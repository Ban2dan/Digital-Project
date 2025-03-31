`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 13:41:58
// Design Name: 
// Module Name: MouseTransceiver
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


module MouseTransceiver(
    // Standard Inputs
    input        RESET,
    input        CLK,

    // IO - Mouse side (PS/2)
    inout        CLK_MOUSE,
    inout        DATA_MOUSE,

    // Mouse data outputs
    output reg [7:0] MouseStatus,
    output reg [7:0] MouseX,
    output reg [7:0] MouseY,
    output     [7:0] MouseDX,
    output     [7:0] MouseDY,
    output            INTERRUPT
);

    // Mouse coordinate limits
    parameter [7:0] MouseLimitX = 160;
    parameter [7:0] MouseLimitY = 120;

    // Initialize mouse status and position
    initial begin
        MouseStatus <= 8'd0;
        MouseX      <= MouseLimitX / 2; 
        MouseY      <= MouseLimitY / 2;
    end

   
    // 1) Tri-state signals for PS/2 clock and data
   
    reg         ClkMouseIn;             // Filtered clock from mouse
    wire        ClkMouseOutEnTrans;     // Drive clock low when 1
    wire        DataMouseIn;            // Mouse data input
    wire        DataMouseOutTrans;      // Data driven by transmitter
    wire        DataMouseOutEnTrans;    // Drive data line when 1

    // Tri-state assignment for clock
    assign CLK_MOUSE = ClkMouseOutEnTrans ? 1'b0 : 1'bz;

    // Tri-state assignment for data
    assign DATA_MOUSE   = DataMouseOutEnTrans ? DataMouseOutTrans : 1'bz;
    assign DataMouseIn  = DATA_MOUSE;

   
    // 2) Filter the incoming mouse clock to detect stable edges
   
    reg [7:0] MouseClkFilter;

    always @(posedge CLK) begin
        if (RESET) begin
            ClkMouseIn <= 1'b0;
            MouseClkFilter <= 8'h00;
        end 
        else begin
            // Shift register for debouncing / filtering
            MouseClkFilter[7:1] <= MouseClkFilter[6:0];
            MouseClkFilter[0]   <= CLK_MOUSE;

            // Falling edge detection
            if (ClkMouseIn && (MouseClkFilter == 8'h00))
                ClkMouseIn <= 1'b0;
            // Rising edge detection
            else if (~ClkMouseIn && (MouseClkFilter == 8'hFF))
                ClkMouseIn <= 1'b1;
        end
    end

   
    // 3) Instantiate the MouseTransmitter
   
    wire       SendByteToMouse;
    wire       ByteSentToMouse;
    wire [7:0] ByteToSendToMouse;

    MouseTransmitter T (
        // Standard Inputs
        .RESET             (RESET),
        .CLK               (CLK),
        // Mouse IO - CLK
        .CLK_MOUSE_IN      (ClkMouseIn),
        .CLK_MOUSE_OUT_EN  (ClkMouseOutEnTrans),
        // Mouse IO - DATA
        .DATA_MOUSE_IN     (DataMouseIn),
        .DATA_MOUSE_OUT    (DataMouseOutTrans),
        .DATA_MOUSE_OUT_EN (DataMouseOutEnTrans),
        // Control
        .SEND_BYTE         (SendByteToMouse),
        .BYTE_TO_SEND      (ByteToSendToMouse),
        .BYTE_SENT         (ByteSentToMouse)
    );

   
    // 4) Instantiate the MouseReceiver
   
    wire       ReadEnable;
    wire [7:0] ByteRead;
    wire [1:0] ByteErrorCode;
    wire       ByteReady;

    MouseReceiver R (
        // Standard Inputs
        .RESET          (RESET),
        .CLK            (CLK),
        // Mouse IO - CLK
        .CLK_MOUSE_IN   (ClkMouseIn),
        // Mouse IO - DATA
        .DATA_MOUSE_IN  (DataMouseIn),
        // Control
        .READ_ENABLE    (ReadEnable),
        .BYTE_READ      (ByteRead),
        .BYTE_ERROR_CODE(ByteErrorCode),
        .BYTE_READY     (ByteReady)
    );

   
    // 5) Instantiate the Master State Machine
   
    wire [7:0] MouseStatusRaw;
    wire [7:0] MouseDxRaw;
    wire [7:0] MouseDyRaw;
    wire       SendInterrupt;
    wire [3:0] MasterStateCode; // (Optional: for debugging)

    MouseMasterSM MSM (
        // Standard Inputs
        .RESET          (RESET),
        .CLK            (CLK),
        // Transmitter Interface
        .SEND_BYTE      (SendByteToMouse),
        .BYTE_TO_SEND   (ByteToSendToMouse),
        .BYTE_SENT      (ByteSentToMouse),
        // Receiver Interface
        .READ_ENABLE    (ReadEnable),
        .BYTE_READ      (ByteRead),
        .BYTE_ERROR_CODE(ByteErrorCode),
        .BYTE_READY     (ByteReady),
        // Data Registers
        .MOUSE_STATUS   (MouseStatusRaw),
        .MOUSE_DX       (MouseDxRaw),
        .MOUSE_DY       (MouseDyRaw),
        .SEND_INTERRUPT (SendInterrupt)
        
    );

    // Make raw DX/DY visible externally
    assign MouseDX   = MouseDxRaw;
    assign MouseDY   = MouseDyRaw;
    assign INTERRUPT = SendInterrupt;

   
    // 6) Pre-processing for overflow/sign bits, updating X/Y with boundaries
   
    

    wire signed [8:0] MouseDx; // 9-bit potential displacement in X
    wire signed [8:0] MouseDy; // 9-bit potential displacement in Y

    // X Movement
    assign MouseDx =
        (MouseStatusRaw[6]) 
        ? // X Overflow bit set
          (MouseStatusRaw[4] ? {MouseStatusRaw[4], 8'h00} : {MouseStatusRaw[4], 8'hFF})
        : // Normal case: sign-extend the X sign bit
          {MouseStatusRaw[4], MouseDxRaw[7:0]};

    // Y Movement
    assign MouseDy =
        (MouseStatusRaw[7])
        ? // Y Overflow bit set
          (MouseStatusRaw[5] ? {MouseStatusRaw[5], 8'h00} : {MouseStatusRaw[5], 8'hFF})
        : // Normal case: sign-extend the Y sign bit
          {MouseStatusRaw[5], MouseDyRaw[7:0]};

    // Compute next X/Y by adding 9-bit signed offsets
    wire signed [8:0] MouseNewX = {1'b0, MouseX} + MouseDx;
    wire signed [8:0] MouseNewY = {1'b0, MouseY} + MouseDy;

    // Update MouseStatus, MouseX, MouseY on packet completion
    always @(posedge CLK) begin
        if (RESET) begin
            MouseStatus <= 8'd0;
            MouseX      <= MouseLimitX / 2; 
            MouseY      <= MouseLimitY / 2;
        end
        else if (SendInterrupt) begin
            // Update status register
            MouseStatus <= MouseStatusRaw;

            // Boundary check for X
            if (MouseNewX < 0)
                MouseX <= 0;
            else if (MouseNewX > (MouseLimitX - 1))
                MouseX <= MouseLimitX - 1;
            else
                MouseX <= MouseNewX[7:0];

            // Boundary check for Y
            if (MouseNewY < 0)
                MouseY <= 0;
            else if (MouseNewY > (MouseLimitY - 1))
                MouseY <= MouseLimitY - 1;
            else
                MouseY <= MouseNewY[7:0];
        end
    end

endmodule
