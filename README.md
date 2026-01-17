# ElasticJob UI Docker Images

Docker image build for [Apache ShardingSphere ElasticJob UI](https://github.com/apache/shardingsphere-elasticjob-ui).

## About

ElasticJob UI includes two management consoles:
- **Lite UI**: Management interface for lightweight distributed scheduling
- **Cloud UI**: Management interface for Mesos-based distributed scheduling

This project automatically builds the latest Docker images via GitHub Actions and pushes them to Docker Hub.

## Quick Start

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

### Using Docker Compose

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

### Access

Open in browser: `http://localhost:8088`

**Default credentials:**
- Username: `root`
- Password: `root`

⚠️ **Please change the default password in production!** (See environment variables below)

## Environment Variables

### Common Configuration

| Environment Variable | Default Value | Description |
|---------------------|---------------|-------------|
| `SERVER_PORT` | `8088` | Web service port |
| `AUTH_USERNAME` | `root` | Login username |
| `AUTH_PASSWORD` | `root` | Login password |
| `JAVA_OPTS` | `-server -Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200` | JVM options |

### Lite UI Specific Configuration

**Database Configuration** (Optional, defaults to H2 in-memory database)

| Environment Variable | Default Value | Description |
|---------------------|---------------|-------------|
| `SPRING_DATASOURCE_DEFAULT_DRIVER_CLASS_NAME` | `org.h2.Driver` | Database driver |
| `SPRING_DATASOURCE_DEFAULT_URL` | `jdbc:h2:mem:` | Database URL |
| `SPRING_DATASOURCE_DEFAULT_USERNAME` | `sa` | Database username |
| `SPRING_DATASOURCE_DEFAULT_PASSWORD` | (empty) | Database password |

> 💡 Uses H2 in-memory database by default, works without configuration. Data will be lost after container restart. Configure external database for persistence.

**Stored data:**
- Job execution history logs
- Job status tracking records
- Monitoring statistics

### Cloud UI Specific Configuration

| Environment Variable | Default Value | Description |
|---------------------|---------------|-------------|
| `ZK_SERVERS` | `127.0.0.1:2181` | ZooKeeper server address |
| `ZK_NAMESPACE` | `elasticjob-cloud` | ZooKeeper namespace |
| `ZK_DIGEST` | (empty) | ZooKeeper authentication digest |

## Usage Examples

### Change Login Credentials

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  -e AUTH_USERNAME=admin \
  -e AUTH_PASSWORD=StrongPassword123! \
  qiujun8023/elasticjob-ui:lite-latest
```

### Lite UI + MySQL Persistence

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

### Cloud UI + ZooKeeper Cluster

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

### Custom JVM Options

```bash
docker run -d \
  --name elasticjob-lite-ui \
  -p 8088:8088 \
  -e JAVA_OPTS="-server -Xmx1g -Xms512m -XX:+UseG1GC" \
  qiujun8023/elasticjob-ui:lite-latest
```

## Image Tags

### Lite UI

- `qiujun8023/elasticjob-ui:lite-latest` - Latest version
- `qiujun8023/elasticjob-ui:lite-{version}` - Specific version (e.g. lite-3.0.2)

### Cloud UI

- `qiujun8023/elasticjob-ui:cloud-latest` - Latest version
- `qiujun8023/elasticjob-ui:cloud-{version}` - Specific version (e.g. cloud-3.0.2)

## Supported Architectures

- `linux/amd64`
- `linux/arm64` (including Apple Silicon)

## License

This project is licensed under the Apache License 2.0.

ElasticJob UI is part of Apache ShardingSphere and is licensed under the Apache License 2.0.
