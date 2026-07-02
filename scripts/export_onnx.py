#!/usr/bin/env python3
"""Export YOLO .pt to RDK-compatible ONNX (opset 11, 640x640)."""

import argparse
from pathlib import Path

from ultralytics import YOLO


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pt", type=str, required=True, help="Path to YOLO .pt weights")
    parser.add_argument("--out-dir", type=str, required=True, help="Directory to save ONNX")
    parser.add_argument("--imgsz", type=int, default=640)
    args = parser.parse_args()

    pt_path = Path(args.pt)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    model = YOLO(str(pt_path))
    print("Model names:", model.names)
    print("Task:", model.task)

    onnx_path = model.export(
        format="onnx",
        imgsz=args.imgsz,
        opset=11,
        simplify=True,
        dynamic=False,
    )
    onnx_path = Path(onnx_path)
    target = out_dir / f"{pt_path.stem}.onnx"
    if onnx_path.resolve() != target.resolve():
        target.write_bytes(onnx_path.read_bytes())
    print(f"Exported ONNX: {target} ({target.stat().st_size / 1024 / 1024:.2f} MB)")


if __name__ == "__main__":
    main()
