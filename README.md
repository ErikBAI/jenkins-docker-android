# jenkins-docker-android
Docker based Jenkins build continuous integration and continuous delivery for Android apps

## install Docker Engine on CentOS
Please follow the official install guide: https://docs.docker.com/engine/install/centos/

## build Jenkins based docker for Android
### build docker based on jenkins official docker image
Build the jenkins image under the directory of Dockerfile:

  docker build -t jenkins:android-jdk11
	
Run the docker:

  docker run -d -p 8080:8080 -p 50000:50000 jenkins:android-jdk11

Login to docker image built just now via root user:

  docker exec -u 0  -ti DOCKER_IMAGE_ID /bin/bash

### config the Jenkins agent node
Setup Jenkins agent:

  cd /opt/
  sh entrypoint.sh

