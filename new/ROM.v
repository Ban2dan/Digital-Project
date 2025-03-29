//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/04 11:46:39
// Design Name: 
// Module Name: ROM
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


module ROM(
    input CLK,
    input [7:0] ADDR,
    output reg [7:0] DATA
    );
    
    parameter RAMAddrWidth = 8;
    
    //Memory
    reg [7:0] ROM [2**RAMAddrWidth-1:0];
    //
    initial $readmemh("Complete_Demo_ROM.txt", ROM);
    
    //single port ram
    always@(posedge CLK)begin
        DATA <= ROM[ADDR];
    end
        
endmodule
