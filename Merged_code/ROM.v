`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 13:35:29
// Design Name: 
// Module Name: ROM
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


module ROM(
    input CLK,
    input [7:0] ADDR,
    output reg [7:0] DATA
    );
    
    parameter RAMAddrWidth = 8;
    
    //Memory
    reg [7:0] ROM [2**RAMAddrWidth-1:0];
    //
    initial $readmemh("Complete_Demo_ROM.txt", ROM);
    
    //single port ram
    always@(posedge CLK)begin
        DATA <= ROM[ADDR];
    end
        
endmodule