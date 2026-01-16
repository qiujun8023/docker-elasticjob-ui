# Multi-stage Dockerfile for ElasticJob UI (Lite & Cloud)
# Build argument to specify UI type: lite or cloud
ARG UI_TYPE=lite

# ========== Build Stage ==========
FROM eclipse-temurin:8-jdk-alpine AS builder

# Install build dependencies
RUN apk add --no-cache wget tar jq nodejs npm maven

# Set working directory
WORKDIR /build

# Accept build argument
ARG UI_TYPE

# Download ElasticJob UI source code (always latest version)
RUN LATEST_TAG=$(wget -qO- https://api.github.com/repos/apache/shardingsphere-elasticjob-ui/releases/latest | jq -r '.tag_name') && \
    echo "Building latest version: $LATEST_TAG" && \
    wget -qO- "https://github.com/apache/shardingsphere-elasticjob-ui/archive/refs/tags/${LATEST_TAG}.tar.gz" | tar xz --strip-components=1

# Build the project
RUN mvn clean package -Prelease -DskipTests -Dmaven.javadoc.skip=true -q

# Extract built artifacts based on UI type
RUN cd shardingsphere-elasticjob-ui-distribution/shardingsphere-elasticjob-${UI_TYPE}-ui-bin-distribution/target && \
    tar -xzf apache-shardingsphere-*-shardingsphere-elasticjob-${UI_TYPE}-ui-bin.tar.gz && \
    mv apache-shardingsphere-*-shardingsphere-elasticjob-${UI_TYPE}-ui-bin /app

# ========== Runtime Stage ==========
FROM eclipse-temurin:8-jre-alpine

# Metadata labels
LABEL maintainer="ElasticJob UI" \
      org.opencontainers.image.title="ElasticJob UI" \
      org.opencontainers.image.description="Management console for Apache ShardingSphere ElasticJob" \
      org.opencontainers.image.source="https://github.com/apache/shardingsphere-elasticjob-ui" \
      org.opencontainers.image.licenses="Apache-2.0"

# Install curl for health check
RUN apk add --no-cache curl

# Accept UI type argument and convert to environment variable for runtime
ARG UI_TYPE
ENV UI_TYPE=${UI_TYPE}

# Create non-root user
RUN addgroup -g 1000 elasticjob && \
    adduser -D -u 1000 -G elasticjob elasticjob

# Set working directory
WORKDIR /opt/elasticjob-ui

# Copy application from builder stage
COPY --from=builder --chown=elasticjob:elasticjob /app ./

# Create logs directory with correct ownership
RUN mkdir -p logs && chown elasticjob:elasticjob logs

# Switch to non-root user
USER elasticjob

# Set simplified JAVA_OPTS with reasonable defaults
# Users can override via environment variable
ENV JAVA_OPTS="-server -Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Set JVM to output logs to stdout/stderr
ENV JAVA_TOOL_OPTIONS="-Dlogging.level.root=INFO"

# Expose default port
EXPOSE 8088

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8088/ || exit 1

# Determine the correct Bootstrap class and classpath based on UI type
CMD if [ "${UI_TYPE}" = "lite" ]; then \
        exec java ${JAVA_OPTS} -classpath ".:conf:lib/*:ext-lib/*" \
        org.apache.shardingsphere.elasticjob.lite.ui.Bootstrap; \
    else \
        exec java ${JAVA_OPTS} -classpath ".:conf:lib/*" \
        org.apache.shardingsphere.elasticjob.cloud.ui.Bootstrap; \
    fi
