// Module : spi_clk_divider
module spi_clk_divider #
(
  parameter CLK_DIV_WIDTH = 8,
  parameter CPOL = 0)
(
  input wire clk,
  input wire rst_n,
  input wire enable,

  input wire [CLK_DIV_WIDTH-1:0] clk_div,

  output reg spi_clk,
  output wire spi_tick,
  output wire spi_rise,
  output wire spi_fall
);
  reg [CLK_DIV_WIDTH-1:0] div_cnt;
  assign spi_tick = enable && ((clk_div == '0) || (div_cnt == (clk_div - 1'b1)));

  assign spi_rise = spi_tick && (spi_clk == 1'b0);

  assign spi_fall = spi_tick && (spi_clk == 1'b1);
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      spi_clk <= CPOL;
      div_cnt <= '0;
    end
    else begin
      if(!enable) begin
        div_cnt <= '0;
        spi_clk <= CPOL;
      end
      else begin
        if(clk_div == '0) begin
          div_cnt <= '0;
          spi_clk <= ~spi_clk;
        end
        else if(div_cnt == (clk_div - 1'b1)) begin
          div_cnt <= '0;
          spi_clk <= ~spi_clk;
        end
        else begin
          div_cnt <= div_cnt + 1'b1;
        end
      end
    end
  end
endmodule
