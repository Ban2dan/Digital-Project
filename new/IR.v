`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/24 11:24:46
// Design Name: 
// Module Name: IR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Wrapper for IR transmitter, includes control registers via BUS,
//              and sends IR command periodically (10 Hz).
// 
// Dependencies: IRTransmitterSM, Send_Packet_Counter
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module IR(
    input RESET,
    input CLK,
    input [7:0] BUS_ADDR,
    inout [7:0] BUS_DATA,
    input BUS_WE,
    output IR_LED
    );

    // Internal signal for triggering packet transmission
    wire packet_trigger;

    // Registers to store command and color switch selection
    reg [3:0] ir_command;
    reg [3:0] color_selection;

    // Instantiate a 10 Hz pulse generator
    Send_Packet_Counter #(
        .COUNTER_WIDTH(24),
        .COUNTER_MAX(9999999)  // Adjusted to produce ~10 Hz output from CLK
    ) pulse_gen_10Hz (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(1'b1),
        .PULSE(packet_trigger)
    );

    // Instantiate the IR transmitter state machine
    IR_SM IR_sm (
        .CLK(CLK),
        .RESET(RESET),
        .COMMAND(ir_command),
        .ColorSwitchSelection(color_selection),
        .SEND_PACKET(packet_trigger),
        .IR_LED(IR_LED)
    );

    // Register write logic for command and color selection
    always @(posedge CLK) begin
        if (RESET) begin
            ir_command <= 4'b0000;
        end else if (BUS_WE) begin
            if (BUS_ADDR == 8'h90)
                ir_command <= BUS_DATA[3:0];
            else if (BUS_ADDR == 8'h91)
                color_selection <= BUS_DATA[7:4];
        end
    end

    

endmodule
