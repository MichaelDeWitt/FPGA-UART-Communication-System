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

    // 100 MHz clock
    always #5 clk = ~clk;

    // Waveform recording
    initial begin
        $dumpfile("baud_counter.vcd");
        $dumpvars(0, baud_counter_tb);
    end

    // Reset and simulation control
    initial begin
        clk = 0;
        reset = 1;

        #20;

        reset = 0;

        #50000;

        $finish;
    end

endmodule
