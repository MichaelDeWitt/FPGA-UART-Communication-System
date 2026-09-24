module baud_counter (
    input  wire       clk,
    input  wire       reset,
    output reg        baud_tick
);

    reg [9:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter   <= 10'd0;
            baud_tick <= 1'b0;
        end
        else if (counter == 10'd867) begin
            counter   <= 10'd0;
            baud_tick <= 1'b1;
        end
        else begin
            counter   <= counter + 1'b1;
            baud_tick <= 1'b0;
        end
    end

endmodule       
