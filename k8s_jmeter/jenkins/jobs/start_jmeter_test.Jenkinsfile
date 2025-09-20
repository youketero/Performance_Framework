properties([[$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false], 
    parameters([string(defaultValue: 'performance', description: 'Select namespace from which services will be deleted', name: 'NAMESPACE', trim: true),
    string(defaultValue: 'Google_basic.jmx', description: 'Select .jmx file that need to be executed', name: 'JMX_FILE', trim: true), 
    string(defaultValue: '10', description: 'Select number of virtual threads', name: 'THREADS', trim: true),
    string(defaultValue: '10', description: 'Fill ramp up period in sec', name: 'RAMP_UP', trim: true),
    string(defaultValue: '120', description: 'Fill test duration in sec', name: 'DURATION', trim: true),
    string(defaultValue: 'TEST_DELAY:10', description: 'Add custom parameter in format param:value separated by comma' , name: 'CUSTOM_PARAMETERS', trim: true),
    ])])

pipeline {
    agent any
    stages {
        stage('Download Git Repository') {
            steps {
                git(
                    branch: 'main',
                    url: 'https://github.com/youketero/Performance_Framework'
                )
            }
        }
        stage('Start jmeter test') {
            steps {
                script{
                   echo "--------- Getting needed parameters ---------"
                   def masterPod = sh(script: """kubectl get pod -n ${params.NAMESPACE} -l jmeter_mode=master -o jsonpath="{.items[0].metadata.name}" """,returnStdout: true).trim()
                   def slavePods = sh(script: "kubectl get pod -n ${params.NAMESPACE} -l jmeter_mode=slave -o jsonpath='{range.items[*]}{.metadata.name} {end}'", returnStdout: true).trim().split(" ")
                   def filePath= sh(script: "find /var/jenkins_home/workspace/start_jmeter_test -name ${JMX_FILE} | head -n 1", returnStdout: true).trim()
                   def jmeterDir = sh(script: """kubectl exec -n ${params.NAMESPACE} -c jmmaster ${masterPod} -- sh -c 'find /opt -maxdepth 1 -type d -name "apache-jmeter*" | head -n1' """,, returnStdout: true).trim() 
                   echo "--------- Copying ${filePath} into ${slavePods} ---------"
                   writeFile file: 'jmeter_injector_start.sh', text: """cd ${jmeterDir}
trap 'exit 0' SIGUSR1
jmeter-server -Dserver.rmi.localport=50000 -Dserver_port=1099 -Jserver.rmi.ssl.disable=true >> jmeter-injector.out 2>> jmeter-injector.err &
wait
"""
                   def injPath = sh(script: "find /var/jenkins_home/workspace/start_jmeter_test -name jmeter_injector_start.sh | head -n 1", returnStdout: true).trim()
                   slavePods.each{  pod ->
                       sh """kubectl cp -c jmslave "${filePath}" -n "${params.NAMESPACE}" "${pod}:${jmeterDir}/bin/" """
                       sh """kubectl cp -c jmslave "${injPath}" -n "${params.NAMESPACE}" "${pod}:${jmeterDir}" """
                       sh """kubectl exec -c jmslave -i -n "${params.NAMESPACE}" "${pod}" -- //bin/bash "${jmeterDir}/jmeter_injector_start.sh" &"""
                   }
                   echo "--------- Copying ${filePath} into ${masterPod} ---------"
                   def slavePodsStr = sh(script: """kubectl -n "${params.NAMESPACE}" get endpoints jmeter-slaves-svc -o jsonpath='{.subsets[*].addresses[*].ip}' | tr ' ' ','""",returnStdout: true).trim()
                   echo "IP of jmeter slave pods ----- ${slavePodsStr} -------"
                   sh """kubectl cp -c jmmaster "${filePath}" -n "${params.NAMESPACE}" "${masterPod}:${jmeterDir}/bin/" """
                   custom_params = change_custom_parameter(params.CUSTOM_PARAMETERS)
                   writeFile file: 'load_test.sh', text: """chmod +x '${jmeterDir}/load_test.sh'
trap 'exit 0' SIGUSR1
jmeter -n -t ${jmeterDir}/bin/${params.JMX_FILE} -l /jmeter/report_${params.JMX_FILE}_\$(date +"%F_%H%M%S").csv -j /jmeter/report_${params.JMX_FILE}_\$(date +"%F_%H%M%S").jtl -GDURATION=${params.DURATION} -GTHREADS=${params.THREADS} -GRAMP_UP=${params.RAMP_UP} ${custom_params} -Dserver.rmi.ssl.disable=true --remoteexit --remotestart ${slavePodsStr} >> jmeter-master.out 2>> jmeter-master.err &
wait
"""                
                   uploadCsvToPods(slavePods, NAMESPACE, jmeterDir, slavePods.size())
                   def loadTestPath = sh(script: "find /var/jenkins_home/workspace/start_jmeter_test -name load_test.sh | head -n 1", returnStdout: true).trim()
                   sh """kubectl cp -c jmmaster "${loadTestPath}" -n ${params.NAMESPACE} ${masterPod}:${jmeterDir}/load_test.sh"""
                   sh """kubectl exec -c jmmaster -n ${params.NAMESPACE} ${masterPod} -- /bin/bash  "${jmeterDir}/load_test.sh" """
                }
            }
        }
        stage('Cleanup') {
            steps {
                cleanWs()
            }
        }
    }
}

def uploadCsvToPods(slavePods, namespace, jmeterDir, slaveNum) {
                    def csv_raw_split = sh(script: "find '${env.WORKSPACE}' -name '*.csv' ! -name '*_nosplit*.csv' || true",returnStdout: true).trim()
                    def csvFiles_split = csv_raw_split ? csv_raw_split.split("\n").findAll { it?.trim() } : []
                    if (csvFiles_split && csvFiles_split.size() > 0) {
                        csvFiles_split.each { csv ->
                        def linesTotal = sh(script: "wc -l < '${csv}'", returnStdout: true).trim().toInteger()
                        def linesPerSplit = ((linesTotal + 3 - 1) / 3).toInteger()
                        echo "${linesTotal}"
                        
                        sh "split --suffix-length=2 -d -l ${linesPerSplit} '${csv}' '${csv}.'"
                        def copyCommands = []
                        for (int i = 0; i < 3; i++) {
                            def j = String.format("%02d", i)
                            def splitFile = "${csv}.${j}"
                            def pod = slavePods[i]
                            def csvFile = csv.split("/")[-1]
                            sh(script: "kubectl -n ${namespace} cp -c jmslave '${splitFile}' ${pod}:${jmeterDir}/bin/${csvFile}", returnStdout: true).trim()
                            echo "INFO: Copying ${splitFile} to ${pod}:${jmeterDir}/${csvFile}"
                        }
                    }
                    } else {
                        echo "Not found files for splitting"
                    }
                    def csv_raw_split_nosplit = sh(script: "find '${WORKSPACE}' -name '*.csv' | grep '_nosplit' || true",returnStdout: true).trim()
                    def csvFiles_no_split = csv_raw_split_nosplit ? csv_raw_split_nosplit.split("\n").findAll { it?.trim() } : []
                    if (csvFiles_no_split && csvFiles_no_split.size() > 0) {
                            csvFiles_no_split.each { csv ->
                            for (int i = 0; i < 3; i++) {
                                 def pod = slavePods[i]
                                def csvFile = csv.split("/")[-1]
                                sh(script: "kubectl -n ${namespace} cp -c jmslave '${csv}' ${pod}:${jmeterDir}/bin/${csvFile}", returnStdout: true).trim()
                                echo "INFO: Copying ${csv} to ${pod}:${jmeterDir}/${csvFile}"
                            }
                    }
                    } else {
                        echo "Not found csv files "
                    }
    echo "INFO: Finished uploading CSV files to all slaves"
}

def change_custom_parameter(custom_parameter){
    def splittedParameters = custom_parameter.split(",")
    def parameterLine = ""
    splittedParameters.each{ parameter -> 
        parameters = parameter.split(":")
        parameterLine += " -G" + parameters[0] + "=" + parameters[1]
    }
    return parameterLine
}
