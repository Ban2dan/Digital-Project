`timescale 1ns / 1ps

module TOP(
        input                   CLK,
        input                   RESET,        
        inout                   CLK_MOUSE,
        inout                   DATA_MOUSE,
        output                  IR_LED,
        output      [7:0]       COLOUR_OUT,
        output                  HS,
        output                  VS,
        
        output      [3:0]       SEG_SELECT_OUT,
        output      [7:0]       HEX_OUT,
        output      [15:0]      LED_OUT,
        input       [7:0]       SWITCH_IN 
        );
  
    
        wire [1:0] BUS_INTERRUPTS_RAISE; // 0: Mouse, 1: Timer
        wire [1:0] BUS_INTERRUPTS_ACK; // 0: Mouse, 1: Timer
        
            wire [7:0] BusData; // 8-bit data bus
            wire [7:0] BusAddr; // 8-bit address bus
            wire BusWE; // Write enable signal
            wire [7:0] ROMaddr; // 8-bit address bus
            wire [7:0] ROMdata; // 8-bit data bus
            wire [1:0] interuptRAISE; // 0: Mouse, 1: Timer
            wire [1:0] interuptACK; // 0: Mouse, 1: Timer
            

        
        
            ProcessorModule CPU(
                    .CLK(CLK),
                    .RESET(RESET),
                    .BUS_DATA(BusData),
                    .BUS_ADDR(BusAddr),
                    .BUS_WE(BusWE),
                    .ROM_ADDRESS(ROMaddr),
                    .ROM_DATA(ROMdata),
                    .BUS_INTERRUPTS_RAISE(interuptRAISE),
                    .BUS_INTERRUPTS_ACK(interuptACK)
            );
            
                
            ROM rom(
                .CLK(CLK),
                .ADDR(ROMaddr),
                .DATA(ROMdata)
                );
            
            RAM ram(
                .CLK(CLK),
                .BUS_WE(BusWE),
                .BUS_ADDR(BusAddr),  
                .BUS_DATA(BusData)
                );
                
                
            VGA_Controller VGA(
                .CLK(CLK),
                .RESET(RESET),
                .BUS_ADDR(BusAddr),
                .BUS_DATA(BusData),
                .BUS_WE(BusWE),
                .COLOUR_OUT(COLOUR_OUT),
                .HS(HS),
                .VS(VS)
           );
                    
                
            IR IR(
                .RESET(RESET),
                .CLK(CLK),
                .BUS_ADDR(BusAddr),
                .BUS_DATA(BusData),
                .BUS_WE(BusWE),
                .IR_LED(IR_LED)
                );
             
        Timer timer (
            .CLK(CLK),
            .RESET(RESET),
            .BUS_DATA(BusData),
            .BUS_ADDR(BusAddr),
            .BUS_WE(BusWE),
            .BUS_INTERRUPT_RAISE(interuptRAISE[1]),
            .BUS_INTERRUPT_ACK(interuptACK[1])
        );
    
        Mouse MP (
            .CLK(CLK),
            .RESET(RESET),
            .CLK_MOUSE(CLK_MOUSE),
            .DATA_MOUSE(DATA_MOUSE),
            .BUS_ADDR(BusAddr),
            .BUS_DATA(BusData),
            .Bus2MouseWE(BusWE),
            .BUS_INTERRUPT_RAISE(interuptRAISE[0]),
            .BUS_INTERRUPT_ACK(interuptACK[0])
        );
    
        LED LP (
            .CLK(CLK),
            .RESET(RESET),
            .BUS_ADDR(BusAddr),
            .BUS_DATA(BusData),
            .BUS_WE(BusWE),
            .LED_OUT(LED_OUT)
        );
    
        SEG7 SEGP (
            .CLK(CLK),
            .RESET(RESET),
            .BUS_ADDR(BusAddr),
            .BUS_DATA(BusData),
            .BUS_WE(BusWE),
            .HEX_OUT(HEX_OUT),
            .SEG_SELECT_OUT(SEG_SELECT_OUT)
        );
    
        

endmodule
