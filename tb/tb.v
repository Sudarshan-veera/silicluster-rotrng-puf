`timescale 1ns/1ps
module tb;
  reg clk=0, rst_n=0, sck=0, mosi=0, cs_n=1, free_run=0;
  reg [1:0] ro_sel=0, challenge=0;
  wire miso, trng_bit, trng_valid, busy, health_fail;
  wire [3:0] ro_div;
  silicluster_top dut(clk,rst_n,sck,mosi,cs_n,free_run,ro_sel,challenge,
    miso,trng_bit,trng_valid,busy,health_fail,ro_div);
  always #50 clk = ~clk;

  task spi_xfer(input [7:0] a, input [7:0] d, output [7:0] r);
    integer i; reg [15:0] tx;
    begin
      tx = {a,d}; r = 0; cs_n = 0; #1000;
      for (i = 15; i >= 0; i = i-1) begin
        mosi = tx[i]; #1000 sck = 1;
        if (i < 8) r[i] = miso;
        #1000 sck = 0;
      end
      #1000 cs_n = 1; #1000;
    end
  endtask

  reg [7:0] r; reg [15:0] cnt; reg [31:0] w; integer k, j;
  initial begin
    #1000 rst_n = 1; #1000;
    spi_xfer(8'h0F, 8'h00, r); $display("ID = %h (expect a6)", r);

    spi_xfer(8'h80, 8'h03, r);
    k=0; r=0;
    while (!r[2] && k<400) begin spi_xfer(8'h01, 8'h00, r); k=k+1; end
    spi_xfer(8'h02,8'h00,r); cnt[15:8]=r;
    spi_xfer(8'h03,8'h00,r); cnt[7:0]=r;
    $display("Freq count = %0d", cnt);

    spi_xfer(8'h80, 8'h09, r);
    k=0; r=0;
    while (!r[3] && k<2000) begin spi_xfer(8'h01,8'h00,r); k=k+1; end
    if (r[3]) begin
      for (j=4;j<8;j=j+1) begin spi_xfer(j,8'h00,r); w={w[23:0],r}; end
      $display("TRNG word = %h", w);
    end else $display("TRNG timeout");

    spi_xfer(8'h08,8'h00,r); $display("Health fail count = %0d", r);
    spi_xfer(8'h09,8'h00,r); $display("VN kept = %0d", r);
    spi_xfer(8'h0A,8'h00,r); $display("VN discarded = %0d", r);

    challenge = 2'd1;
    spi_xfer(8'h8C, 8'h01, r);
    for (k=0;k<10;k=k+1) spi_xfer(8'h01,8'h00,r);
    spi_xfer(8'h0B,8'h00,r); $display("PUF response = %h", r);

    $finish;
  end
endmodule
