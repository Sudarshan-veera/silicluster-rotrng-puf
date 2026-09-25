module silicluster_top(
  input clk, input rst_n,
  input sck, input mosi, input cs_n,
  input free_run, input [1:0] ro_sel, input [1:0] challenge,
  output miso, output trng_bit, output trng_valid,
  output busy, output health_fail, output [3:0] ro_div
);
  wire [3:0] ro_out, div_o;
  reg ro_en;

  ro_bank #(.USE_RO(0)) u_bank(.clk(clk), .rst_n(rst_n), .en(ro_en), .ro_out(ro_out));
  ro_div d0(rst_n, ro_out[0], div_o[0]);
  ro_div d1(rst_n, ro_out[1], div_o[1]);
  ro_div d2(rst_n, ro_out[2], div_o[2]);
  ro_div d3(rst_n, ro_out[3], div_o[3]);
  assign ro_div = div_o;

  reg start, ack, trng_run;
  wire [15:0] cnt; wire cnt_busy, cnt_done;
  wire [31:0] tword; wire tvalid;
  wire raw_bit, raw_valid;

  freq_counter u_fc(.clk(clk), .rst_n(rst_n), .start(start),
                    .sig(div_o[ro_sel]), .count(cnt),
                    .busy(cnt_busy), .done(cnt_done));

  trng u_trng(.clk(clk), .rst_n(rst_n), .run(trng_run | free_run),
              .ack(ack), .ro_raw(ro_out), .word(tword),
              .valid(tvalid), .bit_out(trng_bit),
              .raw_bit(raw_bit), .raw_valid(raw_valid));
  assign trng_valid = tvalid;
  assign busy = cnt_busy;

  wire hfail; wire [7:0] hcount; wire [5:0] kept_c, disc_c;
  reg hack;
  health_test u_ht(.clk(clk), .rst_n(rst_n & ~hack), .samp_en(raw_valid),
                    .bit_in(raw_bit), .fail(hfail), .fail_count(hcount),
                    .kept_cnt(kept_c), .discard_cnt(disc_c));
  assign health_fail = hfail;

  reg puf_sample; wire [7:0] puf_resp; wire puf_valid;
  puf_id u_puf(.clk(clk), .rst_n(rst_n), .sample(puf_sample),
               .challenge(challenge), .ro_div(div_o),
               .resp(puf_resp), .resp_valid(puf_valid));

  reg [2:0] sck_s, cs_s; reg [1:0] mosi_s;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin sck_s<=0; cs_s<=3'b111; mosi_s<=0; end
    else begin
      sck_s  <= {sck_s[1:0], sck};
      cs_s   <= {cs_s[1:0],  cs_n};
      mosi_s <= {mosi_s[0],  mosi};
    end
  end
  wire rise = sck_s[1] & ~sck_s[2];
  wire fall = ~sck_s[1] & sck_s[2];
  wire cs_active = ~cs_s[1];

  reg [4:0] bitcnt;
  reg [7:0] sh_in, sh_out, addr, wdata;
  reg wr_pulse, miso_r;
  wire [7:0] cur_byte = {sh_in[6:0], mosi_s[1]};
  assign miso = miso_r;

  reg [7:0] rd;
  always @* begin
    case (cur_byte[6:0])
      7'h00: rd = {4'b0, trng_run, hack, start, ro_en};
      7'h01: rd = {3'b0, hfail, tvalid, cnt_done, cnt_busy, puf_valid};
      7'h02: rd = cnt[15:8];
      7'h03: rd = cnt[7:0];
      7'h04: rd = tword[31:24];
      7'h05: rd = tword[23:16];
      7'h06: rd = tword[15:8];
      7'h07: rd = tword[7:0];
      7'h08: rd = hcount;
      7'h09: rd = {2'b0, kept_c};
      7'h0A: rd = {2'b0, disc_c};
      7'h0B: rd = puf_resp;
      7'h0F: rd = 8'hA6;
      default: rd = 8'h00;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bitcnt<=0; sh_in<=0; sh_out<=0; addr<=0; wdata<=0;
      wr_pulse<=0; miso_r<=0; ro_en<=0; trng_run<=0; start<=0; ack<=0;
      hack<=0; puf_sample<=0;
    end else begin
      wr_pulse <= 0; start <= 0; ack <= 0; hack <= 0; puf_sample <= 0;
      if (!cs_active) begin
        bitcnt <= 0; miso_r <= 0;
      end else begin
        if (rise) begin
          sh_in <= cur_byte;
          if (bitcnt != 5'd31) bitcnt <= bitcnt + 5'd1;
          if (bitcnt == 5'd7)  begin addr <= cur_byte; sh_out <= rd; end
          if (bitcnt == 5'd15) begin wdata <= cur_byte; wr_pulse <= addr[7]; end
        end
        if (fall && bitcnt >= 5'd8) begin
          miso_r <= sh_out[7];
          sh_out <= {sh_out[6:0], 1'b0};
        end
      end
      if (wr_pulse && addr[6:0] == 7'h00) begin
        ro_en    <= wdata[0];
        start    <= wdata[1];
        hack     <= wdata[2];
        trng_run <= wdata[3];
      end
      if (wr_pulse && addr[6:0] == 7'h0C) puf_sample <= wdata[0];
    end
  end
endmodule
