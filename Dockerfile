# ============================================================
# Dockerfile – Portfolio Backend (Quarkus JVM mode)
# ============================================================
# Build steps:
#   1. docker compose build
#   OR (manual):
#   1. ./mvnw package -DskipTests
#   2. docker build -t portfolio-backend .
# ============================================================

### Stage 1 – Build ###
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Copy Maven wrapper & pom first (layer cache)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Download dependencies (cached unless pom.xml changes)
RUN ./mvnw dependency:go-offline -q

# Copy source code and build
COPY src/ src/
RUN ./mvnw package -DskipTests -q

### Stage 2 – Runtime ###
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /deployments

# Security: non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy Quarkus fast-jar layout
COPY --from=builder --chown=appuser:appgroup /build/target/quarkus-app/lib/ lib/
COPY --from=builder --chown=appuser:appgroup /build/target/quarkus-app/*.jar ./
COPY --from=builder --chown=appuser:appgroup /build/target/quarkus-app/app/ app/
COPY --from=builder --chown=appuser:appgroup /build/target/quarkus-app/quarkus/ quarkus/

EXPOSE 8080

ENV JAVA_OPTS="-Xms64m -Xmx256m -XX:+UseG1GC"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar quarkus-run.jar"]
