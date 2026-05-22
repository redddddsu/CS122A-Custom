`include "src/sprite_buf_EX2.sv"

module top
(
    input  CLK, //FPGA's clocck

    input logic mosi,
    input logic sclk,
    input logic cs,
    output logic miso,

	output LCD_CLK,//LCD clock. 
	output LCD_DEN,
	output logic[4:0] LCD_R,
	output logic[5:0] LCD_G,
	output logic[4:0] LCD_B
);


lcd u_lcd (
    .mosi(mosi),
    .sclk(sclk),
    .cs(cs),
    .miso(miso),
    .rst(0),      
    .pclk(CLK),
    .LCD_DE(LCD_DEN),
    .LCD_R(LCD_R),
    .LCD_G(LCD_G),
    .LCD_B(LCD_B)
);
assign LCD_CLK = CLK;

endmodule

module lcd
(
    input logic mosi,
    input logic sclk,
    input logic cs,
    output logic miso,


    input  rst,
    input  pclk, 

    output LCD_DE,      // Display Enable

    output logic[4:0] LCD_B, // 5-bit blue color data
    output logic[5:0] LCD_G, // 6-bit green color data
    output logic[4:0] LCD_R  // 5-bit red color data
);

parameter H_ACTIVE = 480;
parameter V_ACTIVE = 272;

parameter H_TOTAL = 525;
parameter V_TOTAL = 285;

parameter CELL_SIZE = 16;
parameter MAX_X = 30;

logic[10:0] horizontal;
logic[10:0] vertical;

logic[8:0]  waddr;
logic[7:0] wdata;
logic we;

logic[7:0] maze_cell;
logic[7:0] maze[0:511];


logic[7:0] shift_reg;
logic[2:0] bit_counter;
always_ff @(posedge sclk) begin
    we <= 0;
    if (!cs) begin
        shift_reg <= {shift_reg[6:0], mosi};
        if (bit_counter == 7) begin
            wdata <= {shift_reg[6:0], mosi};
            waddr <= waddr + 1;
            we <= 1;
            bit_counter <= 0;
        end
        else begin
            bit_counter <= bit_counter + 1;
        end
    end
    else begin
        bit_counter <= 0;
        shift_reg <= 0;
        waddr <= 0;
    end
end

always_ff @(posedge pclk) begin
    if (we)
        maze[waddr] <= wdata;
end

logic [5:0] cx, cy;

always_comb begin
    if (horizontal >= H_ACTIVE)
        cx = MAX_X - 1;
    else
        cx = horizontal / CELL_SIZE;

    if (vertical >= V_ACTIVE)
        cy = MAX_Y - 1;
    else
        cy = vertical / CELL_SIZE;

    index = cy * MAX_X + cx;
    cell = maze[index];
end

logic[5:0] x;
logic[5:0] y;

logic[8:0] index;
logic[7:0] cell;

always_comb begin
    x = horizontal % CELL_SIZE;
    y = vertical % CELL_SIZE;
end

logic top;
logic right;
logic bottom;
logic left;

always_comb begin
    top = cell[0];
    right = cell[1];
    bottom = cell[2];
    left = cell[3];
end

always_ff @(posedge pclk) begin
    if (rst) begin
        horizontal <= 0;
        vertical <= 0;
    end else begin 
        if (horizontal == H_TOTAL - 1) begin
            horizontal <= 0;
            if (vertical == V_TOTAL - 1)
                vertical <= 0;
            else
                vertical <= vertical + 1;
        end else begin
            horizontal <= horizontal + 1;
end
    
    end
end

always_ff @(posedge pclk) begin
    LCD_DE <= (horizontal < H_ACTIVE) && (vertical < V_ACTIVE);
end

logic wall;

always_comb begin
    wall = 0;
    if (top && y == 0)
        wall = 1;
    if (bottom && y == CELL_SIZE-1)
        wall = 1;
    if (left && x == 0)
        wall = 1;
    if (right && x == CELL_SIZE-1)
        wall = 1;
end

always_ff @(posedge pclk) begin
    if (wall) begin
        LCD_R <= 5'h1F;
        LCD_G <= 6'h3F;
        LCD_B <= 5'h1F;
    end else begin
        LCD_R <= 255;
        LCD_G <= 0;
        LCD_B <= 0;
    end

end

endmodule