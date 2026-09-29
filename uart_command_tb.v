
`timescale 1ns/1ps

module uart_command_tb;

    reg clk;
    reg uart_rx;
    wire uart_tx;
    wire [7:0] led;

    integer tests;
    integer errors;

    // Device under test
    uart_top dut (
        .clk(clk),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led(led)
    );

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    // Send one UART byte using 115200 baud, 8N1
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            // Idle
            uart_rx = 1'b1;
            repeat (100) @(negedge clk);

            // Start bit
            uart_rx = 1'b0;
            repeat (868) @(negedge clk);

            // Eight data bits, least-significant bit first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                repeat (868) @(negedge clk);
            end

            // Stop bit
            uart_rx = 1'b1;
            repeat (868) @(negedge clk);

            // Allow the receiver/parser to finish
            repeat (100000) @(negedge clk);
        end
    endtask

    task check_led0;
        input expected;
        input [8*40-1:0] description;
        begin
            tests = tests + 1;
            if (led[0] !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s | expected LED0=%b, got=%b",
                         description, expected, led[0]);
            end
            else begin
                $display("PASS: %0s | LED0=%b",
                         description, led[0]);
            end
        end
    endtask

    initial begin
        $dumpfile("uart_command.vcd");
        $dumpvars(0, uart_command_tb);

        clk = 1'b0;
        uart_rx = 1'b1;
        tests = 0;
        errors = 0;

        // Allow initial conditions to settle.
        repeat (10) @(negedge clk);

        // Command '1': LED0 should turn on.
        send_uart_byte(8'h31);
        check_led0(1'b1, "Command 1 turns LED0 on");

        // Command '0': LED0 should turn off.
        send_uart_byte(8'h30);
        check_led0(1'b0, "Command 0 turns LED0 off");

        // Command '1' again: LED0 should turn on again.
        send_uart_byte(8'h31);
        check_led0(1'b1, "Command 1 turns LED0 on again");

        // Invalid command: LED0 should retain its state.
        send_uart_byte(8'h58);
        check_led0(1'b1, "Invalid command preserves LED0");

        $display("--------------------------------");
        $display("Tests run: %0d", tests);
        $display("Failures:  %0d", errors);

        if (errors == 0)
            $display("ALL COMMAND TESTS PASSED");
        else
            $display("SOME COMMAND TESTS FAILED");

        $finish;
    end

endmodule