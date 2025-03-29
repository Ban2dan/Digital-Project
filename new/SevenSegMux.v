// Drives a 4-digit multiplexed seven-segment display.
// Assumes active-low segments and active-low digit enables.
module SevenSegMux(
    input CLK,
    input RESET,
    input [3:0] digit3, // Thousands digit
    input [3:0] digit2, // Hundreds digit
    input [3:0] digit1, // Tens digit
    input [3:0] digit0, // Ones digit
    output reg [7:0] seg,
    output reg [3:0] an
);
    reg [15:0] refresh_counter;
    reg [1:0] scan;
    
    // Refresh counter for multiplexing.
    always @(posedge CLK) begin
        if (RESET)
            refresh_counter <= 16'd0;
        else
            refresh_counter <= refresh_counter + 1;
    end
    
    // Use the two MSBs of the refresh counter to select the digit.
    always @(posedge CLK) begin
        if (RESET)
            scan <= 2'd0;
        else
            scan <= refresh_counter[15:14];
    end

    // Seven-segment decoder function.
    // Digits 0-9 are standard.
    // 4'hA represents "X" and 4'hB represents "Y".
    function [7:0] decode_digit;
        input [3:0] digit;
        begin
            case(digit)
                4'd0: decode_digit = 8'b11000000;
                4'd1: decode_digit = 8'b11111001;
                4'd2: decode_digit = 8'b10100100;
                4'd3: decode_digit = 8'b10110000;
                4'd4: decode_digit = 8'b10011001;
                4'd5: decode_digit = 8'b10010010;
                4'd6: decode_digit = 8'b10000010;
                4'd7: decode_digit = 8'b11111000;
                4'd8: decode_digit = 8'b10000000;
                4'd9: decode_digit = 8'b10010000;
                4'ha: decode_digit = 8'b10001001; // Pattern for "X"
                4'hb: decode_digit = 8'b10010001; // Pattern for "Y"
                default: decode_digit = 8'b11111111;
            endcase
        end
    endfunction

    // Multiplex the 4 digits.
    always @(*) begin
        case(scan)
            2'd0: begin
                an = 4'b1110;
                seg = decode_digit(digit0);
            end
            2'd1: begin
                an = 4'b1101;
                seg = decode_digit(digit1);
            end
            2'd2: begin
                an = 4'b1011;
                seg = decode_digit(digit2);
            end
            2'd3: begin
                an = 4'b0111;
                seg = decode_digit(digit3);
            end
            default: begin
                an = 4'b1111;
                seg = 8'b11111111;
            end
        endcase
    end
endmodule
