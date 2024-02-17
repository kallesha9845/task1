# Stage 1: Build with Maven and JDK
# Use Eclipse Temurin image with JDK 17
FROM eclipse-temurin:17-jdk-jammy AS build

# Set the working directory to /app
WORKDIR /app

# Copy the .mvn folder and Maven wrapper to the image
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Resolve all dependencies
RUN ./mvnw dependency:resolve

# Copy the source code to the image
COPY src ./src

# Build the project and package the jar to the local repository
RUN ./mvnw clean package -Dmaven.test.skip=true

# Stage 2: Run with JRE
# Use Eclipse Temurin image with JRE 17
FROM eclipse-temurin:17-jre-jammy

# Set the working directory to /app
WORKDIR /app

# Copy the jar file from the build stage to the current stage
COPY --from=build /app/target/*.jar app.jar

# Set the entry point of the container to the jar file
ENTRYPOINT ["java","-jar","app.jar"]