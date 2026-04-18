FROM maven:3.9-eclipse-temurin-11 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:11-jdk
WORKDIR /app

RUN apt-get update && apt-get install -y wget && \
    wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz && \
    tar -xzf apache-tomcat-9.0.85.tar.gz && \
    mv apache-tomcat-9.0.85 /opt/tomcat && \
    rm apache-tomcat-9.0.85.tar.gz

COPY --from=build /app/target/cafeteria.war /opt/tomcat/webapps/cafeteria.war

ENV PORT=8080
EXPOSE 8080

CMD ["/opt/tomcat/bin/catalina.sh", "run"]
