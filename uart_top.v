
`timescale 1ns/1ps

module uart_top (
    input  wire       clk,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led
);

    // UART receiver signals
    wire [7:0] rx_data;
    wire       rx_done;

    // UART transmitter signals
    wire       baud_tick;
    wire       tx_start;
    wire       tx_busy;
    wire       tx_done;
    wire [7:0] tx_data;

    // LED state
    reg led0_state = 1'b0;

    // Response storage: up to 10 characters
    reg [79:0] response_buf;
    reg [3:0]  response_len;
    reg [3:0]  char_index;

    // Controller states
    localparam IDLE    = 2'd0;
    localparam SEND    = 2'd1;
    localparam WAIT_TX = 2'd2;

    reg [1:0] state;

    // Display received data on LEDs 7:1.
    assign led[7:1] = rx_data[7:1];
    assign led[0]   = led0_state;

    // Select the current response character.
    assign tx_data =
        response_buf[79 - (char_index * 8) -: 8];

    // Start a byte only when the transmitter is available.
    assign tx_start = (state == SEND) && !tx_busy;

    // Baud timing generator restarts for each transmitted byte.
    baud_counter baud_gen (
        .clk(clk),
        .reset(tx_start),
        .baud_tick(baud_tick)
    );

    uart_rx receiver (
        .clk(clk),
        .reset(1'b0),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    uart_tx transmitter (
        .clk(clk),
        .reset(1'b0),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data(tx_data),
        .tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Command parser and response controller
    always @(posedge clk) begin
        case (state)

            IDLE: begin
                if (rx_done) begin
                    char_index <= 4'd0;

                    case (rx_data)

                        // Command '1': turn LED0 on.
                        8'h31: begin
                            led0_state <= 1'b1;
                            response_buf <= {"LED0=ON\r\n", 8'b0};
                            response_len <= 4'd9;
                            state <= SEND;
                        end

                        // Command '0': turn LED0 off.
                        8'h30: begin
                            led0_state <= 1'b0;
                            response_buf <= {"LED0=OFF\r\n"};
                            response_len <= 4'd10;
                            state <= SEND;
                        end

                        // Command '?': report current LED0 state.
                        8'h3F: begin
                            if (led0_state) begin
                                response_buf <= {"LED0=ON\r\n", 8'b0};
                                response_len <= 4'd9;
                            end
                            else begin
                                response_buf <= {"LED0=OFF\r\n"};
                                response_len <= 4'd10;
                            end

                            state <= SEND;
                        end

                        // Invalid command: report an error.
                        default: begin
                            response_buf <= {"ERR\r\n", 40'b0};
                            response_len <= 4'd5;
                            state <= SEND;
                        end

                    endcase
                end
            end

            SEND: begin
                // tx_start is asserted while TX is available.
                // Move to WAIT_TX after the byte is accepted.
                if (!tx_busy)
                    state <= WAIT_TX;
            end

            WAIT_TX: begin
                if (tx_done) begin
                    if (char_index + 1 >= response_len) begin
                        state <= IDLE;
                    end
                    else begin
                        char_index <= char_index + 1'b1;
                        state <= SEND;
                    end
                end
            end

            default: begin
                state <= IDLE;
            end

        endcase
    end

endmodule