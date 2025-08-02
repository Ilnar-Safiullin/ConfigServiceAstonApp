# Build stage (используем JDK для сборки)
FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /app

# Копируем только необходимые файлы для ускорения сборки
COPY pom.xml mvnw ./
COPY .mvn/ .mvn/
RUN ./mvnw dependency:go-offline -B

# Копируем исходный код и собираем
COPY src/ src/
RUN ./mvnw clean package -DskipTests

# Runtime stage (используем JRE для уменьшения размера)
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Копируем JAR из стадии сборки
COPY --from=builder /app/target/ConfigServer-*.jar app.jar

# Настройки (можно переопределить через docker-compose)
ENV SPRING_PROFILES_ACTIVE=docker \
    SPRING_CLOUD_CONFIG_SERVER_GIT_URI=https://github.com/Ilnar-Safiullin/ConfigSavePublicAston \
    SPRING_CLOUD_CONFIG_SERVER_GIT_DEFAULT-LABEL=master

EXPOSE 8888

# Healthcheck для docker-compose
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8888/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]