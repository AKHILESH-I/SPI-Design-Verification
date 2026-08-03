module spi_clk_divider 
#(  parameter CLK_DIV_WIDTH = 8,
    parameter CPOL = 0)
(   input wire clk, rst_n, enable,
    input wire [CLK_DIV_WIDTH-1:0] clk_div,
    output reg spi_clk, spi_tick
);
  reg [CLK_DIV_WIDTH-1:0] div_cnt;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      spi_clk  <= CPOL;
      spi_tick <= 1'b0;
      div_cnt  <= '0;
    end
    else begin
      if(!enable) begin
        div_cnt  <= '0;
        spi_clk  <= CPOL;
        spi_tick <= 1'b0;
      end
      else begin
        spi_tick <= 0;
        if(clk_div == '0) begin
            spi_clk  <= ~spi_clk;
            div_cnt  <= 0;
            spi_tick <= 1'b1;
        end
        else if(div_cnt == (clk_div - 1'b1)) begin
            div_cnt  <=0;
            spi_clk  <= ~spi_clk;
            spi_tick <= 1'b1; //
        end
        else begin
          div_cnt <= div_cnt + 1;
        end
      end
    end
  end
endmodule
