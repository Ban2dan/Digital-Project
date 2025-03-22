`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.03.2025 11:04:42
// Design Name: 
// Module Name: Top_Wrapper
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


module Top_Wrapper(
    input CLK,
    input RESET,
    output [7:0] HEX_OUT,
    output [3:0] SEG_SELECT,
    output HS,
    output VS,
    output [7:0] COLOUR_OUT
    );
    
    wire [7:0] BusData;
    wire [7:0] BusAddr;
    wire BusWE;
    wire [7:0] RomAddress;
    wire [7:0] RomData;
    wire [1:0] BusInterruptsRaise;
    wire [1:0] BusInterruptsAck;

    Processor Processor (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .ROM_ADDRESS(RomAddress),
        .ROM_DATA(RomData),
        .BUS_INTERRUPTS_RAISE(BusInterruptsRaise),
        .BUS_INTERRUPTS_ACK(BusInterruptsAck)
    );

    ROM ROM (
        .CLK(CLK),
        .ADDR(RomAddress),
        .DATA(RomData)
    );

    RAM RAM (
        .CLK(CLK),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE)
    );

    Timer Timer (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .BUS_INTERRUPT_RAISE(BusInterruptsRaise[1]),
        .BUS_INTERRUPT_ACK(BusInterruptsAck[1])
    );
    
    Seg7Peripheral Seg7 (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_ADDR(BusAddr),
        .BUS_DATA(BusData),
        .BUS_WE(BusWE),
        .HEX_OUT(HEX_OUT),
        .SEG_SELECT(SEG_SELECT)
    );
    
    VGA_Top VGA (
        .CLK(CLK),
        .RESET(RESET),
        .BUS_DATA(BusData),
        .BUS_ADDR(BusAddr),
        .BUS_WE(BusWE),
        .COLOUR_OUT(COLOUR_OUT),
        .HS(HS),
        .VS(VS)
    );

endmodule