`timescale 1ns / 1ps

module Mouse(
    // General signals
    input           CLK,
    input           RESET,
    // Mouse interface
    inout           CLK_MOUSE,
    inout           DATA_MOUSE,
    // Bus interface
    inout   [7:0]   BUS_DATA,
    input   [7:0]   BUS_ADDR,
    input           Bus2MouseWE,
    // Interrupt signals
    output  reg     BUS_INTERRUPT_RAISE,
    input           BUS_INTERRUPT_ACK
);

    // Internal wires for mouse data outputs
    wire        [3:0]   mouseStatus;
    wire        [7:0]   mouseX;
    wire        [7:0]   mouseY;
    wire                interruptSignal;

    // Address parameters for mouse registers (adjustable for different projects)
    parameter   [7:0]   MouseBaseADDR = 8'hA0;
    parameter   [7:0]   MouseHighADDR = 8'hA2;
    parameter   [7:0]   DPIADDR       = 8'hA3;

    // Bus interface internal signals
    reg                 busWriteEnable;
    reg         [7:0]   busDataOut;
    reg         [15:0]  dpiConfig;

    // Instantiate the mouse transceiver module
    MouseTransceiver mouseTransceiverInst(
        // Standard inputs
        .RESET(RESET),
        .CLK(CLK),
        // Mouse I/O
        .CLK_MOUSE(CLK_MOUSE),
        .DATA_MOUSE(DATA_MOUSE),
        // Mouse data outputs and interrupt
        .INTERRUPT(interruptSignal),
        .MouseStatus(mouseStatus),
        .MouseX(mouseX),
        .MouseY(mouseY)
    );

    // Interrupt generation logic:
    // - Raise the BUS_INTERRUPT_RAISE when the mouse transceiver signals an interrupt.
    // - Lower the BUS_INTERRUPT_RAISE on system reset or when the interrupt is acknowledged.
    always @(posedge CLK) begin
        if (RESET)
            BUS_INTERRUPT_RAISE <= 1'b0;
        else if (interruptSignal)
            BUS_INTERRUPT_RAISE <= 1'b1;
        else if (BUS_INTERRUPT_ACK)
            BUS_INTERRUPT_RAISE <= 1'b0;
    end

    // Aggregate mouse data into an array for modular access.
    // Note: mouseStatus is 4-bit, so zero-extended to 8 bits.
    wire [7:0] mouseDataArray [2:0];
    assign mouseDataArray[0] = {4'b0, mouseStatus};
    assign mouseDataArray[1] = mouseX;
    assign mouseDataArray[2] = mouseY;  

    // Drive BUS_DATA when the mouse is in read mode (i.e. when the processor is not writing)
    assign BUS_DATA = (busWriteEnable) ? busDataOut : 8'hZZ;

    // Bus read logic:
    // - Select data based on BUS_ADDR offset (A0 = MouseStatus, A1 = MouseX, A2 = MouseY).
    // - Enable bus output when address is within the mouse range and processor is not writing.
    always @(posedge CLK) begin
        busDataOut <= mouseDataArray[BUS_ADDR[3:0]]; 
        
        if ((BUS_ADDR >= MouseBaseADDR) & (BUS_ADDR <= MouseHighADDR))
            busWriteEnable <= ~Bus2MouseWE;
        else
            busWriteEnable <= 1'b0;
    end

    // DPI configuration logic:
    // - Store the DPI value when the processor writes to the DPI address.
    always @(posedge CLK) begin
        if (RESET)
            dpiConfig <= 16'h0000;
        else if (Bus2MouseWE) begin
            if (BUS_ADDR == DPIADDR)
                dpiConfig <= BUS_DATA;
        end
    end

endmodule
