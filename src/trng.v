module trng(
  input clk, input rst_n, input run, input ack,
  input [3:0] ro_raw,
  output reg [31:0] word, output reg valid, output reg bit_out,
  output raw_bit, output raw_valid
);
  reg s1, s2, prev, have_prev;
  reg [3:0] tcnt;
  reg [4:0] nbits;
  wire tick = &tcnt;
  reg raw_v;
  assign raw_bit = s2;
  assign raw_valid = raw_v;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s1<=0; s2<=0; prev<=0; have_prev<=0; tcnt<=0; nbits<=0;
      word<=0; valid<=0; bit_out<=0; raw_v<=0;
    end else begin
      s1 <= ^ro_raw; s2 <= s1;
      tcnt <= tcnt + 4'd1;
      raw_v <= 0;
      if (ack) begin
        valid <= 0; nbits <= 0; have_prev <= 0;
      end else if (tick && run) begin
        raw_v <= 1;
        if (!valid) begin
          if (have_prev) begin
            have_prev <= 0;
            if (prev != s2) begin
              word <= {word[30:0], prev};
              bit_out <= prev;
              nbits <= nbits + 5'd1;
              if (nbits == 5'd31) valid <= 1;
            end
          end else begin
            prev <= s2; have_prev <= 1;
          end
        end
      end
    end
  end
endmodule
