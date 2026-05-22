# Docker 镜像构建和部署指南

立体书图片向量服务（DINOv3），默认端口 **8010**。使用 Docker / Docker Compose。

## 服务说明

| 项目 | 说明 |
|------|------|
| 镜像名称 | `picture-embedding` |
| 默认端口 | `8010` |
| API 文档 | `http://<host>:8010/picture-embedding/docs` |
| 向量接口 | `POST /picture-embedding/embed` |
| 上游调用 | manager-api `picture-embedding.base-url` / `picture-embedding.api-key` |

## 阿里云镜像仓库配置

- **命名空间**: `dejavu_ding`（请按实际账号修改）
- **镜像名称**: `picture-embedding`
- **镜像地址格式**: `registry.cn-<region>.aliyuncs.com/dejavu_ding/picture-embedding:<tag>`

也可使用 GitHub Actions 推送到 **GHCR**：`ghcr.io/<owner>/<repo>`（见 `.github/workflows/docker.yml`）。

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

#### 1. 登录阿里云镜像仓库

```bash
# 请根据你的镜像仓库区域修改（hangzhou/beijing/shanghai/shenzhen 等）
docker login --username=<你的用户名> registry.cn-hangzhou.aliyuncs.com
```

#### 2. 构建镜像

```bash
docker build -t picture-embedding:latest .
```

> 首次构建会安装 PyTorch 等依赖，耗时较长；镜像体积较大属正常现象。

#### 3. 标记镜像

```bash
docker tag picture-embedding:latest registry.cn-hangzhou.aliyuncs.com/dejavu_ding/picture-embedding:latest
docker tag picture-embedding:latest registry.cn-hangzhou.aliyuncs.com/dejavu_ding/picture-embedding:v1.0.0
```

#### 4. 推送镜像

```bash
docker push registry.cn-hangzhou.aliyuncs.com/dejavu_ding/picture-embedding:latest
docker push registry.cn-hangzhou.aliyuncs.com/dejavu_ding/picture-embedding:v1.0.0
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

### 2. 登录阿里云镜像仓库

```bash
docker login --username=<你的用户名> registry.cn-hangzhou.aliyuncs.com
```

### 3. 准备部署目录

```bash
mkdir -p /opt/picture-embedding
cd /opt/picture-embedding
```

将以下文件放到该目录（可从仓库复制）：

| 文件 | 说明 |
|------|------|
| `docker-compose.test.yml` | 测试环境 Compose |
| `picture_embedding.yaml` | 配置模板（首次启动会复制到 `data/`） |

创建持久化目录：

```bash
mkdir -p data models logs
```

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

**模型权重**（二选一）：

1. **推荐**：在宿主机提前下载好模型，挂载到 `./models`（与开发环境 `models/hub` 结构一致），避免容器内重复下载。
2. 留空挂载，容器首次启动时从 ModelScope/HuggingFace 拉取（需外网，启动较慢）。

### 5. 部署服务

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

### 6. 验证

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

### 7. 对接 manager-api

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

使用 `docker-compose.prod.yml`，步骤与测试环境相同，建议：

- 使用**版本标签**（如 `v1.0.0`），勿仅依赖 `latest`
- `server.apikey` 使用强随机密钥
- 通过防火墙限制 `8010` 仅内网或指定安全组可访问
- 定期备份 `data/`、`models/` 挂载目录

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

---

## 常用命令

### 更新部署

```bash
docker compose -f docker-compose.test.yml pull
docker compose -f docker-compose.test.yml up -d
```

### 查看日志

```bash
docker compose -f docker-compose.test.yml logs -f
docker compose -f docker-compose.test.yml logs -f picture-embedding
```

### 停止服务

```bash
docker compose -f docker-compose.test.yml down
```

### 进入容器调试

```bash
docker exec -it picture-embedding bash
```

### 清理镜像

```bash
docker image prune -a
docker images | grep picture-embedding
```

---

## 注意事项

1. **镜像仓库区域**  
   按阿里云控制台实际地址修改 `build-and-push.sh` / `build-and-push.bat` 中的 `REGISTRY`。

2. **认证信息**  
   使用 RAM 子账号访问凭证；勿将 `data/.picture_embedding.yaml` 中的 `apikey` 提交到 Git。

3. **资源**  
   - CPU：建议 ≥ 4 核  
   - 内存：建议 ≥ 8GB（Compose 中已设 limits，可按机器调整）  
   - 首次启动会在 lifespan 中预加载 DINOv3，`healthcheck` 的 `start_period` 已放宽

4. **持久化卷**  
   - `./data`：运行时配置 `data/.picture_embedding.yaml`  
   - `./models`：模型缓存（强烈建议挂载，避免每次重启重新下载）  
   - `./logs`：应用日志目录

5. **网络**  
   测试/生产服务器需能拉取阿里云镜像；若无法访问外网拉模型，必须预置 `models/` 目录。

6. **与 operations-analysis 的差异**  
   - 本服务为 FastAPI + GPU/CPU 推理，镜像更大、启动更慢  
   - 配置在 YAML 而非 `.env`（除 Compose 中的 `TZ` 等）

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
