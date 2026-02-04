#!/usr/bin/env bash
set -euo pipefail

# Simplified wrapper for Aufgabe 3 (dataflow_min).
./run_ghdl.sh my_rail_crossing_tb_dataflow_min my_rail_crossing_tb_dataflow_min.vhdl 100ms

