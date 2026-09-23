FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

COPY mvnw .
COPY .mvn/ .mvn/
COPY pom.xml .

RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline

COPY src/ src/

RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Maven output is in the target/ directory
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]