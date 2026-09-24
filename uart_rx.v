module uart_rx (
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,

    output reg [7:0]  rx_data,
    output reg        rx_done
);

    // ------------------------------------------------
    // UART timing
    // ------------------------------------------------

    localparam HALF_BIT = 10'd433;
    localparam FULL_BIT = 10'd867;


    // ------------------------------------------------
    // States
    // ------------------------------------------------

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;


    reg [1:0] state;

    reg [9:0] baud_counter;

    reg [2:0] bit_index;

    reg [7:0] data_reg;


    // ------------------------------------------------
    // Main RX logic
    // ------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            state        <= IDLE;
            baud_counter <= 10'd0;
            bit_index    <= 3'd0;
            data_reg     <= 8'd0;

            rx_data      <= 8'd0;
            rx_done      <= 1'b0;

        end

        else begin

            // rx_done is normally LOW
            rx_done <= 1'b0;


            case (state)

                // ------------------------------------
                // IDLE
                // ------------------------------------

                IDLE: begin

                    baud_counter <= 10'd0;
                    bit_index    <= 3'd0;

                    // Start bit detected
                    if (rx == 1'b0) begin
                        state <= START;
                    end

                end


                // ------------------------------------
                // START
                // ------------------------------------

                START: begin

                    if (baud_counter == HALF_BIT) begin

                        baud_counter <= 10'd0;

                        // Confirm start bit
                        if (rx == 1'b0) begin
                            state <= DATA;
                        end

                        else begin
                            // False start
                            state <= IDLE;
                        end

                    end

                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end


                // ------------------------------------
                // DATA
                // ------------------------------------

                DATA: begin

                    if (baud_counter == FULL_BIT) begin

                        baud_counter <= 10'd0;

                        // Store received bit
                        data_reg[bit_index] <= rx;

                        if (bit_index == 3'd7) begin

                            bit_index <= 3'd0;
                            state <= STOP;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                        end

                    end

                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end


                // ------------------------------------
                // STOP
                // ------------------------------------

                STOP: begin

                    if (baud_counter == FULL_BIT) begin

                        baud_counter <= 10'd0;

                        // Stop bit should be HIGH
                        if (rx == 1'b1) begin

                            rx_data <= data_reg;
                            rx_done <= 1'b1;

                        end

                        state <= IDLE;

                    end

                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end


                // ------------------------------------
                // Default
                // ------------------------------------

                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule
