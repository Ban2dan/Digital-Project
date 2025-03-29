`timescale 1ns / 1ps

module SEG7(
    input CLK,
    input RESET,
    
    // Bus interface
    input [7:0] BUS_ADDR,
    input [7:0] BUS_DATA,
    input BUS_WE,

    // 7-segment display outputs
    output [7:0] HEX_OUT,
    output [3:0] SEG_SELECT_OUT
);

    // Base address for the 7-segment display module
    parameter [7:0] Seg7BaseADDR = 8'hD0;

    // Register to store the value to be displayed on the 7-segment display
    reg [15:0] Seg7Value;

    // Instance of the 7-segment display driver module
    // IN0 to IN3 represent the four digits, ordered from right to left
    SEG7disp seg7_inst (
        .CLK(CLK),
        .IN0(Seg7Value[3:0]),     // First digit (LSB)
        .IN1(Seg7Value[7:4]),     // Second digit
        .IN2(Seg7Value[11:8]),    // Third digit
        .IN3(Seg7Value[15:12]),   // Fourth digit (MSB)
        .SEG_SELECT_OUT(SEG_SELECT_OUT),
        .HEX_OUT(HEX_OUT)
    );

    // Handle writes to the 7-segment display registers
    always @(posedge CLK) begin
        if (RESET)
            Seg7Value <= 16'h0000;  // Reset display value
        else if (BUS_WE) begin
            if (BUS_ADDR == Seg7BaseADDR)
                Seg7Value[7:0] <= BUS_DATA;   // Lower 8 bits (LSB)
            else if (BUS_ADDR == Seg7BaseADDR + 1)
                Seg7Value[15:8] <= BUS_DATA;  // Upper 8 bits (MSB)
        end
    end

endmodule
