module dump;
  initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
endmodule
