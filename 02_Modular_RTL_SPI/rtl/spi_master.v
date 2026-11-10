
module spi_master #
(
  parameter DATA_WIDTH    = 8,
  parameter CLK_DIV_WIDTH = 8,
  parameter CPOL          = 1'b0,
  parameter CPHA          = 1'b0
)
(
  input wire clk,
  input wire rst_n,

  // External signals
  input wire start,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire miso,
  input wire msb_first,
  input wire [CLK_DIV_WIDTH-1:0] clk_div,

  // Outputs
  output wire mosi,
  output wire sclk,
  output wire ss_n,
  output wire [DATA_WIDTH-1:0] rx_data,
  output wire busy,
  output wire done
);

  // Internal wires
  wire spi_clk;
  wire spi_tick;
  wire spi_rise;
  wire spi_fall;

  wire load;
  wire tx_shift_en;
  wire rx_sample_en;
  wire count_en;

  wire bit_done;
  wire [$clog2(DATA_WIDTH)-1:0] bit_count;
  wire enable_clk;

  // Clock divider
  spi_clk_divider #(
    .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
    .CPOL(CPOL)
  ) u_clk_divider (
    .clk      (clk),
    .rst_n    (rst_n),
    .enable   (enable_clk),
    .clk_div  (clk_div),
    .spi_clk  (spi_clk),
    .spi_tick (spi_tick),
    .spi_rise (spi_rise),
    .spi_fall (spi_fall)
  );

  // Master controller
  spi_master_ctrl #(
    .DATA_WIDTH(DATA_WIDTH),
    .CPOL      (CPOL),
    .CPHA      (CPHA)
  ) u_master_ctrl (
    .clk          (clk),
    .rst_n        (rst_n),
    .start        (start),
    .spi_clk      (spi_clk),
    .spi_tick     (spi_tick),
    .spi_rise     (spi_rise),
    .spi_fall     (spi_fall),
    .bit_count    (bit_count),
    .load         (load),
    .tx_shift_en  (tx_shift_en),
    .rx_sample_en (rx_sample_en),
    .count_en     (count_en),
    .busy         (busy),
    .done         (done),
    .ss_n         (ss_n),
    .enable_clk   (enable_clk)
  );

  // Master datapath
  spi_master_datapath #(
    .DATA_WIDTH(DATA_WIDTH)
  ) u_master_datapath (
    .clk          (clk),
    .rst_n        (rst_n),
    .load         (load),
    .tx_shift_en  (tx_shift_en),
    .rx_sample_en (rx_sample_en),
    .count_en     (count_en),
    .msb_first    (msb_first),
    .tx_data      (tx_data),
    .miso         (miso),
    .mosi         (mosi),
    .rx_data      (rx_data),
    .bit_done     (bit_done),
    .bit_count    (bit_count)
  );

  // External SPI clock
  assign sclk = spi_clk;

endmodule

