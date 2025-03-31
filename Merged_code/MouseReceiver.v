`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 13:44:10
// Design Name: 
// Module Name: MouseReceiver
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


module MouseReceiver(
    // Standard Inputs
    input           RESET,
    input           CLK,
    // Mouse IO - Clock
    input           CLK_MOUSE_IN,
    // Mouse IO - Data
    input           DATA_MOUSE_IN,
    // Control Signal
    input           READ_ENABLE,
    output  [7:0]   BYTE_READ,
    output  [1:0]   BYTE_ERROR_CODE,
    output          BYTE_READY
    );

    // Delayed mouse clock for falling edge detection
    reg mouse_clk_delay;
    always @(posedge CLK) begin
        mouse_clk_delay <= CLK_MOUSE_IN;
    end

    // State Machine Variables
    reg [2:0] current_state, next_state;
    reg [7:0] data_reg, next_data_reg;
    reg [3:0] bit_counter, next_bit_counter;
    reg       byte_valid, next_byte_valid;
    reg [1:0] error_flags, next_error_flags;
    reg [15:0] timeout_counter, next_timeout_counter;

    // Sequential logic: update registers on the rising edge of CLK
    always @(posedge CLK) begin
        if (RESET) begin
            current_state   <= 3'b000;
            data_reg        <= 8'h00;
            bit_counter     <= 4'b0000;
            byte_valid      <= 1'b0;
            error_flags     <= 2'b00;
            timeout_counter <= 16'b0;
        end else begin
            current_state   <= next_state;
            data_reg        <= next_data_reg;
            bit_counter     <= next_bit_counter;
            byte_valid      <= next_byte_valid;
            error_flags     <= next_error_flags;
            timeout_counter <= next_timeout_counter;
        end
    end

    // Combinational logic: determine next state and register values
    always @* begin
        // Default assignments
        next_state         = current_state;
        next_data_reg      = data_reg;
        next_bit_counter   = bit_counter;
        next_byte_valid    = 1'b0;
        next_error_flags   = error_flags;
        next_timeout_counter = timeout_counter + 1'b1;

        case (current_state)
            // State 0: Idle, waiting for the start bit
            3'b000: begin
                // When READ_ENABLE is high and a falling edge is detected on CLK_MOUSE_IN with DATA_MOUSE_IN low,
                // a start bit is detected.
                if (READ_ENABLE && mouse_clk_delay && ~CLK_MOUSE_IN && ~DATA_MOUSE_IN) begin
                    next_state = 3'b001;
                    next_error_flags = 2'b00;
                end
                next_bit_counter = 4'b0000;
            end

            // State 1: Receiving 8 data bits
            3'b001: begin
                if (timeout_counter == 16'd50000) begin
                    next_state = 3'b000; // Timeout: return to idle
                end else if (bit_counter == 4'd8) begin
                    next_state = 3'b010; // All 8 data bits received, move to parity check
                    next_bit_counter = 4'b0000;
                end else if (mouse_clk_delay && ~CLK_MOUSE_IN) begin
                    // Shift in the incoming data bit on the falling edge of CLK_MOUSE_IN
                    next_data_reg = {DATA_MOUSE_IN, data_reg[7:1]};
                    next_bit_counter = bit_counter + 1;
                    next_timeout_counter = 16'b0; // Reset timeout counter on valid edge
                end
            end

            // State 2: Parity bit check
            3'b010: begin
                if (timeout_counter == 16'd50000) begin
                    next_state = 3'b000; // Timeout error
                end else if (mouse_clk_delay && ~CLK_MOUSE_IN) begin
                    // Compare received parity bit with computed odd parity (using XNOR reduction)
                    if (DATA_MOUSE_IN != ~^data_reg) begin
                        next_error_flags[0] = 1'b1; // Parity error detected
                    end
                    next_state = 3'b011;
                    next_timeout_counter = 16'b0;
                end
            end

            // State 3: Stop bit check
            3'b011: begin
                if (timeout_counter == 16'd50000) begin
                    next_state = 3'b000; // Timeout error
                end else if (mouse_clk_delay && ~CLK_MOUSE_IN) begin
                    // Stop bit should be high; if low then flag an error
                    if (~DATA_MOUSE_IN) begin
                        next_error_flags[1] = 1'b1; // Stop bit error detected
                    end
                    next_state = 3'b100;
                    next_timeout_counter = 16'b0;
                end
            end

            // State 4: Byte successfully received
            3'b100: begin
                next_state = 3'b000;
                next_byte_valid = 1'b1;
            end

            // Default: reset registers
            default: begin
                next_state         = 3'b000;
                next_data_reg      = 8'hFF;
                next_bit_counter   = 4'b0000;
                next_byte_valid    = 1'b0;
                next_error_flags   = 2'b00;
                next_timeout_counter = 16'b0;
            end
        endcase
    end

    // Output assignments
    assign BYTE_READY = byte_valid;
    assign BYTE_READ = data_reg;
    assign BYTE_ERROR_CODE = error_flags;

endmodule
