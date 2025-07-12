# resource-server/Dockerfile

FROM maven:3.8.7-amazoncorretto-17 AS build
WORKDIR /app
COPY mytrainer2/pom.xml ./
RUN mvn dependency:go-offline
COPY mytrainer2/src ./src
RUN mvn package -DskipTests

FROM amazoncorretto:17
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

COPY wait-for-it.sh /app/wait-for-it.sh
RUN chmod +x /app/wait-for-it.sh

# Switch to CMD (instead of ENTRYPOINT)
# so that docker-compose.yml's 'command:' will override it
CMD ["java", "-jar", "app.jar"]

EXPOSE 8080
