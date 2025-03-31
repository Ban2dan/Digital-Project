`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 13:39:06
// Design Name: 
// Module Name: IR_SM
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


module IR_SM(
    input CLK,    
    input RESET,
    input [3:0] COMMAND,              // 4-bit command: forward3, back2, left1, right0
    input SEND_PACKET,                // 10 Hz trigger signal for sending a packet
    input [3:0] ColorSwitchSelection, // Color-based configuration selector
    output IR_LED,                    // Output to drive IR LED
    output [3:0] Current_state        // Output current state for simulation
    );

    // Internal signals
    assign Current_state = state_current;

    reg ir_led_signal;
    assign IR_LED = ir_led_signal;

    reg [3:0] state_current;
    reg [3:0] state_next;
    reg [3:0] command_buffer;
    reg [3:0] gap_counter;

    reg [15:0] pulse_divider_count;
    reg [24:0] state_duration_counter;
    reg [24:0] state_duration_target;
    reg pulse_out;
    reg duration_done;

    // Configurable burst lengths and timing
    reg [7:0] burst_start;
    reg [5:0] burst_car_select;
    reg [5:0] burst_gap;
    reg [5:0] burst_assert;
    reg [5:0] burst_deassert;
    reg [10:0] pulse_divider_max;

    // Car color configuration (pulse durations)
    always @(posedge CLK) begin
        if (ColorSwitchSelection == 4'b0001) begin // Yellow car
            burst_start       <= 88;
            burst_car_select  <= 22;
            burst_gap         <= 40;
            burst_assert      <= 44;
            burst_deassert    <= 22;
            pulse_divider_max <= 1250;
        end else if (ColorSwitchSelection == 4'b0010) begin // Blue car
            burst_start       <= 191;
            burst_car_select  <= 47;
            burst_gap         <= 25;
            burst_assert      <= 47;
            burst_deassert    <= 22;
            pulse_divider_max <= 1388;
        end else if (ColorSwitchSelection == 4'b0100) begin // Green car
            burst_start       <= 88;
            burst_car_select  <= 44;
            burst_gap         <= 40;
            burst_assert      <= 44;
            burst_deassert    <= 22;
            pulse_divider_max <= 1332;
        end else if (ColorSwitchSelection == 4'b1000) begin // Red car
            burst_start       <= 192;
            burst_car_select  <= 24;
            burst_gap         <= 24;
            burst_assert      <= 48;
            burst_deassert    <= 24;
            pulse_divider_max <= 1388;
        end
    end

    // State encoding
    parameter STATE_WAIT      = 4'd0,
              STATE_START     = 4'd1,
              STATE_GAP       = 4'd2,
              STATE_CAR_SEL   = 4'd3,
              STATE_ASSERT    = 4'd4,
              STATE_DEASSERT  = 4'd5;

    // Initialization
    initial begin  
        state_duration_target   = 0;
        state_duration_counter  = 0;
        state_current           = STATE_WAIT;
        state_next              = STATE_WAIT;
        pulse_divider_count     = 0;
        pulse_out               = 0;
        duration_done           = 0;     
        gap_counter             = 0;
        command_buffer          = 4'd0;
    end

    // State register update
    always @(posedge CLK) begin
        if (RESET)
            state_current <= STATE_WAIT;
        else
            state_current <= state_next;
    end

    // Duration counter per state
    always @(posedge CLK) begin
        if (duration_done)
            state_duration_counter <= 0;
        else
            state_duration_counter <= state_duration_counter + 1;
    end    

    // Duration done signal
    always @(*) begin
        duration_done = (state_duration_counter == state_duration_target);
    end

    // Command capture and gap counter
    always @(posedge duration_done) begin
        if (state_current == STATE_START) begin
            gap_counter    <= 0;
            command_buffer <= COMMAND;
        end else if (state_current == STATE_CAR_SEL || 
                     state_current == STATE_ASSERT  || 
                     state_current == STATE_DEASSERT) begin
            gap_counter <= gap_counter + 1;
        end
    end

    // Duration target per state
    always @(*) begin
        case (state_current)                  
            STATE_WAIT:     state_duration_target = 0;
            STATE_START:    state_duration_target = burst_start * 2 * 1389 - 1;
            STATE_GAP:      state_duration_target = burst_gap * 2 * 1389 - 1;
            STATE_CAR_SEL:  state_duration_target = burst_car_select * 2 * 1389 - 1;
            STATE_ASSERT:   state_duration_target = burst_assert * 2 * 1389 - 1;
            STATE_DEASSERT: state_duration_target = burst_deassert * 2 * 1389 - 1;
            default:        state_duration_target = 0;
        endcase
    end    

    // Next state logic
    always @(*) begin
        case (state_current)
            STATE_WAIT:
                state_next = SEND_PACKET ? STATE_START : STATE_WAIT;

            STATE_START:
                state_next = duration_done ? STATE_GAP : STATE_START;

            STATE_GAP: begin
                if (duration_done) begin
                    if (gap_counter == 0) begin
                        state_next = STATE_CAR_SEL;
                    end else if (gap_counter < 5) begin
                        state_next = command_buffer[gap_counter - 1] ? 
                                     STATE_ASSERT : STATE_DEASSERT;
                    end else begin
                        state_next = STATE_WAIT;
                    end
                end else begin
                    state_next = STATE_GAP;
                end
            end

            STATE_CAR_SEL:
                state_next = duration_done ? STATE_GAP : STATE_CAR_SEL;

            STATE_ASSERT:
                state_next = duration_done ? STATE_GAP : STATE_ASSERT;

            STATE_DEASSERT:
                state_next = duration_done ? STATE_GAP : STATE_DEASSERT;

            default:
                state_next = STATE_WAIT;
        endcase
    end

    // Pulse generator (36kHz)
    always @(posedge CLK) begin
        if (pulse_divider_count == pulse_divider_max) begin
            pulse_out <= ~pulse_out;
            pulse_divider_count <= 0;
        end else begin
            pulse_divider_count <= pulse_divider_count + 1;
        end
    end

    // IR LED output control
    always @(*) begin
        if (state_current == STATE_WAIT || state_current == STATE_GAP)
            ir_led_signal = 1'b0;
        else
            ir_led_signal = pulse_out;
    end

endmodule
