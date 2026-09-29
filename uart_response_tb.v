
`timescale 1ns/1ps

module uart_response_tb;

    reg clk;
    reg uart_rx;
    wire uart_tx;
    wire [7:0] led;

    integer tests;
    integer errors;

    reg [7:0] received_byte;
    integer i;

    uart_top dut (
        .clk(clk),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led(led)
    );

    always #5 clk = ~clk;

    // Send one UART byte to the FPGA.
    task send_uart_byte;
        input [7:0] data;
        integer j;
        begin
            @(negedge clk);
            uart_rx = 1'b0;
            repeat (868) @(negedge clk);

            for (j = 0; j < 8; j = j + 1) begin
                uart_rx = data[j];
                repeat (868) @(negedge clk);
            end

            uart_rx = 1'b1;
            repeat (868) @(negedge clk);
        end
    endtask

    // Receive one UART byte from the FPGA.
    task receive_uart_byte;
        integer j;
        begin
            // Wait for the falling edge of the start bit.
            @(negedge uart_tx);

            // Move to the center of the first data bit.
            repeat (1302) @(posedge clk);

            // Sample each data bit, LSB first.
            for (j = 0; j < 8; j = j + 1) begin
                received_byte[j] = uart_tx;

                if (j < 7)
                    repeat (868) @(posedge clk);
            end

            // Finish sampling before the next byte starts.
            repeat (434) @(posedge clk);
        end
    endtask

    // Compare an expected response character.
    task check_response_byte;
        input [7:0] expected;
        begin
            receive_uart_byte();

            tests = tests + 1;

            if (received_byte !== expected) begin
                errors = errors + 1;
                $display("FAIL: expected %02h (%c), received %02h (%c)",
                         expected, expected, received_byte, received_byte);
            end
            else begin
                $display("PASS: response byte %02h (%c)",
                         received_byte, received_byte);
            end
        end
    endtask

    initial begin
        $dumpfile("uart_response.vcd");
        $dumpvars(0, uart_response_tb);

        clk = 0;
        uart_rx = 1;
        tests = 0;
        errors = 0;
        received_byte = 0;

        // Allow the receiver to settle.
        repeat (10) @(negedge clk);

        // Command '1': expect LED0=ON followed by newline.
        fork
            send_uart_byte(8'h31);
            begin
                check_response_byte("L");
                check_response_byte("E");
                check_response_byte("D");
                check_response_byte("0");
                check_response_byte("=");
                check_response_byte("O");
                check_response_byte("N");
                check_response_byte(8'h0D);
                check_response_byte(8'h0A);
            end
        join

        if (led[0] !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: LED0 did not turn on");
        end
        else begin
            $display("PASS: LED0 turned on");
        end

        // Give the controller time to return to IDLE.
        repeat (100000) @(negedge clk);

        // Command '0': expect LED0=OFF followed by newline.
        fork
            send_uart_byte(8'h30);
            begin
                check_response_byte("L");
                check_response_byte("E");
                check_response_byte("D");
                check_response_byte("0");
                check_response_byte("=");
                check_response_byte("O");
                check_response_byte("F");
                check_response_byte("F");
                check_response_byte(8'h0D);
                check_response_byte(8'h0A);
            end
        join

        if (led[0] !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL: LED0 did not turn off");
        end
        else begin
            $display("PASS: LED0 turned off");
        end

        $display("--------------------------------");
        $display("Response-byte checks: %0d", tests);
        $display("Failures: %0d", errors);

        if (errors == 0)
            $display("ALL RESPONSE TESTS PASSED");
        else
            $display("SOME RESPONSE TESTS FAILED");

        $finish;
    end

    // Prevent an indefinitely stalled simulation.
    initial begin
        #100000000;
        $display("TIMEOUT: response testbench stalled");
        $finish;
    end

endmodule