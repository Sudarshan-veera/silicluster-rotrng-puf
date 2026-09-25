module ro_bank #(parameter USE_RO = 0)(
  input clk, input rst_n, input en, output [3:0] ro_out
);
  generate
    if (USE_RO) begin : g_ro
      ring_osc #(.N(8), .D(1)) r0(.en(en), .out(ro_out[0]));
      ring_osc #(.N(8), .D(1)) r1(.en(en), .out(ro_out[1]));
      ring_osc #(.N(8), .D(1)) r2(.en(en), .out(ro_out[2]));
      ring_osc #(.N(8), .D(1)) r3(.en(en), .out(ro_out[3]));
    end else begin : g_lfsr
      reg [15:0] l;
      always @(posedge clk or negedge rst_n)
        if (!rst_n) l <= 16'hACE1;
        else if (en) l <= {l[14:0], l[15]^l[13]^l[12]^l[10]};
      assign ro_out = {l[12], l[9], l[6], l[3]};
    end
  endgenerate
endmodule
