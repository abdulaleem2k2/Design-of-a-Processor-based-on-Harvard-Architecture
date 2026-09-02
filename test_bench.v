`timescale 1ns / 1ps

module test_bench();
    
    reg clk=0,reset=0;
    reg [15:0] din;
    wire [15:0] dout;
    
    top dut(.clk(clk),.reset(reset),.din(din),.dout(dout));
    
    always #5 clk=~clk;
    
    initial begin
            reset=1'b1;
            repeat(2) @(posedge clk);//wait for 5 clock cycle
            reset=1'b0;
            din=16'd12;
            #800;
            $stop;
        end
        
    
    
endmodule    

