# AHB-Lite Verilog Implementation

A simplified **AMBA AHB-Lite bus system** implemented in Verilog HDL, featuring a single master, multiple memory-mapped slaves, address decoding, burst transfers, and a self-checking verification environment.

## Overview

The design implements the basic AHB-Lite transaction flow between a master and multiple slaves. The master generates read and write transactions, while the decoder selects the appropriate slave based on the address. A multiplexer routes the selected slave's response and read data back to the master.

Each slave contains an internal memory and handles the actual read/write operation.

## AHB-Lite Features Implemented

* **Single-master architecture** with a dedicated AHB master generating bus transactions.
* **Multiple slaves** with address-based slave selection using an address decoder.
* **AHB transfer types** using `HTRANS`, including `NONSEQ` for the first transfer and `SEQ` for subsequent burst transfers.
* **Burst transfers** with support for incrementing and wrapping burst address generation.
* **Transfer-size support** for byte, half-word, and word transfers using `HSIZE`.
* **Read and write transactions** controlled through `HWRITE`, with separate handling of read data and write data.
* **AHB handshake mechanism** using `HREADY` to control transfer completion and wait states.
* **Response handling** through `HRESP` for successful and erroneous transfers.
* **Address alignment checking** for half-word and word accesses.
* **Memory-mapped slave operation** using internal byte-addressable memory.
* **Default slave handling** for addresses that do not correspond to a defined slave region.

## Verification

A self-checking Verilog testbench is included to verify different transfer sizes, burst modes, read/write operations, and invalid or misaligned accesses.

The testbench automatically compares read-back data with expected values and checks whether `HRESP` is asserted when an invalid transfer is performed.

## Files

* `master_ahb.v` — AHB master and burst/address generation
* `slave_ahb.v` — AHB slave with internal memory
* `decoder_ahb.v` — Address decoding and slave selection
* `mux_ahb.v` — Response and read-data multiplexing
* `top_module_ahb.v` — Top-level AHB-Lite system
* `tb_ahb.v` — Self-checking testbench
