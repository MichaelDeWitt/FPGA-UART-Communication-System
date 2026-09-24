`timescale 1ns/1ps

module uart_rx_tb;

    // ------------------------------------------------
    // Signals connected to UART receiver
    // ------------------------------------------------

    reg clk;
    reg reset;
    reg rx;

    wire [7:0] rx_data;
    wire rx_done;


    // ------------------------------------------------
    // Instantiate UART receiver
    // ------------------------------------------------

    uart_rx uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );


    // ------------------------------------------------
    // 100 MHz clock
    // Period = 10 ns
    // ------------------------------------------------

    always #5 clk = ~clk;


    // ------------------------------------------------
    // Record waveform
    // ------------------------------------------------

    initial begin
        $dumpfile("uart_rx.vcd");
        $dumpvars(0, uart_rx_tb);
    end


    // ------------------------------------------------
    // UART transmission task
    //
    // Sends one 8N1 byte to the receiver.
    // Each bit lasts approximately 8.68 us.
    // ------------------------------------------------

    task send_byte;
        input [7:0] byte_to_send;
        integer i;

        begin

            // -----------------------------
            // Start bit
            // -----------------------------

            rx = 1'b0;
            #8680;


            // -----------------------------
            // Data bits
            // LSB first
            // -----------------------------

            for (i = 0; i < 8; i = i + 1) begin
                rx = byte_to_send[i];
                #8680;
            end


            // -----------------------------
            // Stop bit
            // -----------------------------

            rx = 1'b1;
            #8680;

        end
    endtask


    // ------------------------------------------------
    // Test sequence
    // ------------------------------------------------

    initial begin

        // Initial values
        clk   = 1'b0;
        reset = 1'b1;
        rx    = 1'b1;     // UART idle state is HIGH


        // Hold reset for 20 ns
        #20;


        // Release reset
        reset = 1'b0;


        // Wait a little before transmission
        #1000;


        // Send ASCII 'A'
        send_byte(8'h41);


        // Wait after transmission
        #10000;


        $finish;

    end

endmodule
