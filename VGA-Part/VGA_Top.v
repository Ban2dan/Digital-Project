`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2025 12:45:01
// Design Name: 
// Module Name: VGA_Top
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


module VGA_Top(
    input CLK,
    input RESET,
    input [7:0] BUS_ADDR,
    inout [7:0] BUS_DATA,
    input BUS_WE,
    output [7:0] COLOUR_OUT,
    output HS,
    output VS
    );
    
    parameter [7:0] VGABaseAddress = 8'hB0;
        
    wire [15:0] Colour_Conf = {8'hFF, 8'h00};
    wire [14:0] VGA_Address;
    wire FrameBuffer_Data_VGA;
    wire FrameBuffer_Data;   
    wire DPR_CLK;
    
    //registers used to generate Frame Buffer configuration data     
    reg FrameBuffer_WE;
    reg [14:0] FrameBuffer_Address;
    reg Pixel_Map_Data;

    
    Frame_Buffer Frame_Buff (
        .A_CLK(CLK),
        .A_ADDR(FrameBuffer_Address),     
        .A_DATA_IN(Pixel_Map_Data),         
        .A_DATA_OUT(FrameBuffer_Data),
        .A_WE(FrameBuffer_WE),                               
        .B_CLK(DPR_CLK),
        .B_ADDR(VGA_Address),  
        .B_DATA(FrameBuffer_Data_VGA)
    );   
   
    VGA_Sig_Gen VGA_Sig ( 
        .CLK(CLK),
        .RESET(RESET),
        .CONFIG_COLOURS(Colour_Conf),
        .DPR_CLK(DPR_CLK),
        .VGA_ADDR(VGA_Address),
        .VGA_DATA(FrameBuffer_Data_VGA),
        .VGA_HS(HS),
        .VGA_VS(VS),
        .VGA_COLOUR(COLOUR_OUT)
    );
    
    //IMPORTTANTv below here rename and recomment later
    reg VGABusWE;
    reg [7:0] Out;
   
    // Tristate
    assign BUS_DATA = (VGABusWE) ? Out : 8'hZZ;

    always@(posedge CLK) begin
        if (BUS_WE) begin
            VGABusWE <= 1'b0;
            
            // X coordinate
            if (BUS_ADDR == VGABaseAddress) begin
                FrameBuffer_WE <= 1'b0;
                FrameBuffer_Address[7:0] <= BUS_DATA;
            end
            // Y coordinate
            else if (BUS_ADDR == VGABaseAddress + 1) begin
                FrameBuffer_WE <= 1'b0;
                FrameBuffer_Address[14:8] <= 119 - BUS_DATA;
            end
            // Pixel value to write
            else if (BUS_ADDR == VGABaseAddress + 2) begin
                FrameBuffer_WE <= 1'b1;
                Pixel_Map_Data <= BUS_DATA[0];
            end
            else
                FrameBuffer_WE <= 1'b0;
        end
        else begin
            // Enable the VGA module to write to bus (if the address is right)
            if (BUS_ADDR >= VGABaseAddress & BUS_ADDR < VGABaseAddress + 3)
                VGABusWE <= 1'b1;
            else
                VGABusWE <= 1'b0;
                
            // Processor is not writing, so disable writing to frame buffer
            FrameBuffer_WE <= 1'b0;
        end
            
        Out <= FrameBuffer_Data;
    end
    
    
endmodule
