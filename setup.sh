#!/bin/bash
# 这个脚本会在 Radeon Cloud 启动模板时自动执行

set -e
cd /workspace

echo "正在安装基础依赖..."
apt-get update && apt-get install -y ffmpeg

echo "正在下载 AI 视频工具..."
# 如果目录不存在，则克隆项目
if [ ! -d "MoneyPrinterTurbo" ]; then
    git clone https://github.com/harry0703/MoneyPrinterTurbo.git
fi
if [ ! -d "NarratoAI" ]; then
    git clone https://github.com/linyqh/NarratoAI.git
fi

echo "正在安装 Python 依赖..."
cd MoneyPrinterTurbo && pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
cd ../NarratoAI && pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

echo "正在启动服务..."
# 启动 NarratoAI (8501 端口)
cd /workspace/NarratoAI
nohup streamlit run webui.py --server.port 8501 --server.maxUploadSize=2048 > narrato.log 2>&1 &

# 启动 MoneyPrinterTurbo (8502 端口)
cd /workspace/MoneyPrinterTurbo
nohup streamlit run ./webui/Main.py --server.port 8502 > mpt.log 2>&1 &

# 启动 cloudflared 隧道 (公网访问)
cd /workspace
nohup ./cloudflared tunnel --url http://localhost:8501 > tunnel_8501.log 2>&1 &
nohup ./cloudflared tunnel --url http://localhost:8502 > tunnel_8502.log 2>&1 &

echo "所有服务已启动！"
echo "NarratoAI 访问地址："
cat tunnel_8501.log | grep -o "https://[a-z0-9-]*\.trycloudflare\.com" | head -1
echo "MoneyPrinterTurbo 访问地址："
cat tunnel_8502.log | grep -o "https://[a-z0-9-]*\.trycloudflare\.com" | head -1
