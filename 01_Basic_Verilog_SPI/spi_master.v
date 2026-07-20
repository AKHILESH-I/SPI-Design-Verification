module spi_master(
input clk, rst, start, input [7:0] tx_data,
output reg mosi, sclk, ss_n, done);
parameter IDLE = 2'b00;
parameter LOAD = 2'b01;
parameter SHIFT = 2'b10;
parameter DONE = 2'b11;
reg [1:0] state;
reg [7:0] shift_reg;
reg [2:0] bit_count;
always @(posedge clk or negedge rst)
begin
if(!rst) begin
state <= IDLE;
ss_n <= 1;
sclk <= 0;
done <= 0;
end
else begin
case(state)
IDLE: begin
done <= 0;
if(start) state <= LOAD;
end
LOAD:begin
shift_reg <= tx_data;
bit_count <= 7;
ss_n <= 0;
state <= SHIFT;
end
SHIFT: begin
sclk <= ~sclk;
if(sclk == 0) begin
mosi <= shift_reg[7];
shift_reg <= shift_reg << 1;
if(bit_count == 0)
state <= DONE;
else
bit_count <= bit_count - 1;
end
end
DONE: begin
ss_n <= 1;
done <= 1;
sclk <= 0;
state <= IDLE;
end
endcase
end
end
endmodule
