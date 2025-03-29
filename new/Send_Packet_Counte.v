`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/24 11:24:46
// Design Name: 
// Module Name: Generic_Counter
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


module Send_Packet_Counter(
        CLK,
        RESET,
        ENABLE,
        PULSE,
        COUNT
);
    parameter COUNTER_WIDTH = 4;
    parameter COUNTER_MAX = 9;   
                         
    
    input CLK;
    input RESET;
    input ENABLE;
    output PULSE;//trigger out
    output [COUNTER_WIDTH-1:0] COUNT;
    
    reg [COUNTER_WIDTH-1:0] count_value;
    reg Trigger_out;

    always@(posedge CLK) begin
        if(RESET)
            count_value <= 0;
        else begin
            if(ENABLE) begin
                if(count_value == COUNTER_MAX)
                    count_value <= 0;  
                else
                    count_value <= count_value + 1;
            end
        end
    end
    
    always@(posedge CLK) begin
         if(RESET) begin
               Trigger_out <= 0;
               end
         else begin
               if(ENABLE && (count_value == COUNTER_MAX)) begin  
                   Trigger_out <= 1;
               end
               else begin
                   Trigger_out <= 0;
               end
         end
    end
    
    assign PULSE = Trigger_out;
               
endmodule
