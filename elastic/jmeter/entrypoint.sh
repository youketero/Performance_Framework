#!/bin/bash
bash ./bin/jmeter.sh -n -t ${SCENARIO} -j ${WORKSPACE}/jmeter_${BUILD_NUMBER}.log -l ${WORKSPACE}/report_${BUILD_NUMBER}.csv -e -o ${WORKSPACE}/report_${BUILD_NUMBER}/ ${PARAMETERS} -f