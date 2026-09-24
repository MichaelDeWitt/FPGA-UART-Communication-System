`timescale 1ns/1ps

module uart_system_tb;

    // ------------------------------------------------
    // Clock and reset
    // ------------------------------------------------

    reg clk;
    reg reset;


    // ------------------------------------------------
    // TX control
    // ------------------------------------------------

    reg tx_start;
    reg [7:0] tx_data;

    wire tx;


    // ------------------------------------------------
    // RX outputs
    // ------------------------------------------------

    wire [7:0] rx_data;
    wire rx_done;


    // ------------------------------------------------
    // Baud tick
    // ------------------------------------------------

    reg baud_tick;
    reg [9:0] baud_counter;


    // ------------------------------------------------
    // Connect TX and RX
    // ------------------------------------------------

    uart_tx transmitter (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data(tx_data),
        .tx(tx)
    );


    uart_rx receiver (
        .clk(clk),
        .reset(reset),
        .rx(tx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );


    // ------------------------------------------------
    // 100 MHz clock
    // ------------------------------------------------

    always #5 clk = ~clk;


    // ------------------------------------------------
    // Baud counter
    //
    // 100 MHz clock
    // 115200 baud
    // 868 clock cycles per bit
    // ------------------------------------------------

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
    // Waveform recording
    // ------------------------------------------------

    initial begin

        $dumpfile("uart_system.vcd");
        $dumpvars(0, uart_system_tb);

    end


    // ------------------------------------------------
    // Test
    // ------------------------------------------------

    initial begin

        // Initial values
        clk      = 1'b0;
        reset    = 1'b1;
        tx_start = 1'b0;
        tx_data  = 8'h00;


        // Hold reset
        #20;


        // Release reset
        reset = 1'b0;


        // Wait before transmission
        #100;


        // Load ASCII 'A'
        tx_data = 8'h41;


        // Start transmission
        tx_start = 1'b1;


        // Keep tx_start high for one clock
        #10;

        tx_start = 1'b0;


        // Wait for complete transmission
        #100000;


        $finish;

    end

endmodule
