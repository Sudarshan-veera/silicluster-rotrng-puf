module freq_counter(
  input clk, input rst_n, input start, input sig,
  output reg [15:0] count, output reg busy, output reg done
);
  reg [2:0] s;
  reg [14:0] gate;
  wire rise = s[1] & ~s[2];
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s <= 0; gate <= 0; count <= 0; busy <= 0; done <= 0;
    end else begin
      s <= {s[1:0], sig};
      if (start && !busy) begin
        busy <= 1; done <= 0; gate <= 0; count <= 0;
      end else if (busy) begin
        if (rise) count <= count + 16'd1;
        gate <= gate + 15'd1;
        if (gate == 15'h7FFF) begin busy <= 0; done <= 1; end
      end
    end
  end
endmodule
