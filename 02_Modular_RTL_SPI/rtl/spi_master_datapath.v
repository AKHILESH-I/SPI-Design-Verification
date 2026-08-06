module spi_master_datapath #
(
  parameter DATA_WIDTH = 8
)
(
  input wire clk,
  input wire rst_n,
  //Control Signals
  input wire load,
  input wire shift_en,
  input wire count_en,
  input wire msb_first,
  //Parallel Transmit Data
  input wire [DATA_WIDTH-1:0] tx_data,
  //Serial Input
  input wire miso,
  //Datapath Outputs
  output wire mosi,
  output wire [DATA_WIDTH-1:0] rx_data,
  output wire bit_done,
  output wire [$clog2(DATA_WIDTH)-1:0] bit_count
);
  //Shift Register
  spi_shift_register #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_shift_register(
      .clk         (clk), 
      .rst_n       (rst_n), 
      .load        (load), 
      .shift_en    (shift_en),
      .msb_first   (msb_first), 
      .parallel_in (tx_data),  
      .serial_in   (miso), 
      .serial_out  (mosi), 
      .parallel_out(rx_data));
  //Bit counter
  spi_bit_counter #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_bit_counter(
      .clk      (clk), 
      .rst_n    (rst_n), 
      .load     (load), 
      .count_en (count_en),
      .bit_done (bit_done), 
      .bit_count(bit_count));

endmodule
