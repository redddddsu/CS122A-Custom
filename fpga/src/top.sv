module top
(
    input  CLK, //FPGA's clocck

    input logic mosi,
    input logic sclk,
    input logic cs,
    output logic miso,

	output logic LCD_CLK,//LCD clock. 
	output logic LCD_DEN,
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


    input logic rst,
    input logic pclk, 

    output logic LCD_DE,      // Display Enable

    output logic[4:0] LCD_B, // 5-bit blue color data
    output logic[5:0] LCD_G, // 6-bit green color data
    output logic[4:0] LCD_R  // 5-bit red color data
);

parameter H_ACTIVE = 480;
parameter V_ACTIVE = 272;

parameter H_TOTAL = 525;
parameter V_TOTAL = 285;

parameter CELL_SIZE = 16;
parameter MAX_X = 15;
parameter MAX_Y = 8;

localparam FRAME_SIZE = MAX_X * MAX_Y;

logic[10:0] horizontal;
logic[10:0] vertical;

logic[8:0]  waddr;
logic[7:0] wdata;

logic [4:0] maze[0:FRAME_SIZE-1];


logic[7:0] shift_reg;
logic[2:0] bit_counter;

logic [7:0] rx;

logic switch_screen;
always_ff @(posedge sclk) begin
    if (cs) begin
        bit_counter <= 0;
        shift_reg <= 0;
        waddr <= 0;
    end
    else begin
        shift_reg <= {shift_reg[6:0], mosi};
        if (bit_counter == 7 && waddr < FRAME_SIZE) begin
            rx = {shift_reg[6:0], mosi};
            maze[waddr] <= rx[4:0]; 
            switch_screen <= rx[6];
            waddr <= waddr + 1;
            bit_counter <= 0;
           
        end
        else begin
            bit_counter <= bit_counter + 1;
            if (waddr >= FRAME_SIZE) 
                waddr <= 0;
        end
    end
end

logic [5:0] cx, cy;
logic inside;
logic[8:0] index;
logic[4:0] cell;

always_comb begin
    inside = (horizontal < MAX_X * CELL_SIZE) && (vertical < MAX_Y * CELL_SIZE);
    cell = 5'b0000;
    cx = 0;
    cy = 0;
    index = 0;
    if (inside) begin
        cx = horizontal / CELL_SIZE;
        cy = vertical   / CELL_SIZE;

        index = cy * MAX_X + cx;
        cell  = maze[index];
    end
end

logic[5:0] x;
logic[5:0] y;

always_comb begin
    x = horizontal % CELL_SIZE;
    y = vertical % CELL_SIZE;
end

logic top;
logic right;
logic bottom;
logic left;
logic curr_pos;

always_comb begin
    top = cell[0];
    right = cell[1];
    bottom = cell[2];
    left = cell[3];
    curr_pos = cell[4];
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
logic location;

always_ff @(posedge pclk) begin
    wall <= 0;
    location <= 0;
    if (inside) begin
        if (top && y == 0)
            wall <= 1;
        if (bottom && y == CELL_SIZE-1)
            wall <= 1;
        if (left && x == 0)
            wall <= 1;
        if (right && x == CELL_SIZE-1)
            wall <= 1;
        if (curr_pos)
            location <= 1;
    end
end

logic screen;

localparam SCREEN_START = 0;
localparam SCREEN_GAME = 1;

always_ff @(posedge pclk) begin
    if (switch_screen == 0) 
        screen <= SCREEN_START;
    else
        screen <= SCREEN_GAME;
    
end

always_ff @(posedge pclk) begin
    if (screen == SCREEN_START) begin
        if (title_pixel) begin
            LCD_R <= 0;
            LCD_G <= 0;
            LCD_B <= 0;
        end
        else begin
            LCD_R <= 21;
            LCD_G <= 0;
            LCD_B <= 0;
        end
    end else if (screen == SCREEN_GAME) begin
        if (wall) begin
            LCD_R <= 0;
            LCD_G <= 0;
            LCD_B <= 0;
        end else if (location) begin
            LCD_R <= 0;
            LCD_G <= 21;
            LCD_B <= 0;
        end else begin
            LCD_R <= 21;
            LCD_G <= 0;
            LCD_B <= 0;
        
        end

    end





end

logic title_pixel;

always_comb begin
    title_pixel = 0;

    if (
        ((horizontal >= 120 && horizontal < 128) && (vertical >= 80  && vertical < 160))
        ||
        ((horizontal >= 152 && horizontal < 160) && (vertical >= 80  && vertical < 160))
        ||
        ((horizontal >= 128 && horizontal < 136) && (vertical >= 88  && vertical < 96))
        ||
        ((horizontal >= 144 && horizontal < 152) && (vertical >= 88  && vertical < 96))
        ||
        ((horizontal >= 136 && horizontal < 144) && (vertical >= 96 && vertical < 104))
    )
        title_pixel = 1;
    if (
        ((horizontal >= 180 && horizontal < 188) && (vertical >= 80  && vertical < 160))
        ||
        ((horizontal >= 212 && horizontal < 220) && (vertical >= 80  && vertical < 160))
        ||
        ((horizontal >= 180 && horizontal < 220) && (vertical >= 80  && vertical < 88))
        ||
        ((horizontal >= 180 && horizontal < 220) && (vertical >= 116 && vertical < 124))
    )
        title_pixel = 1;
    if (
        ((horizontal >= 240 && horizontal < 280) && (vertical >= 80  && vertical < 88))
        ||
        ((horizontal >= 240 && horizontal < 280) && (vertical >= 152 && vertical < 160))
        ||
        ((horizontal - 240) + (vertical - 80) >= 64 && (horizontal - 240) + (vertical - 80) < 80 && horizontal >= 240 && horizontal < 280 && vertical >= 80 && vertical < 160)
    )
        title_pixel = 1;

    if (
        ((horizontal >= 300 && horizontal < 308) &&(vertical >= 80  && vertical < 160))
        ||
        ((horizontal >= 300 && horizontal < 340) && (vertical >= 80  && vertical < 88))
        ||
        ((horizontal >= 300 && horizontal < 336) && (vertical >= 116 && vertical < 124))
        ||
        ((horizontal >= 300 && horizontal < 340) && (vertical >= 152 && vertical < 160))

    )
        title_pixel = 1;

end


endmodule