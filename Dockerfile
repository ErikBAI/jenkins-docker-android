# ====================================================================== #
# Dockerfile for Jenkins and Android project
# ====================================================================== #

# Base image
# ---------------------------------------------------------------------- #
# Jenkins master: jenkinsci/blueocean
# Jenkins agent: jenkins/jenkins
# Jenkins docker image with JDK-11 ready
#ARG JENKINS_TAG=lts-jdk11
FROM jenkins/jenkins:lts

# Author
# ---------------------------------------------------------------------- #
LABEL maintainer "erik.bai@outlook.com"

# set the environment variables
ENV TZ Asia/Shanghai
#ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

ARG javaUrl=https://download.java.net/java/ga/jdk11/openjdk-11_linux-x64_bin.tar.gz
ENV JAVA_URL ${javaUrl}
ENV JAVA_HOME /opt/java/openjdk
ENV PATH ${PATH}:${JAVA_HOME}/bin

ARG GRADLE_VERSION=7.0.2
ENV GRADLE_USER_HOME /.gradle
ENV GRADLE_HOME /opt/gradle
ENV PATH ${PATH}:${GRADLE_HOME}/bin

ARG ANDROID_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV ANDROID_VERSION 31
ENV ANDROID_TOOLS_VERSION 31.0.0
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/platform-tools
#ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/emulator


USER root

## Install requirements
# RUN dpkg --add-architecture i386
# RUN rm -rf /var/lib/apt/list/* && apt-get update && apt-get install ca-certificates curl gnupg2 software-properties-common git unzip file apt-utils lxc procps apt-transport-https libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y


# support multiarch: i386 architecture
# install essential tools
RUN apt-get update \
	&& apt-get install -y --no-install-recommends curl ca-certificates fontconfig locales unzip git wget procps vim \
	&& echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/*

#ARG DEBIAN_FRONTEND=noninteractive
#RUN dpkg --add-architecture i386 && \
#    apt-get update && \
#    apt-get dist-upgrade -y && \
#    echo 'debconf debconf/frontend select noninteractive' | debconf-set-selections && \
#    apt-get install -y --no-install-recommends --assume-yes apt-utils sudo dialog && \
#    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 zlib1g:i386 && \
#    apt-get install -y --no-install-recommends openjdk-${JDK_VERSION}-jdk && \
#    apt-get install -y --no-install-recommends git curl wget unzip procps vim && \
#    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# download and install Java
RUN echo "Downloading Java..." \
	&& curl -Lo jdk.tar.gz ${JAVA_URL} \
	&& tar xzf jdk.tar.gz \
	&& rm jdk.tar.gz \
	&& mkdir -p /opt/java \
	&& mv jdk-* ${JAVA_HOME}

# download and install Gradle
# https://services.gradle.org/distributions/
RUN set -o errexit -o nounset \
	&& echo "Downloading Gradle..." \
	&& curl -Lo gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
	&& echo "Installing Gradle..." \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
#	&& ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
	&& echo "Testing Gradle installation..." \
	&& gradle --version
#RUN cd /opt && \
#    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-${GRADLE_DIST}.zip && \
#    unzip gradle*.zip && \
#    ls -d */ | sed 's/\/*$//g' | xargs -I{} mv {} gradle && \
#    rm gradle*.zip

# .gradle and .android are a cache folders
RUN mkdir -p ${GRADLE_USER_HOME}/caches /.android \
	&& chmod -R 777 ${GRADLE_USER_HOME} \
	&& chmod 777 /.android


# download and install Android SDK
# https://developer.android.com/studio#command-tools
#RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
#    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_TOOL_VERSION}_latest.zip && \
#    unzip *tools*linux*.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
#    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/tools && \
#    rm *tools*linux*.zip


# Download Android SDK\
RUN mkdir -p ${ANDROID_SDK_ROOT} && cd "$ANDROID_SDK_ROOT" \
    && curl -o sdk.zip $ANDROID_TOOLS_URL \
    && unzip sdk.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/tools \
    && rm sdk.zip \
    && mkdir -p "$ANDROID_SDK_ROOT/licenses" || true \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_SDK_ROOT/licenses/android-sdk-license" \
    && sdkmanager --version \
    && yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
    && sdkmanager "platforms;android-${ANDROID_VERSION}" \
    && sdkmanager "platform-tools" \
    && sdkmanager "build-tools;${ANDROID_TOOLS_VERSION}"


# Now download the android SDK stuff
#RUN $ANDROID_SDK_ROOT/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --update
#RUN $ANDROID_SDK_ROOT/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
#    "platforms;android-${ANDROID_VERSION}" \
#    "platform-tools"



# RUN echo $PATH
# accept the license agreements of the SDK components
# ADD license_accepter.sh /opt/
# RUN chmod +x /opt/license_accepter.sh && /opt/license_accepter.sh $ANDROID_SDK_ROOT

## Install Android SDK into Image
# ADD $GRADLE_ZIP_URL /opt/
# RUN unzip /opt/$GRADLE_ZIP -d /opt/ && rm /opt/$GRADLE_ZIP

# ADD $ANDROID_SDK_ZIP_URL /opt/
# RUN unzip -q /opt/$ANDROID_SDK_ZIP -d $ANDROID_SDK_ROOT && rm /opt/$ANDROID_SDK_ZIP

RUN chown -R jenkins $ANDROID_SDK_ROOT

COPY agent.jar /opt/
COPY entrypoint.sh /opt/
RUN chown jenkins /opt/entrypoint.sh && chmod +x /opt/entrypoint.sh

## Install Jenkins plugin
USER jenkins

#RUN /bin/bash -c "source /etc/profile"
#RUN echo "source /etc/profile" >> ~/.bashrc

#RUN /usr/local/bin/install-plugins.sh git gradle ws-cleanup embeddable-build-status jacoco locale
RUN jenkins-plugin-cli --plugins git gradle ws-cleanup jacoco
WORKDIR $JENKINS_HOME

## Connect Jenkins agent to Jenkins master
# ARG JENKINS_JNLPURL http://10.24.61.200:8080/computer/SH-ZNZC-1/jenkins-agent.jnlp
# ARG JENKINS_KEY a555e3076e55b58579bf83cc64124fa0247c9a77e85bb064910cae534340bcb8
# ARG JENKINS_DIR /var/jenkins_home/workspace
#ENTRYPOINT "/opt/entrypoint.sh"
#RUN java -jar /opt/agent.jar -jnlpUrl ${JENKINS_JNLPURL} -secret ${JENKINS_KEY} -workDir ${JENKINS_DIR} >${JENKINS_DIR}/agent.log 2>&1 &