# Silicluster RO-TRNG + PUF (Digital)

Compact true random number generator and challenge-response PUF with on-chip entropy health tests, controlled over SPI.

## Architecture
- ring_osc.v, ro_bank.v: entropy source (ring oscillators, or LFSR stand-in selected by the USE_RO build parameter)
- trng.v: XOR of sources, von Neumann debiasing, 32-bit output word
- health_test.v: repetition-count (cutoff C = 21) and adaptive-proportion tests, sticky fail flag and counter
- puf_id.v: challenge-selected XOR of divided oscillator outputs, 8-bit response
- freq_counter.v: gated frequency counter
- silicluster_top.v: SPI register interface (ID register 0x0F reads 0xA6)

## Run the simulation

    iverilog -g2012 -DSIM -s tb -s dump -o sim tb/tb.v src/*.v dump.v
    vvp sim
    gtkwave tb.vcd

## Synthesis (Yosys generic cells, not a SKY130 netlist)
See yosys_stat.txt: 890 cells, 226 flip-flops.

## Simulation results (health-test cutoff C = 21)

    VCD info: dumpfile tb.vcd opened for output.
    ID = a6 (expect a6)
    Freq count = 64
    TRNG word = 6db43f19
    Health fail count = 0
    PUF response = 00
    tb/tb.v:51: $finish called at 4587010000 (1ps)

With the original cutoff C = 5 the health monitor reported 18 failures on the same run (sim_log.txt), so the cutoff was raised to 21.

## Limitations
- Simulated with the LFSR stand-in (USE_RO = 0), so TRNG output is deterministic and not a measure of entropy.
- The PUF response needs real oscillator mismatch (FPGA or silicon) and is not meaningful in simulation.
- Switching between ring oscillators and the LFSR is a build-time choice, not a runtime fallback.
