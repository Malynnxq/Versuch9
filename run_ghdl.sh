#!/usr/bin/env bash
set -euo pipefail

# Generic helper to compile + run one testbench with GHDL.
# Usage: ./run_ghdl.sh <tb_entity_name> <tb_file.vhdl> [stop_time]

TB_ENTITY="${1:?missing tb entity name (e.g. my_rail_crossing_tb_behavior)}"
TB_FILE="${2:?missing tb file (e.g. my_rail_crossing_tb_behavior.vhdl)}"
STOP_TIME="${3:-100ms}"

if ! command -v ghdl >/dev/null 2>&1; then
  echo "ghdl not found in PATH. Please install GHDL to run the simulation." >&2
  exit 127
fi

rm -f work-obj08.cf

ghdl -a --std=08 my_rail_crossing.vhdl
ghdl -a --std=08 "${TB_FILE}"
ghdl -e --std=08 "${TB_ENTITY}"
ghdl -r --std=08 "${TB_ENTITY}" --stop-time="${STOP_TIME}"

