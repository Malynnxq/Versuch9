#!/usr/bin/env bash
set -euo pipefail

TOP="my_rail_crossing_tb_behavior"

if ! command -v ghdl >/dev/null 2>&1; then
  echo "ghdl not found in PATH. Please install GHDL to run the simulation." >&2
  exit 127
fi

rm -f work-obj08.cf

ghdl -a --std=08 my_rail_crossing.vhdl
ghdl -a --std=08 my_rail_crossing_tb_behavior.vhdl
ghdl -e --std=08 "${TOP}"
ghdl -r --std=08 "${TOP}" --stop-time=100ms
