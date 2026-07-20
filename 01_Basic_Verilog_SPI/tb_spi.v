module tb;
reg clk, rst, start;
reg [7:0] tx_data;
wire mosi, sclk, ss_n, done;
wire [7:0] rx_data;
spi_master M(.clk(clk), .rst(rst), .start(start), .tx_data(tx_data), .mosi(mosi), .sclk(sclk), .ss_n(ss_n), .done(done));
spi_slave S(.sclk(sclk), .ss_n(ss_n), .mosi(mosi), .rx_data(rx_data));
initial clk = 0;
always #5 clk = ~clk;
initial begin
rst = 0;
start = 0;
#10 rst = 1;
tx_data = 8'hA5;
#10 start = 1;
#10 start = 0;
#500 $finish;
end
always @(posedge done)
begin
$display("tx = %0h", tx_data);
$display("rx = %0h", rx_data);
end
endmodule
