`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/29 11:18:19
// Design Name: 
// Module Name: MouseTransmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: PS/2 Mouse Transmitter module which sends a byte following the PS/2 
//              protocol. It controls the Clock and Data lines to transmit a start bit, 
//              8 data bits (LSB first), an odd parity bit, and a stop bit, then waits 
//              for the device acknowledgment.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module MouseTransmitter(
    // Standard Inputs
    input               RESET,
    input               CLK,
    // Mouse IO - Clock
    input               CLK_MOUSE_IN,
    output              CLK_MOUSE_OUT_EN, // Enables control of the Clock line
    // Mouse IO - Data
    input               DATA_MOUSE_IN,
    output              DATA_MOUSE_OUT,
    output              DATA_MOUSE_OUT_EN,
    // Control Signals
    input               SEND_BYTE,
    input      [7:0]    BYTE_TO_SEND,
    output              BYTE_SENT
);


// Delay the Mouse Clock Input to detect falling edges
    reg mouse_clk_in_delay;
    always @(posedge CLK) begin
        mouse_clk_in_delay <= CLK_MOUSE_IN;
    end


// State Machine Internal Variables
    reg [3:0] current_state,      next_state;
    reg       current_clk_out_en, next_clk_out_en;
    reg       current_data_out,   next_data_out;
    reg       current_data_out_en,next_data_out_en;
    reg [15:0] current_send_counter, next_send_counter;
    reg       current_byte_sent,  next_byte_sent;
    reg [7:0] current_byte_to_send, next_byte_to_send;


// Sequential Logic: Update state and registers on rising edge of CLK
    always @(posedge CLK) begin
        if (RESET) begin
            current_state         <= 4'h0;
            current_clk_out_en    <= 1'b0;
            current_data_out      <= 1'b0;
            current_data_out_en   <= 1'b0;
            current_send_counter  <= 16'b0;
            current_byte_sent     <= 1'b0;
            current_byte_to_send  <= 8'h00;
        end else begin
            current_state         <= next_state;
            current_clk_out_en    <= next_clk_out_en;
            current_data_out      <= next_data_out;
            current_data_out_en   <= next_data_out_en;
            current_send_counter  <= next_send_counter;
            current_byte_sent     <= next_byte_sent;
            current_byte_to_send  <= next_byte_to_send;
        end
    end


// Combinational Logic: Determine next state and outputs
    always @* begin
        // Default assignments
        next_state            = current_state;
        next_clk_out_en       = 1'b0;
        next_data_out         = 1'b0;
        next_data_out_en      = current_data_out_en;
        next_send_counter     = current_send_counter;
        next_byte_sent        = 1'b0;
        next_byte_to_send     = current_byte_to_send;

        case (current_state)
            // State 0: Idle - Waiting for SEND_BYTE signal
            4'h0: begin
                if (SEND_BYTE) begin
                    next_state        = 4'h1;
                    next_byte_to_send = BYTE_TO_SEND;
                end
                next_data_out_en = 1'b0;
            end

            // State 1: Pull Clock line low for at least 100 microseconds
            // (Approximately 11000 clock cycles @ 100MHz)
            4'h1: begin
                if (current_send_counter == 11000) begin
                    next_state        = 4'h2;
                    next_send_counter = 16'b0;
                end else begin
                    next_send_counter = current_send_counter + 1'b1;
                end
                next_clk_out_en = 1'b1;
            end

            // State 2: Pull Data line low and release the Clock line
            4'h2: begin
                next_state         = 4'h3;
                next_data_out_en   = 1'b1;
            end

            // State 3: Transmit Start Bit (Start bit = 0)
            4'h3: begin
                // Change data on falling edge of CLK_MOUSE_IN
                if (mouse_clk_in_delay & ~CLK_MOUSE_IN)
                    next_state = 4'h4;
            end

            // State 4: Transmit 8 Data Bits (LSB first)
            4'h4: begin
                // On falling edge, update bit counter and output the corresponding data bit
                if (mouse_clk_in_delay & ~CLK_MOUSE_IN) begin
                    if (current_send_counter == 7) begin
                        next_state        = 4'h5;
                        next_send_counter = 16'b0;
                    end else begin
                        next_send_counter = current_send_counter + 1'b1;
                    end
                end
                next_data_out = current_byte_to_send[current_send_counter];
            end

            // State 5: Transmit Parity Bit (Odd parity)
            4'h5: begin
                if (mouse_clk_in_delay & ~CLK_MOUSE_IN)
                    next_state = 4'h6;
                // Compute odd parity: parity bit is the complement of XOR of all data bits
                next_data_out = ~^current_byte_to_send[7:0];
            end

            // State 6: Transmit Stop Bit (Stop bit = 1)
            4'h6: begin
                if (mouse_clk_in_delay & ~CLK_MOUSE_IN)
                    next_state = 4'h7;
                next_data_out = 1'b1;
            end

            // State 7: Release Data line
            4'h7: begin
                next_state         = 4'h8;
                next_data_out_en   = 1'b0;
            end

            // State 8: Wait for Device Acknowledgment
            // The device should pull Data and Clock lines low, then release them
            4'h8: begin
                 if ((DATA_MOUSE_IN == 1'b0) && (CLK_MOUSE_IN == 1'b0)) begin
                    next_state     = 4'h0;
                    next_byte_sent = 1'b1;
                end
            end
            

            // Default: Reset registers
            default: begin
                next_state           = 4'h0;
                next_clk_out_en      = 1'b0;
                next_data_out        = 1'b0;
                next_data_out_en     = 1'b0;
                next_send_counter    = 16'b0;
                next_byte_sent       = 1'b0;
                next_byte_to_send    = 8'hFF;
            end
        endcase
    end


    // Mouse IO - Clock
    assign CLK_MOUSE_OUT_EN  = current_clk_out_en;
    // Mouse IO - Data
    assign DATA_MOUSE_OUT    = current_data_out;
    assign DATA_MOUSE_OUT_EN = current_data_out_en;
    // Control
    assign BYTE_SENT         = current_byte_sent;

endmodule
