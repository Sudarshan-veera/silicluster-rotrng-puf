`ifdef SIM
  `define DLY(x) #(x)
`else
  `define DLY(x)
`endif

module ring_osc #(parameter N = 8, parameter D = 1)(
  input  en,
  output out
);
  (* keep *) wire [N:0] c;
  assign `DLY(D) c[0] = ~(c[N] & en);
  genvar i;
  generate
    for (i = 1; i <= N; i = i + 1) begin : g
      assign `DLY(D) c[i] = ~c[i-1];
    end
  endgenerate
  assign out = c[N];
endmodule

module ro_div(input rst_n, input sig, output msb);
  reg [6:0] cnt;
  always @(posedge sig or negedge rst_n)
    if (!rst_n) cnt <= 7'd0; else cnt <= cnt + 7'd1;
  assign msb = cnt[6];
endmodule
