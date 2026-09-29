`timescale 1ns/1ps

module baud_counter_tb;

    reg clk;
    reg reset;

    wire baud_tick;

    baud_counter uut (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("baud_counter.vcd");
        $dumpvars(0, baud_counter_tb);
    end

    initial begin
        clk = 0;
        reset = 1;

        #20;

        reset = 0;

        #50000;

        $finish;
    end

endmodule
