module spi_shift_register #(
  parameter DATA_WIDTH = 8
)(
  input wire clk, rst_n, load, shift_en,
  input wire [DATA_WIDTH-1:0] parallel_in,
  input wire serial_in,
  output wire serial_out, 
  output wire [DATA_WIDTH-1:0] parallel_out
);
  reg [DATA_WIDTH-1:0] shift_reg;
  assign serial_out = shift_reg[DATA_WIDTH-1];
  assign parallel_out = shift_reg;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      shift_reg <= '0;
    else if(load)
      shift_reg <= parallel_in;
    else if(shift_en)
      shift_reg <= {shift_reg[DATA_WIDTH-2:0], serial_in};
  end
endmodule
