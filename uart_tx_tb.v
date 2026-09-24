`timescale 1ns/1ps

module uart_tx_tb;

    // Inputs to the UART transmitter
    reg clk;
    reg reset;
    reg baud_tick;
    reg tx_start;
    reg [7:0] data;

    // Output from the UART transmitter
    wire tx;


    // Instantiate the UART transmitter
    uart_tx uut (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data(data),
        .tx(tx)
    );


    // ------------------------------------------------
    // 100 MHz clock
    // Period = 10 ns
    // ------------------------------------------------

    always #5 clk = ~clk;


    // ------------------------------------------------
    // Baud tick generator for simulation
    // 115200 baud
    // 100 MHz clock
    // 868 clock cycles per bit
    // ------------------------------------------------

    reg [9:0] baud_counter;

    always @(posedge clk) begin

        if (reset) begin
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


    // ------------------------------------------------
    // Record waveform
    // ------------------------------------------------

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);
    end


    // ------------------------------------------------
    // Test sequence
    // ------------------------------------------------

    initial begin

        // Initial values
        clk      = 1'b0;
        reset    = 1'b1;
        tx_start = 1'b0;
        data     = 8'h00;

        // Hold reset for 20 ns
        #20;

        // Release reset
        reset = 1'b0;

        // Send ASCII 'A'
        data = 8'h41;
        tx_start = 1'b1;

        // Keep tx_start high for one clock cycle
        #10;

        tx_start = 1'b0;

        // Wait long enough for the entire UART frame
        #100000;

        $finish;

    end

endmodule
