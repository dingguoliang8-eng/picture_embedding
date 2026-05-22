# Picture Embedding API

基于 **DINOv3**（`facebook/dinov3-vitl16-pretrain-lvd1689m`，与 `whalesbotai-server/core/utils/popup_book_dinov3.py` 一致）的图片向量服务：上传图片，返回浮点向量。

部署与运维形态参考 **voiceprint-api**（FastAPI + `start_server.py` + `service.sh` + Docker 多阶段构建 + `docker-compose`）。

## 环境

- Python 3.10+
- 首次运行会从 ModelScope/HuggingFace 拉取权重，请保证磁盘与网络；模型缓存目录默认为项目下 `models/`（可通过配置 `embedding.models_dir` 修改）。

## 配置

```bash
mkdir -p data
cp picture_embedding.yaml data/.picture_embedding.yaml
# 生产环境请在 data/.picture_embedding.yaml 的 server.apikey 填入密钥；请求须带请求头 X-Api-Key: <密钥>（或使用头 apikey）
```

## 安装

```bash
conda create -n picture-embedding python=3.10 -y
conda activate picture-embedding
pip install -r requirements.txt
```

## 启动

- 开发（热重载）：`python -m app.main`
- 生产：`python start_server.py`
- Linux 后台（Conda，与 voiceprint-api 相同）：`chmod +x service.sh && ./service.sh start`

文档：`http://<host>:8010/picture-embedding/docs`

## API 摘要

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/picture-embedding/embed?smart_crop=false` | 若配置了 `server.apikey`，须加请求头 `X-Api-Key`（或 `apikey`）。`multipart/form-data` 字段 `file` 上传图片，返回 JSON：`model_name`, `dimension`, `vector`, `smart_crop` |

`smart_crop=true` 时使用 **rembg** 去背景并按 bbox 裁剪，与绘本 `popup_book_dinov3` 预处理一致；默认以配置项 `embedding.default_smart_crop` 为准。

## Docker

本地快速启动：

```bash
docker compose build
docker compose up -d
```

首次启动若未挂载配置文件，入口脚本会将镜像内 `picture_embedding.yaml` 复制到 `data/.picture_embedding.yaml`。建议挂载 `./data` 与 `./models` 以持久化配置与权重。

**测试/生产环境 Docker 部署**（构建推送阿里云、Compose 部署、对接 manager-api）：见 **[DEPLOY.md](./DEPLOY.md)**。

## CI/CD

GitHub Actions：`.github/workflows/docker.yml` — 在 `main` / `master` 推送及 `v*` 标签时构建并推送镜像到 **GHCR**（`ghcr.io/<owner>/<repo>`）。需仓库开启 `GITHUB_TOKEN` 的 `packages: write`（工作流已声明权限）。

与 voiceprint-api 一样，可在 `docker-compose.yml` 中改为拉取已发布的镜像地址。
