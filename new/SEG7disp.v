`timescale 1ns / 1ps

module SEG7disp (
    input                   CLK,
    input   [3:0]           IN0,IN1,IN2,IN3,

    output  	[3:0]       SEG_SELECT_OUT,
    output  	[7:0]       HEX_OUT
);

    wire [1:0] StrobeCount;
    wire [4:0] MuxOut;
    wire Bit17TriggOut;


/////Counter/////////////////////
    //base clk counter
    Generic_counter # (.COUNTER_WIDTH(17), .COUNTER_MAX(99999))
        Bit17Counter (
            .RESET(1'b0),
            .CLK(CLK),
            .ENABLE(1'b1),
            .TRIGGER_OUT(Bit17TriggOut)
    );

    // Strobe counter for 4-way mux
    Generic_counter # (.COUNTER_WIDTH(2), .COUNTER_MAX(3))
        Bit2Counter (
            .RESET(1'b0),
            .CLK(CLK),
            .ENABLE(Bit17TriggOut),
            .COUNT(StrobeCount)
    );

/////Multiplexer_4way with dot in middle/////////////////////
    Multiplexer_4way MUX (
        .CONTROL(StrobeCount),
        .IN0({1'b0, IN0}),
        .IN1({1'b0, IN1}),
        .IN2({1'b1, IN2}),
        .IN3({1'b0, IN3}),
        .OUT(MuxOut)
    );

/////seg7 decoder////////////////////
    seg7decoder seg7 (
		.SEG_SELECT_IN(StrobeCount),
		.BIN_IN(MuxOut[3:0]),
		.DOT_IN(MuxOut[4]),
		.SEG_SELECT_OUT(SEG_SELECT_OUT),
		.HEX_OUT(HEX_OUT)
	);
endmodule