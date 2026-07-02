#!/usr/bin/env bash
# One-shot: .pt -> ONNX -> RDK X5 .bin
# Usage:
#   ./convert.sh                          # interactive, prompt for .pt path
#   ./convert.sh ~/Desktop/my_model.pt    # direct path

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP="${HOME}/Desktop"
CAL_DIR="${TOOL_DIR}/calibration_data"

if [[ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/miniconda3/etc/profile.d/conda.sh"
  conda activate rdk310
fi

if ! command -v hb_mapper >/dev/null 2>&1; then
  echo "ERROR: hb_mapper 未找到。请先安装环境："
  echo "  conda activate rdk310"
  echo "  pip install rdkx5-yolo-mapper torch ultralytics onnx onnxsim"
  exit 1
fi

if [[ ! -d "${CAL_DIR}" ]] || [[ -z "$(ls -A "${CAL_DIR}" 2>/dev/null)" ]]; then
  echo "ERROR: 校准图目录为空: ${CAL_DIR}"
  exit 1
fi

resolve_pt_path() {
  local raw="$1"
  raw="${raw//\'/}"
  raw="${raw//\"/}"
  raw="${raw#file://}"
  raw="$(echo "${raw}" | xargs)"
  readlink -f "${raw}"
}

if [[ $# -ge 1 ]]; then
  PT_PATH="$(resolve_pt_path "$1")"
else
  echo "========================================"
  echo " RDK X5 YOLO 模型转换"
  echo " 拖入 .pt 文件路径，或输入完整路径后回车"
  echo "========================================"
  read -rp "模型路径: " INPUT
  PT_PATH="$(resolve_pt_path "${INPUT}")"
fi

if [[ ! -f "${PT_PATH}" ]]; then
  echo "ERROR: 文件不存在: ${PT_PATH}"
  exit 1
fi
if [[ "${PT_PATH}" != *.pt ]]; then
  echo "ERROR: 需要 .pt 文件"
  exit 1
fi

STEM="$(basename "${PT_PATH}" .pt)"
MMDD="$(date +%m%d)"
OUT_DIR="${DESKTOP}/${MMDD}_${STEM}"
PREFIX="${STEM}_bayese_640x640_nv12"

if [[ -d "${OUT_DIR}" ]]; then
  echo "WARNING: 目录已存在，将在其中继续/覆盖: ${OUT_DIR}"
else
  mkdir -p "${OUT_DIR}"
fi

echo ""
echo "==> 输出目录: ${OUT_DIR}"
echo "==> 复制 .pt ..."
cp -f "${PT_PATH}" "${OUT_DIR}/${STEM}.pt"

echo "==> 导出 ONNX ..."
python "${TOOL_DIR}/scripts/export_onnx.py" \
  --pt "${OUT_DIR}/${STEM}.pt" \
  --out-dir "${OUT_DIR}"

echo "==> 生成 convert_config.yaml ..."
python "${TOOL_DIR}/scripts/gen_config.py" \
  --onnx "${OUT_DIR}/${STEM}.onnx" \
  --out-dir "${OUT_DIR}" \
  --cal-dir "${CAL_DIR}" \
  --prefix "${PREFIX}"

cd "${OUT_DIR}"
rm -rf model_output

echo "==> 检查 ONNX ..."
hb_mapper checker \
  --model-type onnx \
  --model "./${STEM}.onnx" \
  --march bayes-e \
  --input-shape images 1x3x640x640

echo "==> 量化转 .bin（约 10~15 分钟）..."
hb_mapper makertbin --model-type onnx --config convert_config.yaml 2>&1 | tee convert.log

BIN="$(find model_output -name "${PREFIX}.bin" | head -1)"
if [[ -z "${BIN}" ]]; then
  echo "ERROR: 未找到 ${PREFIX}.bin"
  exit 1
fi
cp -f "${BIN}" "./${PREFIX}.bin"

cat > README.txt <<EOF
转换时间: $(date '+%Y-%m-%d %H:%M:%S')
源模型:   ${PT_PATH}
输出目录: ${OUT_DIR}

文件清单:
  ${STEM}.pt
  ${STEM}.onnx
  ${PREFIX}.bin
  convert_config.yaml
  convert.log

拷到 RDK 板子:
  scp ${PREFIX}.bin sunrise@<板子IP>:/home/sunrise/Desktop/palm_handup_rdk/

板端验证:
  python3 handup_detect.py --model-path ${PREFIX}.bin --test-dir <测试图目录> --max-images 20
EOF

echo ""
echo "========================================"
echo " 转换完成"
echo " 目录: ${OUT_DIR}"
echo " .bin: ${OUT_DIR}/${PREFIX}.bin ($(du -h "${OUT_DIR}/${PREFIX}.bin" | cut -f1))"
echo "========================================"
echo "桌面上的 .pt 可以删了，副本已保存在上述目录中。"
