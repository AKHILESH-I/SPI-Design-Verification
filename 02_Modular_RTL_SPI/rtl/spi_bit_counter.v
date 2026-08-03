module spi_bit_counter #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           load,
    input  wire                           count_en,
    output wire                           bit_done,
    output wire [$clog2(DATA_WIDTH)-1:0]  bit_count
);
    // Counter width required to represent DATA_WIDTH bits
    localparam COUNT_WIDTH = $clog2(DATA_WIDTH);
    // Down-counter tracking remaining bits in the current transfer
    reg [COUNT_WIDTH-1:0] counter;
    // Outputs
    assign bit_done  = (counter == '0);
    assign bit_count = counter;
    // Down Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= '0;
        // Load remaining bit count
        else if (load)
            counter <= DATA_WIDTH - 1;
        // Decrement after each successful bit transfer
        else if (count_en && (counter != '0))
            counter <= counter - 1'b1;
    end
endmodule
