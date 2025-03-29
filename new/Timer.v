`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/04 10:49:29
// Design Name: 
// Module Name: Timer
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

module Timer(
    // Standard signals
    input CLK,
    input RESET,

    // BUS interface
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    output BUS_INTERRUPT_RAISE,
    input BUS_INTERRUPT_ACK
);

    // Timer base address in memory map
    parameter [7:0] TimerBaseAddr = 8'hF0;

    // Default interrupt rate (1000ms = 1s)
    parameter InitialInterruptRate = 1000; 

    // Default interrupt enable state
    parameter InitialInterruptEnable = 1'b1; 

    /////////////////////////////////
    // Memory Mapped Addresses:
    // BaseAddr + 0 -> Read: Current timer value
    // BaseAddr + 1 -> Write: Timer interrupt interval (default: 100 ms)
    // BaseAddr + 2 -> Write: Reset timer, restart counting from zero
    // BaseAddr + 3 -> Write: Interrupt enable register

    // Interrupt rate configuration register
    reg [7:0] InterruptRate;
    always @(posedge CLK) begin
        if (RESET)
            InterruptRate <= InitialInterruptRate;
        else if ((BUS_ADDR == TimerBaseAddr + 8'h01) & BUS_WE)
            InterruptRate <= BUS_DATA;
    end

    // Interrupt enable configuration register
    reg InterruptEnable;
    always @(posedge CLK) begin
        if (RESET)
            InterruptEnable <= InitialInterruptEnable;
        else if ((BUS_ADDR == TimerBaseAddr + 8'h03) & BUS_WE)
            InterruptEnable <= BUS_DATA[0];
    end

    // Downscaling the system clock (assume 100MHz) to 1 kHz (1ms period)
    reg [31:0] ClockDivider;
    always @(posedge CLK) begin
        if (RESET)
            ClockDivider <= 0;
        else if (ClockDivider == 32'd99999)
            ClockDivider <= 0;
        else
            ClockDivider <= ClockDivider + 1'b1;
    end

    // Timer counter (1ms increments)
    reg [31:0] Timer;
    always @(posedge CLK) begin
        if (RESET || (BUS_ADDR == TimerBaseAddr + 8'h02))  // Reset when requested
            Timer <= 0;
        else if (ClockDivider == 0)  // Increment every 1ms
            Timer <= Timer + 1'b1;
    end

    // Interrupt generation logic
    reg TargetReached;
    reg [31:0] LastInterruptTime;

    always @(posedge CLK) begin
        if (RESET) begin
            TargetReached <= 1'b0;
            LastInterruptTime <= 0;
        end
        else if ((LastInterruptTime + InterruptRate) == Timer) begin
            if (InterruptEnable)
                TargetReached <= 1'b1;
            LastInterruptTime <= Timer;
        end 
        else
            TargetReached <= 1'b0;
    end

    // Interrupt flag handling
    reg Interrupt;
    always @(posedge CLK) begin
        if (RESET)
            Interrupt <= 1'b0;
        else if (TargetReached)
            Interrupt <= 1'b1;
        else if (BUS_INTERRUPT_ACK)
            Interrupt <= 1'b0;
    end

    assign BUS_INTERRUPT_RAISE = Interrupt;

    // Tristate output for reading timer value
    reg OutputTimerValue;
    always @(posedge CLK) begin
        if (BUS_ADDR == TimerBaseAddr)
            OutputTimerValue <= 1'b1;
        else
            OutputTimerValue <= 1'b0;
    end

    assign BUS_DATA = (OutputTimerValue) ? Timer[7:0] : 8'hZZ;

endmodule
