
`timescale 1ns/1ps

module uart_tx_handshake_tb;

    reg clk;
    reg reset;
    reg baud_tick;
    reg tx_start;
    reg [7:0] data;

    wire tx;
    wire tx_busy;
    wire tx_done;

    integer done_count;
    integer errors;
    integer baud_count;

    // Transmitter under test
    uart_tx dut (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data(data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    // Generate a baud tick every 868 clock cycles.
    always @(posedge clk) begin
        if (reset || tx_start) begin
            baud_count <= 0;
            baud_tick <= 0;
        end
        else if (baud_count == 867) begin
            baud_count <= 0;
            baud_tick <= 1;
        end
        else begin
            baud_count <= baud_count + 1;
            baud_tick <= 0;
        end
    end

    // Count tx_done pulses.
    always @(posedge clk) begin
        if (reset)
            done_count <= 0;
        else if (tx_done)
            done_count <= done_count + 1;
    end

    initial begin
        $dumpfile("uart_tx_handshake.vcd");
        $dumpvars(0, uart_tx_handshake_tb);

        clk = 0;
        reset = 1;
        baud_tick = 0;
        tx_start = 0;
        data = 8'hA5;
        baud_count = 0;
        done_count = 0;
        errors = 0;

        // Release reset.
        repeat (3) @(negedge clk);
        reset = 0;

        // Start transmitting A5.
        @(negedge clk);
        tx_start = 1;

        @(negedge clk);
        tx_start = 0;

        // Confirm transmitter becomes busy.
        #1;
        if (tx_busy !== 1'b1) begin
            $display("FAIL: tx_busy did not assert");
            errors = errors + 1;
        end
        else begin
            $display("PASS: tx_busy asserted");
        end

        // Wait for transmission to finish.
        wait (tx_done === 1'b1);
        #1;

        if (tx_busy !== 1'b0) begin
            $display("FAIL: tx_busy did not deassert");
            errors = errors + 1;
        end
        else begin
            $display("PASS: tx_busy deasserted");
        end

        // Allow the counter to register the tx_done pulse.
        @(posedge clk);
        #1;

        // Check that exactly one completion pulse occurred.
        if (done_count != 1) begin
            $display("FAIL: expected one tx_done pulse, got %0d",
                     done_count);
            errors = errors + 1;
        end
        else begin
            $display("PASS: exactly one tx_done pulse");
        end

        $display("-------------------------------");
        $display("Failures: %0d", errors);

        if (errors == 0)
            $display("ALL TX HANDSHAKE TESTS PASSED");
        else
            $display("TX HANDSHAKE TESTS FAILED");

        $finish;
    end

    // Timeout guard.
    initial begin
        #2000000;
        $display("TIMEOUT: transmitter did not finish");
        $finish;
    end

endmodule