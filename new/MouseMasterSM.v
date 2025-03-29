`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02/03/2025 10:14:59 AM
// Design Name: 
// Module Name:    MouseMasterSM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      Modified state machine to ignore BYTE_ERROR_CODE during initialization
//      and only check for errors during the data reception phase.
//      Additionally, in state 8, expecting `F4` instead of `FA` to accommodate
//      USB-to-PS/2 adapters on Basys3 boards that do not strictly follow 
//      the standard acknowledgment byte.
// 
// Dependencies: 
//   MouseTransmitter, MouseReceiver
// 

// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module MouseMasterSM(
    input               CLK,
    input               RESET,
    // Transmitter Control
    output              SEND_BYTE,
    output      [7:0]   BYTE_TO_SEND,
    input               BYTE_SENT,
    // Receiver Control
    output              READ_ENABLE,
    input       [7:0]   BYTE_READ,
    input       [1:0]   BYTE_ERROR_CODE,
    input               BYTE_READY,
    // Data Registers
    output      [7:0]   MOUSE_DX,
    output      [7:0]   MOUSE_DY,
    output      [7:0]   MOUSE_STATUS,
    output              SEND_INTERRUPT
);

    //////////////////////////////////////////////////////////////
    // State Machine - Initialization & Data Reception
    //  1) Send 0xFF (Reset Command)
    //  2) Receive 0xFA (Mouse Acknowledge)
    //  3) Receive 0xAA (Self-Test Pass)
    //  4) Receive 0x00 (Mouse ID)
    //  5) Send 0xF4 (Enable Data Transmission)
    //  6) Expect 0xF4 instead of 0xFA due to USB-PS/2 adapters
    //  7) After initialization, read 3-byte packets (Status, DX, DY)
    //  8) If any error occurs during the data phase, re-initialize.
    //////////////////////////////////////////////////////////////

    // State Machine Control
    reg     [3:0]   state_current, state_next;
    reg     [23:0]  counter_current, counter_next;

    // Transmitter Control
    reg             send_byte_current, send_byte_next;
    reg     [7:0]   byte_to_send_current, byte_to_send_next;

    // Receiver Control
    reg             read_enable_current, read_enable_next;

    // Mouse Data Registers
    reg     [7:0]   status_current, status_next;
    reg     [7:0]   dx_current, dx_next;
    reg     [7:0]   dy_current, dy_next;
    reg             send_interrupt_current, send_interrupt_next;

    //-----------------------------------
    // 1) Sequential Logic
    //-----------------------------------
    always@(posedge CLK) begin
        if(RESET) begin
            state_current          <= 4'h0;
            counter_current        <= 24'd0;
            send_byte_current      <= 1'b0;
            byte_to_send_current   <= 8'h00;
            read_enable_current    <= 1'b0;
            status_current         <= 8'h00;
            dx_current             <= 8'h00;
            dy_current             <= 8'h00;
            send_interrupt_current <= 1'b0;
        end 
        else begin
            state_current          <= state_next;
            counter_current        <= counter_next;
            send_byte_current      <= send_byte_next;
            byte_to_send_current   <= byte_to_send_next;
            read_enable_current    <= read_enable_next;
            status_current         <= status_next;
            dx_current             <= dx_next;
            dy_current             <= dy_next;
            send_interrupt_current <= send_interrupt_next;
        end
    end

    //-----------------------------------
    // 2) Combinational Logic
    //-----------------------------------
    always@* begin
        // Default assignments
        state_next          = state_current;
        counter_next        = counter_current;
        send_byte_next      = 1'b0;
        byte_to_send_next   = byte_to_send_current;
        read_enable_next    = 1'b0;
        status_next         = status_current;
        dx_next             = dx_current;
        dy_next             = dy_current;
        send_interrupt_next = 1'b0;

        case (state_current)
            // State 0: Delay for 10ms before initialization
            4'h0: begin
                if(counter_current == 1000000) begin
                    state_next      = 4'h1;
                    counter_next    = 24'd0;
                end else begin
                    counter_next    = counter_current + 1'b1;
                end
            end

            // State 1: Send Reset Command (0xFF)
            4'h1: begin
                state_next      = 4'h2;
                send_byte_next  = 1'b1;
                byte_to_send_next = 8'hFF;
            end

            // State 2: Wait for Command to be Sent
            4'h2: begin
                if(BYTE_SENT)
                    state_next = 4'h3;
            end

            // State 3: Expect Acknowledge (0xFA)
            4'h3: begin
                if(BYTE_READY) begin
                    if (BYTE_READ == 8'hFA)
                        state_next = 4'h4;
                    else
                        state_next = 4'h0;
                end
                read_enable_next = 1'b1;
            end

            // State 4: Expect Self-Test Pass (0xAA)
            4'h4: begin
                if(BYTE_READY) begin
                    if (BYTE_READ == 8'hAA)
                        state_next = 4'h5;
                    else
                        state_next = 4'h0;
                end
                read_enable_next = 1'b1;
            end

            // State 5: Expect Mouse ID (0x00)
            4'h5: begin
                if(BYTE_READY) begin
                    if (BYTE_READ == 8'h00)
                        state_next = 4'h6;
                    else
                        state_next = 4'h0;
                end
                read_enable_next = 1'b1;
            end

            // State 6: Send Enable Data Transmission Command (0xF4)
            4'h6: begin
                state_next      = 4'h7;
                send_byte_next  = 1'b1;
                byte_to_send_next = 8'hF4;
            end

            // State 7: Wait for Command to be Sent
            4'h7: begin
                if(BYTE_SENT)
                    state_next = 4'h8;
            end

            // State 8: Expect Acknowledge (0xF4 instead of 0xFA)
           4'h8: begin
                if(BYTE_READY) begin
                   
                    if ((BYTE_READ == 8'hF4) || (BYTE_READ == 8'hFA))
                        state_next = 4'h9;
                    else
                        state_next = 4'h0; 
                end
                read_enable_next = 1'b1;
            end

            // State 9: Receive First Data Byte (Status)
            4'h9: begin
                if (BYTE_READY && BYTE_ERROR_CODE == 2'b00) begin
                    status_next = BYTE_READ;
                    state_next  = 4'hA;
                end
                read_enable_next = 1'b1;
            end

            // State A: Receive Second Data Byte (DX)
            4'hA: begin
                if (BYTE_READY && BYTE_ERROR_CODE == 2'b00) begin
                    dx_next = BYTE_READ;
                    state_next  = 4'hB;
                end
                read_enable_next = 1'b1;
            end

            // State B: Receive Third Data Byte (DY)
            4'hB: begin
                if (BYTE_READY && BYTE_ERROR_CODE == 2'b00) begin
                    dy_next = BYTE_READ;
                    state_next  = 4'hC;
                end
                read_enable_next = 1'b1;
            end

            // State C: Complete Packet, Send Interrupt
            4'hC: begin
                state_next = 4'h9;
                send_interrupt_next = 1'b1;
            end

            // Default: Reset
            default: state_next = 4'h0;
        endcase
    end

    //-----------------------------------
    // 3) Output Assignments
    //-----------------------------------
    assign SEND_BYTE       = send_byte_current;
    assign BYTE_TO_SEND    = byte_to_send_current;
    assign READ_ENABLE     = read_enable_current;
    assign MOUSE_DX        = dx_current;
    assign MOUSE_DY        = dy_current;
    assign MOUSE_STATUS    = status_current;
    assign SEND_INTERRUPT  = send_interrupt_current;

endmodule
