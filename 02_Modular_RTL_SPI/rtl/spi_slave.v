module spi_slave #(
    parameter DATA_WIDTH = 8,
    parameter CPOL       = 1'b0,
    parameter CPHA       = 1'b0
)(
    input  wire clk,
    input  wire rst_n,

    // Parallel data interface
    input  wire [DATA_WIDTH-1:0] tx_data,
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire rx_valid,

    // SPI interface
    input  wire sclk,
    input  wire ss_n,
    input  wire mosi,
    output wire miso,

    input  wire msb_first
);

    // Internal registers
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [DATA_WIDTH-1:0] rx_shift_reg;

    // Supports counts from 0 through DATA_WIDTH
    localparam COUNT_WIDTH = $clog2(DATA_WIDTH + 1);

    reg [COUNT_WIDTH-1:0] bit_count;

    reg rx_valid_reg;

    // Input synchronizers
    reg sclk_sync_1;
    reg sclk_sync_2;
    reg sclk_sync_2_d;

    reg ss_sync_1;
    reg ss_sync_2;
    reg ss_sync_2_d;

    reg mosi_sync_1;
    reg mosi_sync_2;

    // Edge detection
    wire sclk_rise;
    wire sclk_fall;

    wire sample_edge;
    wire shift_edge;

    wire select_event;

    assign sclk_rise = sclk_sync_2 && !sclk_sync_2_d;
    assign sclk_fall = !sclk_sync_2 && sclk_sync_2_d;

    assign select_event = ss_sync_2_d && !ss_sync_2;

    // Leading and trailing edges depend on CPOL.
    // Sampling and shifting edges depend on CPHA.
    assign sample_edge =
        (CPHA == 1'b0) ?
        ((CPOL == 1'b0) ? sclk_rise : sclk_fall) :
        ((CPOL == 1'b0) ? sclk_fall : sclk_rise);

    assign shift_edge =
        (CPHA == 1'b0) ?
        ((CPOL == 1'b0) ? sclk_fall : sclk_rise) :
        ((CPOL == 1'b0) ? sclk_rise : sclk_fall);

    // SCLK synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync_1   <= CPOL;
            sclk_sync_2   <= CPOL;
            sclk_sync_2_d <= CPOL;
        end
        else begin
            sclk_sync_1   <= sclk;
            sclk_sync_2   <= sclk_sync_1;
            sclk_sync_2_d <= sclk_sync_2;
        end
    end

    // SS synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ss_sync_1   <= 1'b1;
            ss_sync_2   <= 1'b1;
            ss_sync_2_d <= 1'b1;
        end
        else begin
            ss_sync_1   <= ss_n;
            ss_sync_2   <= ss_sync_1;
            ss_sync_2_d <= ss_sync_2;
        end
    end

    // MOSI synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mosi_sync_1 <= 1'b0;
            mosi_sync_2 <= 1'b0;
        end
        else begin
            mosi_sync_1 <= mosi;
            mosi_sync_2 <= mosi_sync_1;
        end
    end

    // External outputs
    assign rx_data  = rx_shift_reg;
    assign rx_valid = rx_valid_reg;

    // Release MISO immediately when the physical
    // chip-select signal is inactive.
    assign miso = (!ss_n) ?
                  (msb_first ?
                   tx_shift_reg[DATA_WIDTH-1] :
                   tx_shift_reg[0]) : 1'bz;

    // TX shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= '0;
        end
        else if (ss_sync_2) begin
            tx_shift_reg <= '0;
        end
        else if (select_event) begin
            // Load transmit data at transaction start.
            tx_shift_reg <= tx_data;
        end
        else if (shift_edge) begin

            if (CPHA == 1'b0) begin

                // CPHA=0:
                // Shift after each sampled bit.
                // Do not shift beyond the final bit.
                if (bit_count > 0 && bit_count < DATA_WIDTH) begin
                    if (msb_first)
                        tx_shift_reg <= {
                            tx_shift_reg[DATA_WIDTH-2:0], 1'b0
                        };
                    else
                        tx_shift_reg <= {
                            1'b0, tx_shift_reg[DATA_WIDTH-1:1]
                        };
                end
            end
            else begin

                // CPHA=1:
                // First bit is already available before
                // the first sampling edge.
                // Shift subsequent bits on shift edges.
                if (bit_count > 0 && bit_count < DATA_WIDTH) begin
                    if (msb_first)
                        tx_shift_reg <= {
                            tx_shift_reg[DATA_WIDTH-2:0], 1'b0
                        };
                    else
                        tx_shift_reg <= {
                            1'b0, tx_shift_reg[DATA_WIDTH-1:1]
                        };
                end
            end
        end
    end

    // RX shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg <= '0;
        end
        else if (select_event) begin
            // Clear receive register at transaction start.
            rx_shift_reg <= '0;
        end
        else if (!ss_sync_2 && sample_edge &&
                 (bit_count < DATA_WIDTH)) begin
            if (msb_first)
                rx_shift_reg <= {
                    rx_shift_reg[DATA_WIDTH-2:0],
                    mosi_sync_2
                };
            else
                rx_shift_reg <= {
                    mosi_sync_2,
                    rx_shift_reg[DATA_WIDTH-1:1]
                };
        end
    end

    // Bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= '0;
        end
        else if (ss_sync_2) begin
            bit_count <= '0;
        end
        else if (sample_edge && (bit_count < DATA_WIDTH)) begin
            bit_count <= bit_count + 1'b1;
        end
    end

    // RX valid generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_reg <= 1'b0;
        end
        else if (ss_sync_2) begin
            rx_valid_reg <= 1'b0;
        end
        else begin
            rx_valid_reg <= 1'b0;
            // Assert valid on the final received bit.
            if (sample_edge && (bit_count == DATA_WIDTH - 1))
                rx_valid_reg <= 1'b1;
        end
    end
endmodule
