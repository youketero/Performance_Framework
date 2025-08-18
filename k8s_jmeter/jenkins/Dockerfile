FROM jenkins/jenkins:lts

ARG JOB_NAME=jmeter

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.model.DirectoryBrowserSupport.CSP=''"


COPY ${JOB_NAME}.ndjson /var
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

RUN mkdir -p /var/jenkins_home/workspace/${JOB_NAME} && mkdir -p /var/jenkins_home/jobs/${JOB_NAME} 
COPY /jobs/${JOB_NAME}.xml /var/jenkins_home/jobs/${JOB_NAME}/config.xml
RUN mkdir -p /var/jenkins_home/jobs/${JOB_NAME}/latest/ && mkdir -p /var/jenkins_home/jobs/${JOB_NAME}/builds/1/ 

COPY casc.yaml /usr/share/jenkins/ref/casc.yaml
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc.yaml

USER root
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*

ENV KUBECTL_VERSION=v1.32.0
RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

USER jenkins