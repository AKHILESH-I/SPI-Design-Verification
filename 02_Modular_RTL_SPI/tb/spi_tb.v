`default_nettype none
`timescale 1ns/1ps

module spi_tb;
    parameter DATA_WIDTH    = 8;
    parameter CLK_DIV_WIDTH = 8;

    // Common clock and reset
    reg clk;
    reg rst_n;
    integer total_pass;
    integer total_fail;
    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    // Reset generation
    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
    end
    // Mode 0 status
    wire mode0_finished;
    wire [1:0] mode0_pass;
    wire [1:0] mode0_fail;
    // Mode 1 status
    wire mode1_finished;
    wire [1:0] mode1_pass;
    wire [1:0] mode1_fail;
    // Mode 2 status
    wire mode2_finished;
    wire [1:0] mode2_pass;
    wire [1:0] mode2_fail;
    // Mode 3 status
    wire mode3_finished;
    wire [1:0] mode3_pass;
    wire [1:0] mode3_fail;
    // SPI Mode 0: CPOL=0, CPHA=0
    spi_mode_test #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
        .CPOL(1'b0),
        .CPHA(1'b0)
    ) u_mode0 (
        .clk(clk),
        .rst_n(rst_n),
        .finished(mode0_finished),
        .pass_count(mode0_pass),
        .fail_count(mode0_fail)
    );
    // SPI Mode 1: CPOL=0, CPHA=1
    spi_mode_test #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
        .CPOL(1'b0),
        .CPHA(1'b1)
    ) u_mode1 (
        .clk(clk),
        .rst_n(rst_n),
        .finished(mode1_finished),
        .pass_count(mode1_pass),
        .fail_count(mode1_fail)
    );
    // SPI Mode 2: CPOL=1, CPHA=0
    spi_mode_test #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
        .CPOL(1'b1),
        .CPHA(1'b0)
    ) u_mode2 (
        .clk(clk),
        .rst_n(rst_n),
        .finished(mode2_finished),
        .pass_count(mode2_pass),
        .fail_count(mode2_fail)
    );
    // SPI Mode 3: CPOL=1, CPHA=1
    spi_mode_test #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH),
        .CPOL(1'b1),
        .CPHA(1'b1)
    ) u_mode3 (
        .clk(clk),
        .rst_n(rst_n),
        .finished(mode3_finished),
        .pass_count(mode3_pass),
        .fail_count(mode3_fail)
    );
    // Global regression timeout
    initial begin
        #200000;
        $fatal(1, "SPI REGRESSION TIMEOUT");
    end

    // Regression summary
    initial begin
        // Wait until all four SPI modes finish
        wait (
            mode0_finished &&
            mode1_finished &&
            mode2_finished &&
            mode3_finished
        );
        // Allow signal updates to settle
        #1;
        // Calculate total pass and fail counts
        total_pass = integer'(mode0_pass) +
                     integer'(mode1_pass) +
                     integer'(mode2_pass) +
                     integer'(mode3_pass);
        total_fail = integer'(mode0_fail) +
                     integer'(mode1_fail) +
                     integer'(mode2_fail) +
                     integer'(mode3_fail);
        // Display regression summary
        $display("       SPI VERIFICATION REGRESSION");
        $display("MODE 0 : PASS=%0d FAIL=%0d",
                 mode0_pass, mode0_fail);
        $display("MODE 1 : PASS=%0d FAIL=%0d",
                 mode1_pass, mode1_fail);
        $display("MODE 2 : PASS=%0d FAIL=%0d",
                 mode2_pass, mode2_fail);
        $display("MODE 3 : PASS=%0d FAIL=%0d",
                 mode3_pass, mode3_fail);
        $display("TOTAL TESTS : %0d", total_pass + total_fail);
        $display("PASSED      : %0d", total_pass);
        $display("FAILED      : %0d", total_fail);
        if (total_pass == 8 && total_fail == 0) begin
            $display("SPI REGRESSION PASSED");
            $finish;
        end
        else begin
            $fatal(1, "SPI REGRESSION FAILED");
        end
    end
endmodule

`default_nettype wire

