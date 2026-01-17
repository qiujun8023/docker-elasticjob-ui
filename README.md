# ElasticJob UI Docker 镜像

为 [Apache ShardingSphere ElasticJob UI](https://github.com/apache/shardingsphere-elasticjob-ui) 提供 Docker 镜像构建。

## 项目说明

ElasticJob UI 包含两个管理控制台：
- **Lite UI**: 轻量级分布式调度的管理界面
- **Cloud UI**: 基于 Mesos 的分布式调度管理界面

本项目通过 GitHub Actions 自动构建最新版本的 Docker 镜像并推送到 Docker Hub。

## 快速开始

### ElasticJob Lite UI

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  qiujun8023/elasticjob-ui:lite-latest
```

### ElasticJob Cloud UI

```bash
docker run -d \
  --name elasticjob-cloud-ui \
  -p 8088:8088 \
  -e ZK_SERVERS=your-zookeeper:2181 \
  qiujun8023/elasticjob-ui:cloud-latest
```

### 使用 Docker Compose

```yaml
version: '3.8'

services:
  elasticjob-lite-ui:
    image: qiujun8023/elasticjob-ui:lite-latest
    container_name: elasticjob-lite-ui
    ports:
      - "8088:8088"
    environment:
      - AUTH_USERNAME=admin
      - AUTH_PASSWORD=your-secure-password
    restart: unless-stopped
```

### 访问

浏览器访问: `http://localhost:8088`

**默认登录凭据：**
- 用户名：`root`
- 密码：`root`

⚠️ **生产环境请务必修改默认密码！**（见下方环境变量配置）

## 环境变量配置

### 通用配置

| 环境变量 | 默认值 | 说明 |
|---------|-------|------|
| `SERVER_PORT` | `8088` | Web 服务端口 |
| `AUTH_USERNAME` | `root` | 登录用户名 |
| `AUTH_PASSWORD` | `root` | 登录密码 |
| `JAVA_OPTS` | `-server -Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200` | JVM 参数 |

### Lite UI 专用配置

**数据库配置**（可选，默认使用 H2 内存数据库）

| 环境变量 | 默认值 | 说明 |
|---------|-------|------|
| `SPRING_DATASOURCE_DEFAULT_DRIVER_CLASS_NAME` | `org.h2.Driver` | 数据库驱动 |
| `SPRING_DATASOURCE_DEFAULT_URL` | `jdbc:h2:mem:` | 数据库 URL |
| `SPRING_DATASOURCE_DEFAULT_USERNAME` | `sa` | 数据库用户名 |
| `SPRING_DATASOURCE_DEFAULT_PASSWORD` | （空） | 数据库密码 |

> 💡 默认使用 H2 内存数据库，无需配置即可使用。容器重启后数据会丢失，如需持久化请配置外部数据库。

**存储的数据：**
- 任务执行历史日志
- 任务状态追踪记录
- 监控统计数据

### Cloud UI 专用配置

| 环境变量 | 默认值 | 说明 |
|---------|-------|------|
| `ZK_SERVERS` | `127.0.0.1:2181` | ZooKeeper 服务器地址 |
| `ZK_NAMESPACE` | `elasticjob-cloud` | ZooKeeper 命名空间 |
| `ZK_DIGEST` | （空） | ZooKeeper 认证摘要 |

## 使用示例

### 修改登录密码

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  -e AUTH_USERNAME=admin \
  -e AUTH_PASSWORD=StrongPassword123! \
  qiujun8023/elasticjob-ui:lite-latest
```

### Lite UI + MySQL 持久化

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  -e SPRING_DATASOURCE_DEFAULT_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver \
  -e SPRING_DATASOURCE_DEFAULT_URL=jdbc:mysql://mysql:3306/elasticjob \
  -e SPRING_DATASOURCE_DEFAULT_USERNAME=elasticjob \
  -e SPRING_DATASOURCE_DEFAULT_PASSWORD=db-password \
  qiujun8023/elasticjob-ui:lite-latest
```

### Cloud UI + ZooKeeper 集群

```bash
docker run -d \
  --name elasticjob-cloud-ui \
  -p 8088:8088 \
  -e ZK_SERVERS=zk1:2181,zk2:2181,zk3:2181 \
  -e ZK_NAMESPACE=production \
  -e AUTH_USERNAME=admin \
  -e AUTH_PASSWORD=StrongPassword123! \
  qiujun8023/elasticjob-ui:cloud-latest
```

### 自定义 JVM 参数

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  -e JAVA_OPTS="-server -Xmx1g -Xms512m -XX:+UseG1GC" \
  qiujun8023/elasticjob-ui:lite-latest
```

## 镜像标签

### Lite UI

- `qiujun8023/elasticjob-ui:lite-latest` - 最新版本
- `qiujun8023/elasticjob-ui:lite-{version}` - 指定版本（如 lite-3.0.2）

### Cloud UI

- `qiujun8023/elasticjob-ui:cloud-latest` - 最新版本
- `qiujun8023/elasticjob-ui:cloud-{version}` - 指定版本（如 cloud-3.0.2）

## 支持的架构

- `linux/amd64`
- `linux/arm64`（包括 Apple Silicon）

## 常见问题

### Q: 容器启动后无法访问？

检查端口是否被占用：
```bash
lsof -i :8088
```

查看容器日志：
```bash
docker logs elasticjob-lite-ui
```

### Q: Cloud UI 无法连接 ZooKeeper？

确认 ZooKeeper 地址是否正确，容器是否能访问 ZooKeeper 网络：
```bash
docker exec elasticjob-cloud-ui ping your-zookeeper-host
```

### Q: 如何查看容器运行状态？

```bash
docker ps -a | grep elasticjob
docker inspect elasticjob-lite-ui
```

### Q: 容器以什么用户运行？

容器以非 root 用户 `elasticjob` 运行，提升安全性。

## 相关链接

- [ElasticJob 官方网站](https://shardingsphere.apache.org/elasticjob/)
- [ElasticJob UI 源码](https://github.com/apache/shardingsphere-elasticjob-ui)
- [Docker Hub 镜像](https://hub.docker.com/r/qiujun8023/elasticjob-ui)
- [本项目 GitHub](https://github.com/qiujun8023/docker-elasticjob-ui)

## 许可证

本项目遵循 Apache License 2.0 许可证。

ElasticJob UI 是 Apache ShardingSphere 的一部分，遵循 Apache License 2.0 许可证。
