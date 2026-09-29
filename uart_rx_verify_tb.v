
`timescale 1ns/1ps

module uart_rx_verify_tb;

    reg clk;
    reg reset;
    reg rx;

    wire [7:0] rx_data;
    wire rx_done;

    integer tests;
    integer errors;
    integer done_count;

    uart_rx uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    // Count every completed, valid frame.
    always @(posedge clk) begin
        if (reset)
            done_count <= 0;
        else if (rx_done)
            done_count <= done_count + 1;
    end

    // Send a UART frame with a selectable stop bit.
    task send_frame;
        input [7:0] data_byte;
        input stop_bit;
        integer i;

        begin
            // Start bit
            rx = 1'b0;
            #8680;

            // Eight data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = data_byte[i];
                #8680;
            end

            // Stop bit: normally 1, or deliberately invalid 0
            rx = stop_bit;
            #8680;

            // Return to idle
            rx = 1'b1;
            #10000;
        end
    endtask

    initial begin
        $dumpfile("uart_rx_verify.vcd");
        $dumpvars(0, uart_rx_verify_tb);
    end

    initial begin
        clk        = 1'b0;
        reset      = 1'b1;
        rx         = 1'b1;
        tests      = 0;
        errors     = 0;
        done_count = 0;

        #30;
        @(negedge clk);
        reset = 1'b0;

        // Test 1: Valid frame
        $display("Test 1: Valid frame");
        send_frame(8'hA5, 1'b1);

        tests = tests + 1;

        if (rx_data === 8'hA5 && done_count == 1)
            $display("PASS: valid frame received correctly");
        else begin
            errors = errors + 1;
            $display("FAIL: rx_data=%02h, done_count=%0d",
                     rx_data, done_count);
        end

        // Test 2: Invalid stop bit
        $display("Test 2: Invalid stop bit");
        send_frame(8'h3C, 1'b0);

        tests = tests + 1;

        if (done_count == 1 && rx_data === 8'hA5)
            $display("PASS: invalid frame was rejected");
        else begin
            errors = errors + 1;
            $display("FAIL: invalid frame was accepted or data changed");
        end

        $display("------------------------------");
        $display("Tests:    %0d", tests);
        $display("Failures: %0d", errors);

        if (errors == 0)
            $display("ALL RX VERIFICATION TESTS PASSED");
        else
            $display("RX VERIFICATION FAILED");

        $finish;
    end

endmodule