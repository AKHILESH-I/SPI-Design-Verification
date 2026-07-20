module spi_slave(
input sclk, ss_n, mosi,
output reg [7:0] rx_data);
reg [2:0] bit_count;
always @(posedge sclk)
begin
if(!ss_n) begin
rx_data <= {rx_data[6:0], mosi};
bit_count <= bit_count + 1;
end
end
endmodule
