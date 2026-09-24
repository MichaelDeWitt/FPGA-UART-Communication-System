module uart_tx (
    input  wire       clk,
    input  wire       reset,
    input  wire       baud_tick,
    input  wire       tx_start,
    input  wire [7:0] data,
    output reg        tx
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk) begin

        if (reset) begin
            state     <= IDLE;
            bit_index <= 3'd0;
            data_reg  <= 8'd0;
            tx        <= 1'b1;
        end

        else begin

            case (state)

                IDLE: begin
                    tx <= 1'b1;

                    if (tx_start) begin
                        data_reg  <= data;
                        bit_index <= 3'd0;
                        state     <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (baud_tick) begin
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx <= data_reg[bit_index];

                    if (baud_tick) begin

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= STOP;
                        end

                        else begin
                            bit_index <= bit_index + 1'b1;
                        end

                    end
                end

                STOP: begin
                    tx <= 1'b1;

                    if (baud_tick) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx    <= 1'b1;
                end

            endcase
        end
    end

endmodule
