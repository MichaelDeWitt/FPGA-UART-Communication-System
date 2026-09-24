module uart_top (
    input  wire       clk,
    input  wire       uart_rx,
    output wire [7:0] led
);

    // Received UART data
    wire [7:0] rx_data;

    // Pulses high for one clock when a byte is received
    wire rx_done;


    // ----------------------------------------
    // UART Receiver
    // ----------------------------------------

    uart_rx receiver (
        .clk(clk),
        .reset(1'b0),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );


    // ----------------------------------------
    // Display received byte on LEDs
    // ----------------------------------------

    assign led = rx_data;

endmodule
