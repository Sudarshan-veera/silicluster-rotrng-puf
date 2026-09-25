module health_test #(
  parameter C = 5,
  parameter W = 64,
  parameter APT_MAX = 46
)(
  input clk, input rst_n, input samp_en, input bit_in,
  output reg fail, output reg [7:0] fail_count,
  output reg [5:0] kept_cnt, output reg [5:0] discard_cnt
);
  reg prev_bit; reg have_prev;
  reg [7:0] rep_cnt;
  wire rct_fail = (rep_cnt >= C);

  reg [6:0] win_cnt;
  reg [6:0] ones_cnt;
  wire apt_fail = (win_cnt == W[6:0]) && (ones_cnt > APT_MAX[6:0]);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_bit<=0; have_prev<=0; rep_cnt<=0;
      win_cnt<=0; ones_cnt<=0;
      fail<=0; fail_count<=0; kept_cnt<=0; discard_cnt<=0;
    end else if (samp_en) begin
      if (!have_prev) begin
        have_prev <= 1; prev_bit <= bit_in; rep_cnt <= 1;
      end else if (bit_in == prev_bit) begin
        rep_cnt <= rep_cnt + 8'd1;
      end else begin
        prev_bit <= bit_in; rep_cnt <= 1;
      end

      if (win_cnt == W[6:0]) begin
        win_cnt <= 1; ones_cnt <= {6'b0, bit_in};
      end else begin
        win_cnt <= win_cnt + 7'd1;
        if (bit_in) ones_cnt <= ones_cnt + 7'd1;
      end

      if (rct_fail || apt_fail) begin
        fail <= 1;
        if (fail_count != 8'hFF) fail_count <= fail_count + 8'd1;
      end
    end
  end
endmodule
