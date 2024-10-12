FROM openjdk:11

ARG JMETER_VERSION="5.1"
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_DOWNLOAD_URL  https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

# download and extract JMeter
RUN mkdir /tmp/dependencies
RUN mkdir /opt/results
RUN	curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz

RUN tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt && \
    rm -rf /tmp/dependencies

# Set global PATH such that "jmeter" command is found
ENV PATH $PATH:$JMETER_BIN

COPY plugins/lib/*.jar ${JMETER_HOME}/lib/
COPY plugins/lib/ext/*.jar ${JMETER_HOME}/lib/ext/
COPY jmeter.sh ${JMETER_HOME}/bin/
COPY elasticapm.properties ${JMETER_HOME}/bin/
COPY elastic-apm-agent-1.15.0.jar ${JMETER_HOME}/bin/

COPY entrypoint.sh /
RUN chmod a+x ./entrypoint.sh
WORKDIR	${JMETER_HOME}

ENTRYPOINT ["/entrypoint.sh"]
