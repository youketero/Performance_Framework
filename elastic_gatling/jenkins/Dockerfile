FROM jenkins/jenkins:latest

ARG JOB_NAME=gatling
  
ENV JAVA_OPTS="-Dpermissive-script-security.enabled=true -Djenkins.install.runSetupWizard=false -Dhudson.model.DirectoryBrowserSupport.CSP=''"

RUN mkdir -p /var/jenkins_home/workspace/${JOB_NAME} && mkdir -p /var/jenkins_home/jobs/${JOB_NAME} 
COPY /jobs/${JOB_NAME}.xml /var/jenkins_home/jobs/${JOB_NAME}/config.xml
RUN mkdir -p /var/jenkins_home/jobs/${JOB_NAME}/latest/ && mkdir -p /var/jenkins_home/jobs/${JOB_NAME}/builds/1/ 

COPY ${JOB_NAME}.ndjson /var
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml

USER root
COPY casc.yaml /var/jenkins_home/casc.yaml
RUN apt-get -y update && \
apt-get -y install sudo && \
sudo usermod -aG staff jenkins && \
echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
ENV PATH "$PATH:/usr/local/bin/dind/"

