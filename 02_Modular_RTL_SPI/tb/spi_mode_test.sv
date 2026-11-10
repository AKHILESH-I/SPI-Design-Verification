`default_nettype none
`timescale 1ns/1ps

module spi_mode_test #(
    parameter DATA_WIDTH    = 8,
    parameter CLK_DIV_WIDTH = 8,
    parameter CPOL          = 1'b0,
    parameter CPHA          = 1'b0
)(
    input wire clk,
    input wire rst_n,
    output reg finished,
    output reg [1:0] pass_count,
    output reg [1:0] fail_count
);
    // Master inputs
    reg start;
    reg [DATA_WIDTH-1:0] master_tx_data;
    // Slave inputs
    reg [DATA_WIDTH-1:0] slave_tx_data;
    // Configuration
    reg msb_first;
    reg [CLK_DIV_WIDTH-1:0] clk_div;
    // DUT outputs
    wire [DATA_WIDTH-1:0] master_rx_data;
    wire [DATA_WIDTH-1:0] slave_rx_data;
    wire slave_rx_valid;
    wire busy;
    wire done;
    // RX valid monitor
    reg [1:0] rx_valid_seen;
    spi_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .master_tx_data(master_tx_data),
        .slave_tx_data(slave_tx_data),
        .msb_first(msb_first),
        .clk_div(clk_div),
        .master_rx_data(master_rx_data),
        .slave_rx_data(slave_rx_data),
        .slave_rx_valid(slave_rx_valid),
        .busy(busy),
        .done(done)
    );
    //Count RX valid pulses
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_valid_seen <= '0;
        else if (slave_rx_valid)
            rx_valid_seen <= rx_valid_seen + 1'b1;
    end
    // Initialize testbench signals
    initial begin
        start          = 1'b0;
        master_tx_data = '0;
        slave_tx_data  = '0;
        msb_first      = 1'b1;
        clk_div        = 8'd4;
    end
    task automatic run_transaction(
        input logic bit_order,
        input logic [DATA_WIDTH-1:0] expected_master_rx,
        input logic [DATA_WIDTH-1:0] expected_slave_rx
    );
        reg [1:0] valid_before;
        reg transaction_pass;
        begin
            transaction_pass = 1'b1;
            // Wait until master is idle
            wait(busy == 1'b0 && done == 1'b0);
            // Capture RX valid count before transaction
            valid_before = rx_valid_seen;
            // Configure transaction
            @(negedge clk);
            msb_first      = bit_order;
            master_tx_data = DATA_WIDTH'(8'h96);
            slave_tx_data  = DATA_WIDTH'(8'h3A);
            clk_div        = CLK_DIV_WIDTH'(4);
            // Generate one-clock start pulse
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            // Wait for transaction completion
            wait(done == 1'b1);
            #1;
            // Check master received data
            if (master_rx_data !== expected_master_rx) begin
                $error("MASTER RX FAILED: Expected %h, Got %h",
                       expected_master_rx, master_rx_data);
                transaction_pass = 1'b0;
            end
            // Check slave received data
            if (slave_rx_data !== expected_slave_rx) begin
                $error("SLAVE RX FAILED: Expected %h, Got %h",
                       expected_slave_rx, slave_rx_data);
                transaction_pass = 1'b0;
            end
            // Check exactly one RX valid pulse
            if (rx_valid_seen !== (valid_before + 2'd1)) begin
                $error("RX_VALID FAILED: Expected one new pulse");
                transaction_pass = 1'b0;
            end
            // Update transaction statistics
            if (transaction_pass) begin
                pass_count = pass_count + 1'b1;
                $display("SPI MODE %0d | %s | PASS", (CPOL * 2 + CPHA), bit_order ? "MSB-FIRST" : "LSB-FIRST");
            end
            else begin
                fail_count = fail_count + 1'b1;
                $display("SPI MODE %0d | %s | FAIL", (CPOL * 2 + CPHA), bit_order ? "MSB-FIRST" : "LSB-FIRST");
            end
        end
    endtask
    initial begin
        finished       = 1'b0;
        pass_count     = '0;
        fail_count     = '0;
        // Wait for reset release
        wait(rst_n == 1'b1);
        @(negedge clk);
        // Run MSB-first transaction
        run_transaction(
            1'b1,
            DATA_WIDTH'(8'h3A),
            DATA_WIDTH'(8'h96)
        );
        // Run LSB-first transaction
        run_transaction(
            1'b0,
            DATA_WIDTH'(8'h3A),
            DATA_WIDTH'(8'h96)
        );
        // Indicate completion
        finished = 1'b1;
    end
endmodule

`default_nettype wire
