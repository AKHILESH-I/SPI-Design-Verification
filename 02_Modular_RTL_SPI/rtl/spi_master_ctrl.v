module spi_master_ctrl #
(
  parameter DATA_WIDTH = 8,
  parameter CPOL       = 1'b0,
  parameter CPHA       = 1'b0
)
(
  input wire clk,
  input wire rst_n,
  input wire start,
  // SPI clock timing events
  input wire spi_clk,
  input wire spi_tick,
  input wire spi_rise,
  input wire spi_fall,
  // Number of bits remaining
  input wire [$clog2(DATA_WIDTH)-1:0] bit_count,
  // Control signals to datapath
  output reg load,
  output reg tx_shift_en,
  output reg rx_sample_en,
  output reg count_en,
  // Master status
  output reg busy,
  output reg done,

  // SPI control
  output reg ss_n,
  output reg enable_clk
);
  localparam [3:0]
    IDLE        = 4'b0000,
    ASSERT_SS   = 4'b0001,
    LOAD        = 4'b0010,
    SHIFT       = 4'b0011,
    LAST_SHIFT  = 4'b0100,
    FINISH      = 4'b0101,
    WAIT_IDLE   = 4'b0110,
    DEASSERT_SS = 4'b0111,
    DONE        = 4'b1000;

  reg [2:0] idle_wait_count;
  reg [3:0] current_state;
  reg [3:0] next_state;
  wire leading_edge;
  wire trailing_edge;

  assign leading_edge =
      (CPOL == 1'b0) ? spi_rise : spi_fall;

  assign trailing_edge =
      (CPOL == 1'b0) ? spi_fall : spi_rise;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end
  // Hold chip select active while the slave processes
  // the final synchronized SCLK edge.
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          idle_wait_count <= 3'd0;
      end
      else if (current_state != WAIT_IDLE) begin
          idle_wait_count <= 3'd0;
      end
      else if (idle_wait_count < 3'd4) begin
          idle_wait_count <= idle_wait_count + 1'b1;
      end
  end
  always @(*) begin
    // Default: stay in current state
    next_state = current_state;
    case(current_state)
      IDLE: begin
        if(start)
          next_state = ASSERT_SS;
      end
      ASSERT_SS: begin
        next_state = LOAD;
      end
      LOAD: begin
        next_state = SHIFT;
      end
      SHIFT: begin

        if(spi_tick) begin
          if(CPHA == 1'b0) begin

            if(leading_edge) begin

              if(bit_count == '0)
                next_state = LAST_SHIFT;
            end
          end
          else begin
            if(trailing_edge) begin
              if(bit_count == '0)
                next_state = FINISH;
            end
          end
        end
      end
      LAST_SHIFT: begin
        if(spi_tick && trailing_edge)
          next_state = FINISH;
      end
      FINISH: begin
        next_state = WAIT_IDLE;
      end
      WAIT_IDLE: begin
        if((spi_clk == CPOL) && (idle_wait_count == 3'd4))
          next_state = DEASSERT_SS;
      end
      DEASSERT_SS: begin
        next_state = DONE;
      end
      DONE: begin
        next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end
  
  always @(*) begin
    // Default assignments
    load         = 1'b0;
    tx_shift_en  = 1'b0;
    rx_sample_en = 1'b0;
    count_en     = 1'b0;
    busy         = 1'b0;
    done         = 1'b0;
    ss_n         = 1'b1;
    enable_clk   = 1'b0;

    case (current_state)

      IDLE: begin
          busy       = 1'b0;
          done       = 1'b0;
          ss_n       = 1'b1;
          enable_clk = 1'b0;
      end

      ASSERT_SS: begin
          busy       = 1'b1;
          ss_n       = 1'b0;
          enable_clk = 1'b0;
      end

      LOAD: begin
          busy       = 1'b1;
          ss_n       = 1'b0;
          enable_clk = 1'b0;
          load       = 1'b1;
      end

      SHIFT: begin
          busy       = 1'b1;
          ss_n       = 1'b0;
          enable_clk = 1'b1;
           if (spi_tick) begin
              if (CPHA == 1'b0) begin

                  if (leading_edge) begin
                      rx_sample_en = 1'b1;
                      count_en     = 1'b1;
                  end
                  else if (trailing_edge) begin
                      tx_shift_en = 1'b1;
                  end
               end
               else begin

                  if (leading_edge) begin
                      // Preserve the first transmitted bit.
                      // Shift subsequent bits, including the
                      // transition to the final bit.
                      if (bit_count != DATA_WIDTH - 1)
                          tx_shift_en = 1'b1;
                  end
                  else if (trailing_edge) begin
                      rx_sample_en = 1'b1;
                      count_en     = 1'b1;
                  end

                end
            end
        end

        LAST_SHIFT: begin
            busy       = 1'b1;
            ss_n       = 1'b0;
            enable_clk = 1'b1;

          if (spi_tick && trailing_edge)
              tx_shift_en = 1'b1;
      end

      FINISH: begin
          busy       = 1'b1;
          ss_n       = 1'b0;
          enable_clk = 1'b0;
      end

      WAIT_IDLE: begin
          busy       = 1'b1;
          ss_n       = 1'b0;
          enable_clk = 1'b0;
      end

      DEASSERT_SS: begin
          busy       = 1'b1;
          ss_n       = 1'b1;
          enable_clk = 1'b0;
      end

      DONE: begin
          busy       = 1'b0;
          done       = 1'b1;
          ss_n       = 1'b1;
          enable_clk = 1'b0;
      end

      default: begin
          load         = 1'b0;
          tx_shift_en  = 1'b0;
          rx_sample_en = 1'b0;
          count_en     = 1'b0;
          busy         = 1'b0;
          done         = 1'b0;
          ss_n         = 1'b1;
          enable_clk   = 1'b0;
      end

    endcase
  end
endmodule
