#!/usr/bin/env python3
"""Generate hb_mapper convert_config.yaml for a model output directory."""

import argparse
from pathlib import Path


TEMPLATE = """\
# Auto-generated for RDK X5 (bayes-e)
model_parameters:
  onnx_model: './{onnx_name}'
  march: 'bayes-e'
  layer_out_dump: False
  working_dir: './model_output'
  output_model_file_prefix: '{prefix}'
  remove_node_type: 'Quantize;Dequantize;Transpose;Cast;Reshape;Softmax'

input_parameters:
  input_type_rt: 'nv12'
  input_type_train: 'rgb'
  input_layout_train: 'NCHW'
  input_shape: '1x3x640x640'
  norm_type: 'data_scale'
  scale_value: 0.003921568627451

calibration_parameters:
  cal_data_dir: '{cal_dir}'
  cal_data_type: 'float32'
  calibration_type: 'default'
  preprocess_on: true

compiler_parameters:
  compile_mode: 'latency'
  debug: False
  optimize_level: 'O3'
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--onnx", type=str, required=True)
    parser.add_argument("--out-dir", type=str, required=True)
    parser.add_argument("--cal-dir", type=str, required=True)
    parser.add_argument("--prefix", type=str, required=True)
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    onnx_name = Path(args.onnx).name
    cal_dir = str(Path(args.cal_dir).resolve())

    content = TEMPLATE.format(onnx_name=onnx_name, prefix=args.prefix, cal_dir=cal_dir)
    config_path = out_dir / "convert_config.yaml"
    config_path.write_text(content, encoding="utf-8")
    print(f"Wrote {config_path}")


if __name__ == "__main__":
    main()
