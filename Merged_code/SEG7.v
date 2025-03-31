`timescale 1ns / 1ps

module SEG7(
    input CLK,
    input RESET,
    
    // Bus interface: assume address D0 is used to write the X coordinate,
    // and address D1 is used to write the Y coordinate.
    input [7:0] BUS_ADDR,
    input [7:0] BUS_DATA,
    input BUS_WE,

    // 7-segment display outputs
    output [7:0] HEX_OUT,
    output [3:0] SEG_SELECT_OUT
);

    // Base address for writing coordinates
    parameter [7:0] Seg7BaseADDR = 8'hD0;

    // Registers to store the mouse's X and Y coordinates on the VGA screen
    reg [7:0] x_coord;
    reg [7:0] y_coord;
    
    // Register to store the display value corresponding to the region code.
    // Only the lower 8 bits (two nibbles representing two characters) are used;
    // the higher 8 bits are set to blank.
    reg [15:0] region_disp;

    // Define the encoding for each character.
    // F and B are assumed to use standard 7-segment hexadecimal codes,
    // while I, L, R are assigned custom codes. BLANK is represented by 4'b0000.
    localparam BLANK  = 4'b0000;
    localparam F_CHAR = 4'hF;  // F
    localparam B_CHAR = 4'hB;  // B
    localparam I_CHAR = 4'b0001; // Custom: representing I (Idle)
    localparam L_CHAR = 4'b0010; // Custom: representing L (Left)
    localparam R_CHAR = 4'b0011; // Custom: representing R (Right)

    // Capture X and Y coordinates based on bus write operations
    always @(posedge CLK) begin
        if (RESET) begin
            x_coord <= 8'd0;
            y_coord <= 8'd0;
        end else if (BUS_WE) begin
            if (BUS_ADDR == Seg7BaseADDR)
                x_coord <= BUS_DATA;  // Write X coordinate
            else if (BUS_ADDR == (Seg7BaseADDR + 1))
                y_coord <= BUS_DATA;  // Write Y coordinate
        end
    end

    
    always @(posedge CLK) begin
        if (RESET)
            region_disp <= 16'd0;
        else begin
            // Determine column based on x_coord (Left, Center, Right)
            if (x_coord < 8'd53) begin
                // Left column
                if (y_coord < 8'd40)
                    region_disp <= {8'd0, {F_CHAR, L_CHAR}};  // Top-Left: FL
                else if (y_coord < 8'd80)
                    region_disp <= {8'd0, {BLANK, L_CHAR}};   // Middle-Left: L
                else
                    region_disp <= {8'd0, {B_CHAR, L_CHAR}};    // Bottom-Left: BL
            end else if (x_coord < 8'd107) begin
                // Center column
                if (y_coord < 8'd40)
                    region_disp <= {8'd0, {BLANK, F_CHAR}};   // Top-Center: F
                else if (y_coord < 8'd80)
                    region_disp <= {8'd0, {BLANK, I_CHAR}};   // Middle-Center: I (Idle)
                else
                    region_disp <= {8'd0, {BLANK, B_CHAR}};    // Bottom-Center: B
            end else begin
                // Right column
                if (y_coord < 8'd40)
                    region_disp <= {8'd0, {F_CHAR, R_CHAR}};  // Top-Right: FR
                else if (y_coord < 8'd80)
                    region_disp <= {8'd0, {BLANK, R_CHAR}};   // Middle-Right: R
                else
                    region_disp <= {8'd0, {B_CHAR, R_CHAR}};    // Bottom-Right: BR
            end
        end
    end

    // Form the final 16-bit display value.
    // Only the lower 8 bits (two characters) are used; the upper 8 bits are blank.
    wire [15:0] final_disp;
    assign final_disp = {8'b0, region_disp[7:0]};

    // Instantiate the 7-segment display driver module.
    // The two lower digits (IN0 and IN1) display the region code, and the upper two digits (IN2 and IN3)
    // are kept blank.
    SEG7disp seg7_inst (
        .CLK(CLK),
        .IN0(final_disp[3:0]),     // Rightmost digit (low nibble)
        .IN1(final_disp[7:4]),     // Second digit
        .IN2(final_disp[11:8]),    // Third digit (blank)
        .IN3(final_disp[15:12]),   // Leftmost digit (blank)
        .SEG_SELECT_OUT(SEG_SELECT_OUT),
        .HEX_OUT(HEX_OUT)
    );

endmodule
