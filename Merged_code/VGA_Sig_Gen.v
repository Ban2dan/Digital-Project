`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 09:32:05
// Design Name: 
// Module Name: VGA_Sig_Gen
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


module VGA_Sig_Gen(
    input CLK,
    input RESET,
    //Colour Configuration Interface
    input [15:0] CONFIG_COLOURS,
    // Frame Buffer (Dual Port memory) Interface
    output DPR_CLK,
    output [14:0] VGA_ADDR,
    input VGA_DATA,
    //VGA Port Interface
    output reg VGA_HS,
    output reg VGA_VS,
    output reg [7:0] VGA_COLOUR
    );
    
    //define wires to make counters work as intended
    wire Trig_Out;
    wire Horz_Trig_Out;
    wire [9:0] Horz_Counter;
    wire [9:0] Vert_Counter;

    // pixel clock set to 25MHz to drive the VGA display
    Generic_counter # (.COUNTER_WIDTH(3),
                          .COUNTER_MAX(3)
                           )
                           Counter25MHz (
                           .CLK(CLK),
                           .RESET(1'b0),
                           .ENABLE(1'b1),
                           .TRIGGER_OUT(Trig_Out)
                           );
    
    //process for creating horizontal counter values for display
    Generic_counter # (.COUNTER_WIDTH(11),
                      .COUNTER_MAX(799)
                      )
                      BitHorzCounter (
                      .CLK(CLK),
                      .RESET(1'b0),
                      .ENABLE(Trig_Out),
                      .TRIGGER_OUT(Horz_Trig_Out),
                      .COUNT(Horz_Counter)
                      );

    //process for creating vertical counter values for display
    Generic_counter # (.COUNTER_WIDTH(11),
                        .COUNTER_MAX(520)
                        )
                        BitVertCounter (
                        .CLK(CLK),
                        .RESET(1'b0),
                        .ENABLE(Horz_Trig_Out),
                        .COUNT(Vert_Counter)
                        );
    
    /*
    Define VGA signal parameters e.g. Horizontal and Vertical display time, pulse widths, front and back porch
    widths etc.
    */
    
    // Use the following signal parameters
    parameter HTs = 800;  // Total Horizontal Sync Pulse Time
    parameter HTpw = 96;   // Horizontal Pulse Width Time
    parameter HTDisp = 640;  // Horizontal Display Time
    parameter Hbp = 48;   // Horizontal Back Porch Time
    parameter Hfp = 16;   // Horizontal Front Porch Time
    
    parameter VTs = 521;  // Total Vertical Sync Pulse Time
    parameter VTpw = 2;  // Vertical Pulse Width Time
    parameter VTDisp = 480;  // Vertical Display Time
    parameter Vbp = 29;   // Vertical Back Porch Time
    parameter Vfp = 10;   // Vertical Front Porch Time

    //Vertical lines timing
    parameter VertTimeToPulseWidthEnd = 10'd2;
    parameter VertTimeToBackPorchEnd = 10'd31;
    parameter VertTimeToDisplayTimeEnd = 10'd511;
    parameter VertTimeToFrontPorchEnd = 10'd521;
    
    //horizontal lines timing
    parameter HorzTimeToPulseWidthEnd = 10'd96;
    parameter HorzTimeToBackPorchEnd = 10'd144;
    parameter HorzTimeToDisplayTimeEnd = 10'd784;
    parameter HorzTimeToFrontPorchEnd = 10'd800;
    
    //define individual horizontal and vertical addresses
    reg [9:0]   ADDRH;
    reg [8:0]   ADDRV;
    
    //Use slower 25MHz clock and skip first 2 bits of vertical and horizontal address arrays to output pixels as 4x4 of each input element pixel 
    assign DPR_CLK = Trig_Out;
    assign VGA_ADDR = {ADDRV[8:2], ADDRH[9:2]};

    
    //decides when to set horizontal sync high or low
    always@(posedge Trig_Out) begin     
        if (Horz_Counter <= HorzTimeToPulseWidthEnd)
            VGA_HS <= 0;
        else
            VGA_HS <= 1;
    end
    
    //decides when to set vertical sync high or low
   always@(posedge Trig_Out) begin
       if (Vert_Counter <= VertTimeToPulseWidthEnd)
          VGA_VS <= 0;
       else
          VGA_VS <= 1;
    end

    //Increment horizontal address according to the horizonal and vertical counters
   always@(posedge Trig_Out) begin
      if (Horz_Counter > HorzTimeToBackPorchEnd && Horz_Counter < HorzTimeToDisplayTimeEnd)
         ADDRH <= Horz_Counter - HorzTimeToBackPorchEnd;
      else
         ADDRH <= 0;
   end
   
   //Increment horizontal address according to the horizonal and vertical counters
   always@(posedge Trig_Out) begin
     if (Vert_Counter > VertTimeToBackPorchEnd && Vert_Counter < VertTimeToDisplayTimeEnd)
        ADDRV <= Vert_Counter - VertTimeToBackPorchEnd;
     else
        ADDRV = 0;
   end

    //output foreground and background colours as determined by Frame Buffer output
    always@(posedge Trig_Out) begin
        if (Horz_Counter > HorzTimeToBackPorchEnd && Horz_Counter < HorzTimeToDisplayTimeEnd && Vert_Counter > VertTimeToBackPorchEnd && Vert_Counter < VertTimeToDisplayTimeEnd) begin
            if(VGA_DATA == 1) begin
                VGA_COLOUR <= CONFIG_COLOURS[7:0]; //8 LSBs of CONFIG_COLOURS used for foreground frame buffer elements
            end
            
            else begin
                VGA_COLOUR <= CONFIG_COLOURS[15:8]; //8 MSBs of CONFIG_COLOURS used for background frame buffer elements
            end
        end
        else
            VGA_COLOUR <=8'h00; //set to black when not in display time
    end
    
endmodule
