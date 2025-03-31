`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 13:36:06
// Design Name: 
// Module Name: RAM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RAM(
    input CLK,
    input BUS_WE,
    input [7:0] BUS_ADDR,  
    inout [7:0] BUS_DATA
    );
    
    parameter RAMBaseAddr = 0;
    parameter RAMAddrWidth = 7; // 128 x 8-bits memory
  
    wire [7:0] BufferedBusData;
    reg [7:0] Out;
    reg RAMBusWE;
    
    //Bus
    //
    assign BUS_DATA = (RAMBusWE) ? Out : 8'hZZ;//BufferedBusData;
    assign BufferedBusData = BUS_DATA;
    
    //Memory
    reg [7:0] Mem [2**RAMAddrWidth-1:0];
   
initial $readmemh("Complete_Demo_RAM.txt", Mem);

    //single port ram
    always@(posedge CLK) begin
    // Brute-force RAM address decoding.
    // This is not synthesizable, but it is useful for simulation.
    // In a real design, you would use a case statement or a decoder.
        if((BUS_ADDR >= RAMBaseAddr) & (BUS_ADDR < RAMBaseAddr + 128)) begin
            if(BUS_WE) begin
                Mem[BUS_ADDR[6:0]] <= BufferedBusData;
                RAMBusWE <= 1'b0;
            end 
            else
                RAMBusWE <= 1'b1;
        end 
        else
            RAMBusWE <= 1'b0;
        Out <= Mem[BUS_ADDR[6:0]];
    end
endmodule
