`timescale 1ns / 1ps


module LED(
    input CLK,
    input RESET,
    // bus 
    input [7:0] BUS_ADDR,
    input [7:0] BUS_DATA,
    input BUS_WE,
   
    output reg [15:0] LED_OUT
    );
    
    // set LED base addr for better modularity
    parameter [7:0] LedBaseADDR = 8'hC0;
    // set LED_OUT to 0 when reset
    // set LED_OUT to BUS_DATA when BUS_WE is high
    // set LED_OUT to BUS_DATA when BUS_WE is high
    always@(posedge CLK) begin
        if (RESET)
            // reset LED value when reset button is pressed
            LED_OUT <= 16'h0000;
        else if (BUS_WE) begin
            if (BUS_ADDR == LedBaseADDR)
                LED_OUT[7:0] <= BUS_DATA;  
            else if (BUS_ADDR == LedBaseADDR + 1)
                LED_OUT[15:8] <= BUS_DATA; 
        end
    end
    
endmodule