#!/usr/bin/env python3

## This script was made by AI

import argparse
import json
import struct
import sys
from pathlib import Path
from urllib.request import urlopen


def stream_json_array(source: str):
    decoder = json.JSONDecoder()
    parsed_document = False
    buffer = ""

    def parse_buffer():
        nonlocal buffer, parsed_document
        while True:
            buffer = buffer.lstrip()
            if not buffer:
                return
            try:
                value, end = decoder.raw_decode(buffer)
            except json.JSONDecodeError:
                return
            buffer = buffer[end:]
            parsed_document = True
            if not isinstance(value, list):
                raise TypeError("The JSON document must be an array of graph edge objects")
            for item in value:
                yield item

    if source.startswith(("http://", "https://")):
        with urlopen(source) as response:
            chunk = response.read(1 << 20)
            while chunk:
                buffer += chunk.decode("utf-8", errors="strict")
                yield from parse_buffer()
                chunk = response.read(1 << 20)
    else:
        with Path(source).open("r", encoding="utf-8") as fh:
            while True:
                chunk = fh.read(1 << 20)
                if not chunk:
                    break
                buffer += chunk
                yield from parse_buffer()

    if buffer.strip():
        raise ValueError("Input ended with invalid or incomplete JSON")
    if not parsed_document:
        raise ValueError("No JSON document found in input")


def write_graph_edges(source: str, output_path: str):
    output = Path(output_path)
    with output.open("wb") as fh:
        for row in stream_json_array(source):
            if not isinstance(row, dict):
                raise TypeError(f"Expected an object for each graph edge, got {type(row)!r}")

            request_1 = int(row["request_1"])
            request_2 = int(row["request_2"])
            jaccard_index = float(row["jaccard_index"])

            if not 0 <= request_1 < 2**32:
                raise ValueError(f"request_1 is out of range for a wasm32 usize: {request_1}")
            if not 0 <= request_2 < 2**32:
                raise ValueError(f"request_2 is out of range for a wasm32 usize: {request_2}")

            fh.write(struct.pack("<II", request_1, request_2))
            fh.write(struct.pack("<d", jaccard_index))


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Convert a JSON array of GraphEdge objects into a binary file compatible with "
            "std::slice::from_raw_parts on wasm32."
        )
    )
    parser.add_argument("input_json", help="Path or URL to a JSON array of GraphEdge objects")
    parser.add_argument(
        "-o",
        "--output",
        default="graph_edges.bin",
        help="Output binary file path (default: graph_edges.bin)",
    )
    args = parser.parse_args()

    try:
        write_graph_edges(args.input_json, args.output)
    except Exception as exc:  # pragma: no cover - CLI error handling
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
