# rdk-x5-yolo-converter

在 x86 Ubuntu 虚拟机上，将 YOLOv8 `.pt` 一键转换为 RDK X5（march=`bayes-e`）可用的 `.bin`。

## 日常使用

1. 从 Windows 拖 `.pt` 到虚拟机桌面
2. 运行：

```bash
~/Desktop/rdk-yolo-converter/convert.sh
# 或拖入路径：
~/Desktop/rdk-yolo-converter/convert.sh ~/Desktop/my_model.pt
```

3. 桌面会生成 **`MMDD_模型名/`** 目录，例如 `0702_0702best/`，内含：

| 文件 | 说明 |
|------|------|
| `{模型名}.pt` | 权重副本（可删桌面上的原文件） |
| `{模型名}.onnx` | ONNX，opset 11 |
| `{模型名}_bayese_640x640_nv12.bin` | RDK BPU 模型 |
| `convert_config.yaml` | 本次转换配置 |
| `convert.log` | 转换日志 |
| `README.txt` | 拷板命令摘要 |

## 环境（首次）

```bash
# Python 3.10 + hb_mapper
source ~/miniconda3/etc/profile.d/conda.sh
conda activate rdk310
pip install rdkx5-yolo-mapper torch ultralytics onnx onnxsim
```

## 目录说明

```
rdk-yolo-converter/
├── convert.sh           # 入口脚本
├── scripts/             # 导出 ONNX、生成 yaml
├── calibration_data/    # PTQ 校准图（50 张，随仓库分发）
└── handup.names         # 类别名参考
```

转换产物**不**进 Git，全部在桌面 `MMDD_*` 目录；验证完下载到 Windows 后可整目录删除。

## RDK 板端

```bash
scp MMDD_xxx/xxx_bayese_640x640_nv12.bin sunrise@<IP>:/home/sunrise/Desktop/palm_handup_rdk/
```

## Git 仓库名建议

`rdk-x5-yolo-converter`（本仓库默认名）
