`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2025 12:46:25
// Design Name: 
// Module Name: Frame_Buffer
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


module Frame_Buffer(
    // Port A - Read/Write
    input           A_CLK,
    input [14:0]    A_ADDR, // 8 + 7 bits = 15 bits hence [14:0]
    input           A_DATA_IN, // Pixel Data In
    output reg      A_DATA_OUT,
    input           A_WE,
    // Port B - Read Only
    input           B_CLK,
    input [14:0]    B_ADDR, // Pixel Data Out
    output reg      B_DATA
    );
    
    // A 256 x 128 1-bit memory to hold frame data
    // The LSBs of the address correspond to the X axis, and the MSBs to the Y axis
    //32767 obtained from (2^15) - 1
    reg [0:0] Memory [32767:0];


    //Port A for read/write operations
    always @ (posedge A_CLK) begin
        if (A_WE == 1) 
            Memory[A_ADDR] <= A_DATA_IN; //input foreground/background element into appropriate memory address

        A_DATA_OUT <= Memory[A_ADDR]; //output appropriate pixel data for specific address
    end

    //Port B for read only opeations
    always@(posedge B_CLK) //slower 25MHz clock
        B_DATA <= Memory[B_ADDR]; //output appropriate pixel data for specific address

endmodule
