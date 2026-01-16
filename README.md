# ElasticJob UI Docker Build

这个项目用于自动构建 Apache ShardingSphere ElasticJob UI 的 Docker 镜像。

## 项目说明

ElasticJob UI 是 [Apache ShardingSphere ElasticJob](https://shardingsphere.apache.org/elasticjob/) 的管理控制台，包含两个部分:

- **ElasticJob Lite UI**: 轻量级分布式调度解决方案的管理界面
- **ElasticJob Cloud UI**: 基于 Mesos 的分布式调度解决方案的管理界面

本项目通过 GitHub Actions 自动拉取官方源码、编译构建并生成 Docker 镜像。

## 功能特性

- ✅ **多阶段构建**: 在 Dockerfile 中完成源码下载、编译和镜像构建
- ✅ **统一 Dockerfile**: 通过 build args 区分 lite 和 cloud 版本
- ✅ **自动获取最新版本**: 通过 GitHub API 获取最新 release
- ✅ **高效源码下载**: 直接下载 tarball，无需克隆完整仓库
- ✅ **现代基础镜像**: 使用 eclipse-temurin:8 替代废弃的 openjdk
- ✅ **安全运行**: 使用非 root 用户 (UID 1000) 运行容器
- ✅ **优化 JVM 参数**: 简化的 JAVA_OPTS，使用 G1GC
- ✅ **支持多架构**: 自动构建 amd64/arm64 镜像
- ✅ **构建缓存**: GitHub Actions 缓存加速构建
- ✅ **本地构建支持**: 多阶段构建允许本地轻松构建镜像

## 使用方法

### 1. 从 Docker Hub 拉取镜像（推荐）

如果你只想使用镜像，直接拉取即可：

#### ElasticJob Lite UI

```bash
# 拉取最新版本
docker pull <your-dockerhub-username>/elasticjob-ui:lite-latest

# 或拉取指定版本（如 3.0.2）
docker pull <your-dockerhub-username>/elasticjob-ui:lite-3.0.2

# 运行容器
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  <your-dockerhub-username>/elasticjob-ui:lite-latest
```

#### ElasticJob Cloud UI

```bash
# 拉取最新版本
docker pull <your-dockerhub-username>/elasticjob-ui:cloud-latest

# 或拉取指定版本（如 3.0.2）
docker pull <your-dockerhub-username>/elasticjob-ui:cloud-3.0.2

# 运行容器
docker run -d \
  --name elasticjob-cloud-ui \
  -p 8088:8088 \
  <your-dockerhub-username>/elasticjob-ui:cloud-latest
```

#### 使用 Docker Compose

```bash
# 编辑 docker-compose.yml，替换镜像名称中的用户名
# 然后运行
docker compose up -d
```

### 2. 本地构建镜像

得益于多阶段构建，你可以在本地轻松构建镜像：

```bash
# 构建 Lite UI（最新版本）
docker build \
  --build-arg UI_TYPE=lite \
  -t elasticjob-ui:lite-latest .

# 构建 Cloud UI（最新版本）
docker build \
  --build-arg UI_TYPE=cloud \
  -t elasticjob-ui:cloud-latest .
```

### 3. 使用 GitHub Actions 构建

#### 配置 GitHub Secrets

在 GitHub 仓库中配置以下 Secrets:

- `DOCKER_USERNAME`: Docker Hub 用户名
- `DOCKER_PASSWORD`: Docker Hub 密码或 Access Token

#### 触发构建

1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "Build ElasticJob UI Docker Image" workflow
3. 点击 "Run workflow" 按钮
4. 等待构建完成（无需填写任何参数，自动构建最新版本）

构建完成后，会生成以下 Docker 镜像标签：
- `<your-username>/elasticjob-ui:lite-<version>` - Lite UI 指定版本
- `<your-username>/elasticjob-ui:lite-latest` - Lite UI 最新版本
- `<your-username>/elasticjob-ui:cloud-<version>` - Cloud UI 指定版本
- `<your-username>/elasticjob-ui:cloud-latest` - Cloud UI 最新版本

### 4. 访问 UI

浏览器访问: `http://localhost:8088`

## 环境变量配置

可以通过环境变量自定义 JVM 参数：

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  -e JAVA_OPTS="-server -Xmx1g -Xms512m -XX:+UseG1GC" \
  <your-dockerhub-username>/elasticjob-ui:lite-latest
```

默认 JVM 参数：
```bash
JAVA_OPTS="-server -Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

## 项目结构

```
docker-elasticjob-ui/
├── .github/
│   └── workflows/
│       └── build-docker.yml    # GitHub Actions 工作流配置
├── Dockerfile                  # 多阶段构建 Dockerfile（支持 lite 和 cloud）
├── docker-compose.yml          # Docker Compose 配置
├── .dockerignore              # Docker 构建忽略文件
├── .gitignore                 # Git 忽略文件
└── README.md                  # 项目说明文档
```

## 构建流程

### 本地构建流程

1. **下载源码**: 通过 wget 直接下载指定版本的源码 tarball
2. **设置环境**: Dockerfile 构建阶段包含 JDK 8、Node.js 和 Maven
3. **编译构建**: 使用 Maven 执行 `mvn clean package -Prelease -DskipTests`
4. **提取产物**: 解压编译生成的 tar.gz 文件
5. **构建运行镜像**: 复制编译产物到精简的 JRE 镜像
6. **设置权限**: 创建非 root 用户并设置文件权限

### GitHub Actions 流程

1. **检出代码**: 克隆本仓库
2. **设置 Buildx**: 配置 Docker 多架构构建
3. **登录 Docker Hub**: 使用 secrets 认证
4. **获取版本**: 通过 GitHub API 获取最新 tag
5. **并行构建**: 使用 matrix 策略同时构建 lite 和 cloud
6. **推送镜像**: 推送到 Docker Hub，包含版本号和 latest 标签
7. **生成摘要**: 输出构建结果和拉取命令

## 技术栈

- **后端**: Spring Boot
- **前端**: Vue.js + Element UI
- **构建工具**: Maven + Node.js
- **基础镜像**:
  - 构建阶段: eclipse-temurin:8-jdk-alpine
  - 运行阶段: eclipse-temurin:8-jre-alpine
- **CI/CD**: GitHub Actions

## 优化特性

### 1. 多阶段构建
- **优势**: 最终镜像体积小，不包含构建工具
- **本地友好**: 无需预先安装 JDK、Maven、Node.js

### 2. 非 root 用户
- **安全性**: 以 UID 1000 运行，降低安全风险
- **最佳实践**: 符合容器安全规范

### 3. 简化的 JVM 参数
- **合理默认值**: 512MB 堆内存适合大多数场景
- **现代 GC**: 使用 G1GC 替代废弃的 CMS
- **易于调整**: 通过环境变量覆盖

### 4. 高效构建
- **GitHub Actions 缓存**: 自动缓存 Docker 构建层
- **并行构建**: 同时构建 lite 和 cloud 版本
- **增量下载**: 仅下载必要的源码 tarball

### 5. 健康检查
- 检查间隔: 30秒
- 超时时间: 3秒
- 启动等待: 40秒
- 重试次数: 3次

## 常见问题

### Q: 如何查看容器日志？

```bash
docker logs elasticjob-lite-ui
```

### Q: 如何进入容器调试？

```bash
docker exec -it elasticjob-lite-ui sh
```

### Q: 如何修改端口？

```bash
docker run -d --name elasticjob-lite-ui -p 9999:8088 <image>
```

### Q: 容器以什么用户运行？

容器以非 root 用户 `elasticjob` (UID 1000) 运行，提升安全性。

### Q: 支持哪些架构？

支持 linux/amd64 和 linux/arm64（包括 Apple Silicon）。

## 故障排查

### 构建失败

**本地构建失败**:
- 检查网络连接（需要下载 Maven 依赖）
- 确认 Docker 有足够的内存和磁盘空间
- 查看构建日志中的错误信息

**GitHub Actions 失败**:
- 检查 Maven 依赖下载是否正常
- 查看 Actions 日志获取详细错误信息
- 验证 GitHub API 调用是否成功

### 镜像推送失败

- 确认 Docker Hub 凭据配置正确
- 检查网络连接状态
- 验证 Docker Hub 仓库是否存在且有写权限

### 容器启动失败

- 检查端口是否被占用: `lsof -i :8088`
- 查看容器日志: `docker logs elasticjob-lite-ui`
- 检查健康检查状态: `docker inspect elasticjob-lite-ui`
- 验证是否有足够的内存

### 健康检查失败

- 等待更长时间（应用启动需要约 40 秒）
- 检查应用日志是否有错误
- 确认端口 8088 未被占用

## 许可证

本项目遵循 Apache License 2.0 许可证。

ElasticJob UI 是 Apache ShardingSphere 的一部分，遵循 Apache License 2.0 许可证。

## 相关链接

- [ElasticJob 官方网站](https://shardingsphere.apache.org/elasticjob/)
- [ElasticJob UI GitHub](https://github.com/apache/shardingsphere-elasticjob-ui)
- [Apache ShardingSphere](https://shardingsphere.apache.org/)
- [Docker Hub](https://hub.docker.com/)

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v2.0.0 (2024)
- ✅ 重构为多阶段构建
- ✅ 合并 Dockerfile，使用 build args 区分版本
- ✅ 添加非 root 用户支持
- ✅ 简化 JAVA_OPTS 配置
- ✅ 更新为 eclipse-temurin 基础镜像
- ✅ 优化源码下载方式
- ✅ 添加 GitHub Actions 缓存
- ✅ 支持本地构建
- ✅ 简化 docker-compose 配置

### v1.0.0
- 初始版本
- 基于 GitHub Actions 的自动构建
- 支持多架构
