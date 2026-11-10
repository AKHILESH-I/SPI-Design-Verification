module spi_top #(
    parameter DATA_WIDTH    = 8,
    parameter CLK_DIV_WIDTH = 8,
    parameter CPOL          = 1'b0,
    parameter CPHA          = 1'b0
)(
    input wire clk,
    input wire rst_n,

    input wire start,

    input wire [DATA_WIDTH-1:0] master_tx_data,
    input wire [DATA_WIDTH-1:0] slave_tx_data,

    input wire msb_first,
    input wire [CLK_DIV_WIDTH-1:0] clk_div,

    output wire [DATA_WIDTH-1:0] master_rx_data,
    output wire [DATA_WIDTH-1:0] slave_rx_data,

    output wire slave_rx_valid,

    output wire busy,
    output wire done
    );

    wire mosi;
    wire miso;
    wire sclk;
    wire ss_n;

    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) u_spi_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(master_tx_data),
        .miso(miso),
        .msb_first(msb_first),
        .clk_div(clk_div),
        .mosi(mosi),
        .sclk(sclk),
        .ss_n(ss_n),
        .rx_data(master_rx_data),
        .busy(busy),
        .done(done)
    );
    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) u_spi_slave (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .rx_valid(slave_rx_valid),
        .sclk(sclk),
        .ss_n(ss_n),
        .mosi(mosi),
        .miso(miso),
        .msb_first(msb_first)
    );
endmodule
