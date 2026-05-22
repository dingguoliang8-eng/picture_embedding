# Docker 镜像构建和部署指南

立体书图片向量服务（DINOv3），默认端口 **8010**。使用 Docker / Docker Compose。

## 目录约定（生产）

| 路径 | 说明 |
|------|------|
| `/data/www/whalesbot-ai-platform` | **项目部署根目录**（在此目录执行 `docker compose`，含 `data/`、`logs/`、compose 文件） |
| `/data/models` | **模型盘**（挂载到容器 `/app/models`） |

**推荐布局**（与平台同机部署时，本服务放在子目录）：

```text
/data/www/whalesbot-ai-platform/
├── picture_embedding/              # 本仓库，在此目录执行 docker compose
│   ├── docker-compose.prod.yml
│   ├── picture_embedding.yaml
│   ├── data/                       # → 容器 /app/data
│   └── logs/                       # → 容器 /app/logs
├── manager-api/                    # 其他组件（示例）
└── ...
```

`docker-compose.prod.yml` 中 `data`、`logs` 已写死为  
`/data/www/whalesbot-ai-platform/picture_embedding/{data,logs}`。  
若你把 compose 放在平台根目录（无 `picture_embedding` 子目录），请把 compose 里对应卷路径改成 `/data/www/whalesbot-ai-platform/data` 与 `.../logs`。

## 服务说明

| 项目 | 说明 |
|------|------|
| 容器名 | `picture-embedding` |
| 镜像仓库 | `whalesbot/whalesbot-ai-platform`（与平台同一仓库） |
| 本服务镜像 tag | `picture-embedding-<版本>`，如 `picture-embedding-latest`、`picture-embedding-v1.0.0` |
| 默认端口 | `8010` |
| API 文档 | `http://<host>:8010/picture-embedding/docs` |
| 向量接口 | `POST /picture-embedding/embed` |
| 上游调用 | manager-api `picture-embedding.base-url` / `picture-embedding.api-key` |

## 阿里云镜像仓库（Whalesbot 个人版实例 · 上海）

| 项 | 值 |
|----|-----|
| 仓库域名 | `crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com` |
| 命名空间 | `whalesbot` |
| 镜像名（与平台共用） | `whalesbot-ai-platform` |
| 本服务 tag | `picture-embedding-<版本>` |
| 完整地址示例 | `.../whalesbot/whalesbot-ai-platform:picture-embedding-v1.0.0` |
| 平台主服务 tag 示例 | `latest` 或 `v1.0.0`（勿与 picture-embedding 混用） |

登录（用户名以控制台为准）：

```bash
docker login --username=leocao0828 crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
```

拉取示例：

```bash
docker pull crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-v1.0.0
```

推送流程（构建机，**同一仓库、不同 tag**）：

```bash
docker build -t picture-embedding:v1.0.0 .
docker tag picture-embedding:v1.0.0 \
  crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-v1.0.0
docker push crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-v1.0.0
```

> 与平台共用 `whalesbot/whalesbot-ai-platform` 仓库；本服务使用 **`picture-embedding-` 前缀 tag**，勿与平台 `latest` / `v*` 混用。

### 其他子项目如何打进同一仓库

**约定**：镜像名固定为 `whalesbot-ai-platform`，每个子项目用 **独立 tag 前缀** `<服务名>-<版本>`。

| 服务（示例） | tag 示例 | 说明 |
|--------------|----------|------|
| 平台主包 | `latest`、`v1.0.0` | 仅主平台使用，勿被子服务占用 |
| picture-embedding | `picture-embedding-v1.0.0` | 本仓库 |
| voiceprint-api | `voiceprint-api-v1.0.0` | 示例 |
| manager-api | `manager-api-v1.0.0` | 示例（若为 Java 镜像） |
| whalesbotai-server | `whalesbotai-server-v1.0.0` | 示例 |

**手动推送（任意子项目）**：

```bash
REGISTRY=crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
SERVICE=voiceprint-api          # 改成你的服务短名（小写、连字符）
VERSION=v1.0.0                    # 或 latest → tag 为 voiceprint-api-latest

docker login --username=leocao0828 ${REGISTRY}
docker build -t ${SERVICE}:${VERSION} .
docker tag ${SERVICE}:${VERSION} \
  ${REGISTRY}/whalesbot/whalesbot-ai-platform:${SERVICE}-${VERSION}
docker push ${REGISTRY}/whalesbot/whalesbot-ai-platform:${SERVICE}-${VERSION}
```

**复制 `build-and-push.sh` 时只改 3 处**：

```bash
IMAGE_NAME="whalesbot-ai-platform"    # 固定不变
IMAGE_TAG="<服务短名>-${VERSION}"     # 如 voiceprint-api-${VERSION}
LOCAL_IMAGE="<服务短名>:${VERSION}"   # 本地构建名，便于识别
```

**docker-compose 中引用**：

```yaml
image: crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:voiceprint-api-v1.0.0
```

**注意**：

- 一个 tag 对应一套镜像内容；不同服务务必用不同 tag 前缀，禁止都推 `latest`。
- tag 只含字母、数字、连字符、点（符合 Docker 规范）。
- 生产部署目录建议：`/data/www/whalesbot-ai-platform/<服务目录>/`。

也可使用 GitHub Actions 推送到 **GHCR**（见 `.github/workflows/docker.yml`）。

---

## 第一步：构建和推送镜像

### 方式一：使用脚本（推荐）

#### Linux/Mac

```bash
chmod +x build-and-push.sh
./build-and-push.sh latest        # 推送 latest 标签
./build-and-push.sh v1.0.0        # 推送版本标签
```

#### Windows

```cmd
build-and-push.bat latest          # 推送 latest 标签
build-and-push.bat v1.0.0          # 推送版本标签
```

### 方式二：手动执行

#### 1. 登录镜像仓库

```bash
docker login --username=leocao0828 crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
```

#### 2. 构建镜像

```bash
docker build -t picture-embedding:latest .
```

> 首次构建会安装 PyTorch 等依赖，耗时较长；镜像体积较大属正常现象。

#### 3. 标记镜像

```bash
docker tag picture-embedding:latest \
  crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-latest
docker tag picture-embedding:v1.0.0 \
  crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-v1.0.0
```

#### 4. 推送镜像

```bash
docker push crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-latest
docker push crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com/whalesbot/whalesbot-ai-platform:picture-embedding-v1.0.0
```

### 方式三：本地开发（不推送仓库）

```bash
docker compose build
docker compose up -d
```

---

## 第二步：在测试环境部署

### 1. 准备测试服务器

确保已安装：

- Docker 20.10+
- Docker Compose 2.0+
- 建议内存 **≥ 8GB**（DINOv3-ViT-L 模型加载与推理占用较高）
- 磁盘空间充足（模型缓存目录 `models/`，首次运行可能需数 GB）

### 2. 登录镜像仓库

```bash
docker login --username=leocao0828 crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
```

### 3. 准备部署目录

```bash
mkdir -p /data/www/whalesbot-ai-platform/picture_embedding
cd /data/www/whalesbot-ai-platform/picture_embedding
mkdir -p data logs
```

将以下文件放到 **`/data/www/whalesbot-ai-platform/picture_embedding`**（从 Git 仓库 `picture_embedding` 目录同步）：

| 文件 | 说明 |
|------|------|
| `docker-compose.test.yml` 或 `docker-compose.prod.yml` | Compose 配置 |
| `picture_embedding.yaml` | 配置模板（首次启动会复制到 `data/`） |

**模型目录**：生产使用宿主机 **`/data/models`**（见下文「挂载 models」），**不要**在项目目录下再建 `models/`。

### 4. 配置服务

编辑 `data/.picture_embedding.yaml`（若不存在，首次 `up` 后由入口脚本从镜像内模板生成）：

```yaml
server:
  host: 0.0.0.0
  port: 8010
  # 生产务必填写；与 manager-api picture-embedding.api-key 一致
  apikey: "your-secret-api-key"

embedding:
  model_name: "facebook/dinov3-vitl16-pretrain-lvd1689m"
  models_dir: "models"
  default_smart_crop: false

logging:
  level: INFO
```

### 5. 挂载 models（生产 `/data/models`）

容器内工作目录为 `/app`，配置项 `embedding.models_dir: models` 即对应 **`/app/models`**。  
生产 `docker-compose.prod.yml` 已配置：

```yaml
volumes:
  - /data/models:/app/models:ro
```

即：**宿主机 `/data/models` → 容器 `/app/models`（只读）**。

#### 宿主机目录结构要求

`/data/models` 下需与开发机 `picture_embedding/models` 一致，至少包含 ModelScope 缓存路径：

```text
/data/models/
├── hub/
│   └── models/
│       └── facebook/
│           └── dinov3-vitl16-pretrain-lvd1689m/   # 权重与 config 等文件
└── huggingface/          # 可选，HF 缓存
    └── hub/
```

从开发机拷贝示例（在能 SSH 到生产机的机器上执行）：

```bash
# 将本机已下载好的 models 同步到生产（保留 hub 结构）
rsync -avz --progress ./models/ user@prod-server:/data/models/
```

或在生产机首次用 Python 拉取一次（需外网），再固定到 `/data/models`：

```bash
# 在装有 modelscope 的环境，MODELSCOPE_CACHE 指向 /data/models/hub
export MODELSCOPE_CACHE=/data/models/hub
python -c "from modelscope import AutoModel; AutoModel.from_pretrained('facebook/dinov3-vitl16-pretrain-lvd1689m')"
```

#### 校验挂载是否生效

```bash
cd /data/www/whalesbot-ai-platform/picture_embedding
docker compose -f docker-compose.prod.yml up -d
docker exec picture-embedding ls -la /app/models/hub/models/facebook/dinov3-vitl16-pretrain-lvd1689m
ls -la /data/www/whalesbot-ai-platform/picture_embedding/data/.picture_embedding.yaml
```

能看到 `config.json` 等文件即表示挂载正确。启动日志应出现 `DINOv3 模型预加载完成`，且**不会**长时间卡在在线下载。

#### 测试环境

`docker-compose.test.yml` 默认 `./models:/app/models`（相对部署目录）。若测试机也有 `/data/models`，可改为与生产相同：

```yaml
- /data/models:/app/models:ro
```

### 6. 部署服务

```bash
# 拉取最新镜像
docker compose -f docker-compose.test.yml pull

# 启动服务
docker compose -f docker-compose.test.yml up -d

# 查看日志（模型预加载需 1～3 分钟，视机器与是否已有缓存而定）
docker compose -f docker-compose.test.yml logs -f

# 查看状态
docker compose -f docker-compose.test.yml ps
```

### 7. 验证

```bash
# 健康检查：OpenAPI 可访问即表示进程已就绪（模型仍在 lifespan 中预加载时请多看日志）
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8010/picture-embedding/openapi.json

# 浏览器打开文档
# http://<服务器IP>:8010/picture-embedding/docs
```

带鉴权测试 embed（将 `YOUR_API_KEY` 替换为 `server.apikey`）：

```bash
curl -X POST "http://127.0.0.1:8010/picture-embedding/embed" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -F "file=@/path/to/test.jpg"
```

### 8. 对接 manager-api

在 manager-api 对应环境配置（如 `application-prod.yml`）：

```yaml
picture-embedding:
  enabled: true
  base-url: http://<picture-embedding-host>:8010
  api-key: your-secret-api-key   # 与 server.apikey 一致
```

确保 manager-api 所在网络能访问 `8010` 端口。

---

## 第三步：生产环境部署

使用 `docker-compose.prod.yml`，建议：

- 修改 compose 中 image 标签为实际推送的 tag（如 `picture-embedding-v1.0.0`）
- `server.apikey` 使用强随机密钥
- 确认宿主机 **`/data/models`** 已就位后再 `up`
- 防火墙仅放行内网访问 `8010`

```bash
cd /data/www/whalesbot-ai-platform/picture_embedding
docker login --username=leocao0828 crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs -f
```

---

## 常用命令

### 更新部署

```bash
cd /data/www/whalesbot-ai-platform/picture_embedding
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### 查看日志

```bash
cd /data/www/whalesbot-ai-platform/picture_embedding
docker compose -f docker-compose.prod.yml logs -f
docker compose -f docker-compose.prod.yml logs -f picture-embedding
```

### 停止服务

```bash
cd /data/www/whalesbot-ai-platform/picture_embedding
docker compose -f docker-compose.prod.yml down
```

### 进入容器调试

```bash
docker exec -it picture-embedding bash
```

### 清理镜像

```bash
docker image prune -a
docker images | grep whalesbot-ai-platform
```

---

## 注意事项

1. **镜像仓库**  
   与平台共用 `whalesbot/whalesbot-ai-platform` 仓库；本服务 tag 必须以 `picture-embedding-` 开头。

2. **认证信息**  
   勿将 `data/.picture_embedding.yaml` 中的 `apikey` 提交到 Git。

3. **资源**  
   - CPU：建议 ≥ 4 核  
   - 内存：建议 ≥ 8GB  
   - 首次启动预加载 DINOv3，`start_period` 已设为 180s

4. **持久化卷（生产）**  
   - `/data/www/whalesbot-ai-platform/picture_embedding/data` → `/app/data`  
   - **`/data/models` → `/app/models:ro`**  
   - `/data/www/whalesbot-ai-platform/picture_embedding/logs` → `/app/logs`

5. **网络**  
   服务器需能 `docker pull` 个人版仓库；无外网时必须在 `/data/models` 预置权重。

6. **服务差异**  
   FastAPI 推理服务，镜像较大；配置在 YAML 而非 `.env`。

---

## 故障排查

### 登录 / 推送 / 拉取失败

同 operations-analysis：检查 `docker login`、命名空间、网络与权限。

### 容器反复重启或 OOM

```bash
docker compose -f docker-compose.test.yml logs picture-embedding
docker stats picture-embedding
```

- 增大内存 limit 或减少并发  
- 确认 `models/` 已挂载且权重完整

### 启动后 502 / 连接被拒绝

- 等待日志出现 `DINOv3 模型预加载完成，服务就绪`  
- 检查端口映射 `8010:8010` 与防火墙

### manager-api 报 10220 / 10221

| 错误码含义 | 处理 |
|------------|------|
| 无法连接 | 检查 `base-url`、容器是否运行、安全组 |
| 鉴权失败 | 对齐 `api-key` 与 `server.apikey` |

### 模型下载失败

- 在可访问 ModelScope 的机器下载后拷贝 `models/` 到服务器  
- 或配置 HTTP 代理（在镜像/宿主机环境变量中设置，视部署方式而定）

---

## 相关文件

| 文件 | 用途 |
|------|------|
| `Dockerfile` | 多阶段构建 |
| `docker-compose.yml` | 本地构建运行 |
| `docker-compose.test.yml` | 测试环境（拉取阿里云镜像） |
| `docker-compose.prod.yml` | 生产环境 |
| `docker-entrypoint.sh` | 初始化 `data/.picture_embedding.yaml` |
| `build-and-push.sh` / `.bat` | 构建并推送阿里云 |
| `.github/workflows/docker.yml` | CI 推送 GHCR |
