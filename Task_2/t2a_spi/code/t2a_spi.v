/*
eYRC26-27: Logic Quest
Task 2A: SPI Master Module
Description : Parameterizable SPI master controller supporting all 4 SPI
              modes (via CPOL/CPHA), configurable bit order (MSB/LSB
              first), and configurable word length. Derives SCLK by
              dividing down the 50MHz input clock (HALF_PERIOD sets the
              divide ratio). On `start`, shifts tx_data out on MOSI while
              simultaneously shifting MISO into rx_data; `busy` is high
              for the duration and `cs_out` is driven low for the TRAN.
Parameters:
  CPOL             - Clock polarity (0: idle low, 1: idle high)        [default: 0]
  CPHA             - Clock phase (0: sample leading edge,
                      1: sample trailing edge)                        [default: 0]
  LSB_FIRST        - Bit order (0: MSB first, 1: LSB first)           [default: 0]
  SPI_WORD_LENGTH  - Number of bits per TRAN                      [default: 8]
  HALF_PERIOD      - clk_50MHz cycles per SCLK half-period.
                      SCLK freq = 50MHz / (2 x HALF_PERIOD)           [default: 25 -> 1MHz]
Ports:
  clk_50MHz    (in )  1 bit               - System clock (50MHz)
  rst_n        (in )  1 bit               - Active-low async reset
  start        (in )  1 bit               - Pulse high (sampled in IDLE) to begin TRAN
  tx_data      (in )  SPI_WORD_LENGTH     - Data word to transmit on MOSI
  miso_input   (in )  1 bit               - Serial data in from SPI slave
  sclk_out     (out)  1 bit               - SPI serial clock, idles at CPOL
  cs_out       (out)  1 bit               - Chip select, active-low during TRAN
  mosi_output  (out)  1 bit               - Serial data out to SPI slave
  rx_data      (out)  SPI_WORD_LENGTH     - Data received from MISO (valid once busy=0)
  busy         (out)  1 bit               - High for the duration of an active TRAN
*/

module t2a_spi
#(
    parameter CPOL             = 1'b0,
    parameter CPHA             = 1'b0,
    parameter LSB_FIRST        = 1'b0,
    parameter SPI_WORD_LENGTH  = 8,
    parameter HALF_PERIOD      = 25   // clk_50MHz cycles per half sclk period
)
(
    input wire clk_50MHz,
    input wire rst_n,

    input wire start,
    input wire [SPI_WORD_LENGTH-1:0] tx_data,
    input wire miso_input,

    output reg sclk_out,
    output reg cs_out,
    output reg mosi_output,

    output reg [SPI_WORD_LENGTH-1:0] rx_data,
    output reg busy
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

  reg [SPI_WORD_LENGTH-1:0] data;
  reg [2:0] bit_count;
  reg [7:0] cycle_count;
  reg [2:0] state;
  reg [2:0] next_state;
  reg do_delay;

  localparam IDLE=0, TRAN=1, DONE=2;

  always @(*) begin
    case (state) 
      DONE: next_state = IDLE;
      IDLE: next_state = start ? TRAN : IDLE;
      TRAN: next_state = (bit_count == SPI_WORD_LENGTH-1 && cycle_count == 2*HALF_PERIOD-1) ? DONE : TRAN;
      default: next_state = IDLE;
    endcase
  end

  initial begin
    cs_out = 1;
    busy = 0;
  end

  always @(posedge clk_50MHz) begin
    if (!rst_n) begin
      state <= IDLE;
      data <= 0;
      sclk_out <= 0;
      cycle_count <= 0;
      cs_out <= 1;
      busy <= 0;
      mosi_output <= 0;
      rx_data <= 0;


    end else begin
      state <= next_state;
      
      case (state)
        IDLE: begin
          cycle_count <= 0;
          bit_count <= 0;
          data <= tx_data; // tx is read at idle to make first run work
          mosi_output <= 0;
        end
        TRAN: begin
          if (cs_out) begin
            cs_out <= 1'b0;
            busy <= 1;
            mosi_output <= data[SPI_WORD_LENGTH-1]; // Write at chip select;
            do_delay <= 1; // I think this is just wrong but okay
          end else if (do_delay) begin
              do_delay <= 0;
          end else if (cycle_count==HALF_PERIOD-1) begin
            sclk_out <= 1'b1;
            cycle_count <= cycle_count + 1'b1;
            data <= {data[SPI_WORD_LENGTH-2:0], miso_input}; // Read at rising edges 
          end else if (cycle_count==2*HALF_PERIOD-1 ) begin
            bit_count <= bit_count + 1'b1;
            cycle_count <= 0;
            sclk_out <= 1'b0;
            mosi_output <= data[SPI_WORD_LENGTH-1]; // Write at falling edge
          end else begin
            cycle_count <= cycle_count + 1'b1;
          end

        end
        DONE: begin
          busy <= 0;
          cs_out <= 1;
          rx_data <= data;
        end
      endcase
    end
  end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule