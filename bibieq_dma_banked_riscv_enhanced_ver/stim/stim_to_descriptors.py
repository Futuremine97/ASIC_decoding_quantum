#!/usr/bin/env python3
"""
Convert a Stim circuit into 64-bit BiBiEQ descriptor words.

This tool is intended to bridge a BiBiEQ Stim circuit generator
(described in the paper) to the RTL testbench used by this project.

It uses TICK boundaries to define phases. By default it assumes
7 phases per round (BiBiEQ memory circuit schedule).
"""

import argparse
import sys


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--stim", required=True, help="Input .stim file")
    p.add_argument("--out", required=True, help="Output .hex descriptor file")
    p.add_argument("--phases", type=int, default=7, help="Phases per round (default: 7)")
    p.add_argument("--schedule", choices=["2EC", "4EC"], default="4EC", help="EC schedule type")
    p.add_argument("--ds-mode", choices=["alternate", "fixed0", "fixed1"], default="alternate")
    p.add_argument("--r-mod", type=int, default=5, help="Modulo for r field (default: 5)")
    p.add_argument("--u-mode", choices=["index", "zero"], default="index")
    p.add_argument("--v-mode", choices=["index", "zero"], default="index")
    p.add_argument("--e-q", default="0x0000", help="e_q field (hex or int)")
    p.add_argument("--q-q", default="0x0000", help="q_q field (hex or int)")
    p.add_argument("--max-desc", type=int, default=0, help="Optional max descriptors (0 = no limit)")
    return p.parse_args()


def parse_int(value: str) -> int:
    value = value.strip().lower()
    if value.startswith("0x"):
        return int(value, 16)
    return int(value, 10)


def pack_descriptor(seg_idx, use_4ec, phase, r, ds, e_q, q_q, u, v):
    val = 0
    val |= (seg_idx & 0xFF) << 56
    val |= (use_4ec & 0x1) << 55
    val |= (phase & 0x7) << 52
    val |= (r & 0x7) << 49
    val |= (ds & 0x1) << 48
    val |= (e_q & 0xFFFF) << 32
    val |= (q_q & 0xFFFF) << 16
    val |= (u & 0xF) << 12
    val |= (v & 0xF) << 8
    return f"{val:016x}"


def main():
    args = parse_args()
    phases = args.phases
    if phases <= 0:
        print("ERROR: phases must be > 0", file=sys.stderr)
        return 2

    use_4ec = 1 if args.schedule == "4EC" else 0
    e_q = parse_int(args.e_q)
    q_q = parse_int(args.q_q)

    tick_count = 0
    out_lines = []

    with open(args.stim, "r", encoding="utf-8") as f:
        for line in f:
            # strip comments
            if "#" in line:
                line = line.split("#", 1)[0]
            line = line.strip()
            if not line:
                continue
            if line == "TICK":
                if args.max_desc and tick_count >= args.max_desc:
                    break

                phase = tick_count % phases
                round_idx = tick_count // phases
                r = round_idx % args.r_mod

                if args.ds_mode == "alternate":
                    ds = phase & 1
                elif args.ds_mode == "fixed1":
                    ds = 1
                else:
                    ds = 0

                if args.u_mode == "index":
                    u = tick_count & 0xF
                else:
                    u = 0

                if args.v_mode == "index":
                    v = (tick_count >> 4) & 0xF
                else:
                    v = 0

                seg_idx = tick_count & 0xFF
                out_lines.append(
                    pack_descriptor(seg_idx, use_4ec, phase, r, ds, e_q, q_q, u, v)
                )
                tick_count += 1

    if tick_count == 0:
        print("WARN: no TICKs found; no descriptors emitted", file=sys.stderr)

    with open(args.out, "w", encoding="utf-8") as f:
        for line in out_lines:
            f.write(line + "\n")

    print(f"Wrote {len(out_lines)} descriptors to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
