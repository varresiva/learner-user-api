#! /bin/bash
echo "Starting Learner User API"
cd /opt/learner
exec java ${JAVA_OPTS} -jar ./*.jar