module puf_id(
  input clk, input rst_n, input sample, input [1:0] challenge,
  input [3:0] ro_div,
  output reg [7:0] resp, output reg resp_valid
);
  reg [7:0] shreg;
  reg [2:0] bitcnt;
  reg samp_d;
  wire samp_rise = sample & ~samp_d;

  wire bit_now = (challenge == 2'd0) ? (ro_div[0] ^ ro_div[1]) :
                 (challenge == 2'd1) ? (ro_div[1] ^ ro_div[2]) :
                 (challenge == 2'd2) ? (ro_div[2] ^ ro_div[3]) :
                                       (ro_div[3] ^ ro_div[0]);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shreg <= 0; bitcnt <= 0; resp <= 0; resp_valid <= 0; samp_d <= 0;
    end else begin
      samp_d <= sample;
      if (samp_rise) begin
        shreg <= {shreg[6:0], bit_now};
        if (bitcnt == 3'd7) begin
          resp <= {shreg[6:0], bit_now};
          resp_valid <= 1;
          bitcnt <= 0;
        end else begin
          bitcnt <= bitcnt + 3'd1;
          resp_valid <= 0;
        end
      end
    end
  end
endmodule
