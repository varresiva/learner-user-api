FROM openjdk:18.0.2.1-jdk
ARG JAR_DEST
ENV JAR_DEST ${JAR_DEST}
ARG JAR_SOURCE
ENV JAR_SOURCE ${JAR_SOURCE}
# environment variable with default value
ENV SPRING_PROFILE=dev
ENV JAVA_OPTS default
RUN mkdir -p /opt/learner/
# COPY ["${JAR_SOURCE}", "/opt/learner/${JAR_DEST}"]
COPY ["${JAR_SOURCE}", "/opt/learner/learner-product.jar"]
COPY ["startup.sh", "/opt/learner/"]
RUN chmod 777 /opt/learner/
RUN chmod 777 /opt/learner/*.sh
WORKDIR /opt/learner
EXPOSE 8080
USER root
#CMD java -jar $JAR_DEST 
#CMD ["java", "-jar", "/opt/learner/$JAR_DEST"]
#CMD ["java", "-jar", "/opt/learner/learner-eureka.jar"]
CMD ["/opt/learner/startup.sh"]



# docker run -p 8000:80 --rm -e SPRING_PROFILE=dockerdev demo-app