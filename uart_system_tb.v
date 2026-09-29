
`timescale 1ns/1ps

module uart_system_tb;

    reg clk;
    reg reset;

    reg tx_start;
    reg [7:0] tx_data;

    wire tx;

    wire [7:0] rx_data;
    wire rx_done;

    reg baud_tick;
    reg [9:0] baud_counter;

    integer tests;
    integer errors;

    // Transmitter
    uart_tx transmitter (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data(tx_data),
        .tx(tx)
    );

    // Connect TX directly to RX for loopback testing
    uart_rx receiver (
        .clk(clk),
        .reset(reset),
        .rx(tx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    // Generate baud ticks.
    // Reset the counter at the start of each transmission.
    always @(posedge clk) begin
        if (reset || tx_start) begin
            baud_counter <= 10'd0;
            baud_tick    <= 1'b0;
        end
        else if (baud_counter == 10'd867) begin
            baud_counter <= 10'd0;
            baud_tick    <= 1'b1;
        end
        else begin
            baud_counter <= baud_counter + 1'b1;
            baud_tick    <= 1'b0;
        end
    end

    // Send one byte and check what the receiver reconstructs.
    task send_and_check;
        input [7:0] test_byte;
        integer completed;
        begin
            @(negedge clk);
            tx_data = test_byte;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            completed = 0;

            // Wait for rx_done, but stop waiting after 12,000 clocks.
            fork
                begin
                    wait (rx_done === 1'b1);
                    completed = 1;
                end

                begin
                    repeat (12000) @(posedge clk);
                end
            join_any
            disable fork;

            tests = tests + 1;

            if (completed == 0) begin
                errors = errors + 1;
                $display("FAIL: sent=%02h, receiver timed out", test_byte);
            end
            else begin
                #1;
                if (rx_data !== test_byte) begin
                    errors = errors + 1;
                    $display("FAIL: sent=%02h received=%02h",
                            test_byte, rx_data);
                end
                else begin
                    $display("PASS: sent=%02h received=%02h",
                            test_byte, rx_data);
                end
            end

            // Allow the receiver to return to IDLE before the next frame.
            repeat (2000) @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("uart_system.vcd");
        $dumpvars(0, uart_system_tb);
    end

    initial begin
        clk         = 1'b0;
        reset       = 1'b1;
        tx_start    = 1'b0;
        tx_data     = 8'h00;
        baud_tick   = 1'b0;
        baud_counter = 10'd0;

        tests  = 0;
        errors = 0;

        // Reset both UART modules.
        #30;
        @(negedge clk);
        reset = 1'b0;

        $display("Starting UART loopback tests...");

        send_and_check(8'h41); // A
        send_and_check(8'h42); // B
        send_and_check(8'h00); // All zeros
        send_and_check(8'hFF); // All ones
        send_and_check(8'h55); // Alternating bits
        send_and_check(8'hAA); // Alternating bits
        send_and_check(8'h31); // ASCII '1'
        send_and_check(8'h7E); // Mixed bit pattern

        $display("--------------------------------");
        $display("Tests run: %0d", tests);
        $display("Failures:  %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule