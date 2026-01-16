# ElasticJob UI Docker Build

这个项目用于自动构建 Apache ShardingSphere ElasticJob UI 的 Docker 镜像。

## 项目说明

ElasticJob UI 是 [Apache ShardingSphere ElasticJob](https://shardingsphere.apache.org/elasticjob/) 的管理控制台，包含两个部分:

- **ElasticJob Lite UI**: 轻量级分布式调度解决方案的管理界面
- **ElasticJob Cloud UI**: 基于 Mesos 的分布式调度解决方案的管理界面

本项目通过 GitHub Actions 自动拉取官方源码、编译构建并生成 Docker 镜像。

## 功能特性

- ✅ **独立 Dockerfile**: lite 和 cloud 版本各自独立，简洁清晰
- ✅ **自动获取最新版本**: 通过 GitHub API 获取最新 release
- ✅ **高效构建流程**: GitHub Actions 编译一次，构建两个镜像
- ✅ **现代基础镜像**: 使用 eclipse-temurin:8-jre
- ✅ **安全运行**: 使用非 root 用户运行容器
- ✅ **优化 JVM 参数**: 简化的 JAVA_OPTS，使用 G1GC
- ✅ **支持多架构**: 自动构建 amd64/arm64 镜像
- ✅ **Maven 依赖缓存**: GitHub Actions 缓存加速构建
- ✅ **正确的信号处理**: Java 进程作为 PID 1，正确响应 docker stop

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

### 2. 使用 GitHub Actions 构建

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

### 3. 访问 UI

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
├── Dockerfile.lite            # Lite UI 镜像构建文件
├── Dockerfile.cloud           # Cloud UI 镜像构建文件
├── docker-compose.yml          # Docker Compose 配置
├── .dockerignore              # Docker 构建忽略文件
├── .gitignore                 # Git 忽略文件
└── README.md                  # 项目说明文档
```

## 构建流程

### GitHub Actions 自动化流程

#### Job 1: 编译构建产物 (build-artifacts)

1. **获取版本**: 通过 GitHub API 获取最新 tag
2. **下载源码**: 下载对应版本的源码 tarball
3. **设置环境**: 配置 JDK 8 和 Node.js 14
4. **Maven 编译**: 执行 `mvn clean package -Prelease -DskipTests`
5. **提取产物**: 分别提取 lite-ui 和 cloud-ui 的编译产物
6. **上传 Artifacts**: 将产物上传供下一个 Job 使用

#### Job 2: 构建镜像 (build-and-push)

1. **下载产物**: 从上一个 Job 下载编译好的产物
2. **设置 Buildx**: 配置 Docker 多架构构建
3. **登录 Docker Hub**: 使用 secrets 认证
4. **并行构建**: 使用 matrix 策略同时构建 lite 和 cloud
5. **推送镜像**: 推送到 Docker Hub，包含版本号和 latest 标签
6. **生成摘要**: 输出构建结果和拉取命令

**优势：**
- 编译只需一次，提高效率
- Dockerfile 简单清晰，易于维护
- Java 进程作为 PID 1，正确处理信号
- 支持多架构（amd64 和 arm64）

## 技术栈

- **后端**: Spring Boot
- **前端**: Vue.js + Element UI
- **构建工具**: Maven + Node.js
- **基础镜像**: eclipse-temurin:8-jre
- **CI/CD**: GitHub Actions

## 优化特性

### 1. 独立 Dockerfile
- **简洁清晰**: 每个 Dockerfile 只有约 40 行
- **无变量混淆**: 不依赖构建参数或环境变量
- **易于维护**: 两个文件几乎完全一样，只有启动命令不同

### 2. 高效构建流程
- **编译一次**: Maven 一次编译生成所有产物
- **并行构建**: 两个镜像同时构建
- **GitHub Actions Artifacts**: 产物在 Jobs 间传递

### 3. 非 root 用户
- **安全性**: 以非 root 用户运行，降低安全风险
- **最佳实践**: 符合容器安全规范

### 4. 简化的 JVM 参数
- **合理默认值**: 512MB 堆内存适合大多数场景
- **现代 GC**: 使用 G1GC 替代废弃的 CMS
- **易于调整**: 通过环境变量覆盖

### 5. 正确的信号处理
- **Java 作为 PID 1**: 使用 `exec` 确保 Java 进程成为 PID 1
- **优雅停机**: 正确响应 docker stop 的 SIGTERM 信号
- **无僵尸进程**: 不会产生孤儿进程

### 6. 高效构建缓存
- **Maven 依赖缓存**: 缓存 ~/.m2/repository 加速编译
- **Docker 层缓存**: GitHub Actions 自动缓存构建层
- **并行构建**: 同时构建 lite 和 cloud 版本

### 7. 健康检查
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

容器以非 root 用户 `elasticjob` 运行，提升安全性。

### Q: 支持哪些架构？

支持 linux/amd64 和 linux/arm64（包括 Apple Silicon）。

## 故障排查

### 构建失败 (GitHub Actions)

- 检查 Maven 依赖下载是否正常
- 查看 Actions 日志获取详细错误信息
- 验证 GitHub API 调用是否成功
- 确认编译产物提取路径是否正确

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

### v2.0.0 (2026)
- ✅ 重构为 GitHub Actions 编译 + 简单 Dockerfile
- ✅ 拆分为 Dockerfile.lite 和 Dockerfile.cloud
- ✅ Java 进程作为 PID 1，正确处理信号
- ✅ 添加非 root 用户支持
- ✅ 简化 JAVA_OPTS 配置
- ✅ 更新为 eclipse-temurin 基础镜像
- ✅ 优化构建流程：编译一次，构建两次
- ✅ 添加 Maven 依赖缓存
- ✅ 移除本地构建能力（专注 CI/CD）

### v1.0.0
- 初始版本
- 基于 GitHub Actions 的自动构建
- 支持多架构
