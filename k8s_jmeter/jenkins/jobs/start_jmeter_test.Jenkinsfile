properties([[$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false], 
    parameters([string(defaultValue: 'Google_basic.jmx', description: 'Select .jmx file that need to be executed', name: 'jmxFile', trim: true), 
    string(defaultValue: 'performance', description: 'Select namespace from which services will be deleted', name: 'Namespace', trim: true)])])

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
                   def masterPod = sh(script: """kubectl get pod -n ${params.Namespace} -l jmeter_mode=master -o jsonpath="{.items[0].metadata.name}" """,returnStdout: true).trim()
                   def slavePods = sh(script: "kubectl get pod -n ${params.Namespace} -l jmeter_mode=slave -o jsonpath='{range.items[*]}{.metadata.name} {end}'", returnStdout: true).trim().split(" ")
                   def filePath= sh(script: "find /var/jenkins_home/workspace/start_jmeter_test -name ${jmxFile} | head -n 1", returnStdout: true).trim()
                   def jmeterDir = sh(script: """kubectl exec -n ${params.Namespace} -c jmmaster ${masterPod} -- sh -c 'find /opt -maxdepth 1 -type d -name "apache-jmeter*" | head -n1' """,, returnStdout: true).trim() 
                   echo "--------- Copying ${filePath} into ${slavePods} ---------"
                   writeFile file: 'jmeter_injector_start.sh', text: """cd ${jmeterDir}
trap 'exit 0' SIGUSR1
jmeter-server -Dserver.rmi.localport=50000 -Dserver_port=1099 -Jserver.rmi.ssl.disable=true >> jmeter-injector.out 2>> jmeter-injector.err &
wait
"""
                   def injPath = sh(script: "find /var/jenkins_home/workspace/start_jmeter_test -name jmeter_injector_start.sh | head -n 1", returnStdout: true).trim()
                   slavePods.each{  pod ->
                       sh """kubectl cp -c jmslave "${filePath}" -n "${params.Namespace}" "${pod}:${jmeterDir}/bin/" """
                       sh """kubectl cp -c jmslave "${injPath}" -n "${params.Namespace}" "${pod}:${jmeterDir}" """
                       sh """kubectl exec -c jmslave -i -n "${params.Namespace}" "${pod}" -- //bin/bash "${jmeterDir}/jmeter_injector_start.sh" &"""
                   }
                   echo "--------- Copying ${filePath} into ${masterPod} ---------"
                   def slavePodsStr = sh(script: """kubectl -n "${params.Namespace}" get endpoints jmeter-slaves-svc -o jsonpath='{.subsets[*].addresses[*].ip}' | tr ' ' ','""",returnStdout: true).trim()
                   echo "${slavePodsStr}"
                   sh """kubectl cp -c jmmaster "${filePath}" -n "${params.Namespace}" "${masterPod}:${jmeterDir}/bin/" """
                   writeFile file: 'load_test.sh', text: """chmod +x '${jmeterDir}/load_test.sh'
trap 'exit 0' SIGUSR1
jmeter -n -t ${jmeterDir}/bin/${params.jmxFile} -l /jmeter/report_${params.jmxFile}_\$(date +"%F_%H%M%S").csv -Dserver.rmi.ssl.disable=true --remoteexit --remotestart ${slavePodsStr} >> jmeter-master.out 2>> jmeter-master.err &
wait
"""                
                   def loadTestPath = sh(script: "find /var/jenkins_home/workspace/start_jmeter_test -name load_test.sh | head -n 1", returnStdout: true).trim()
                   sh """kubectl cp -c jmmaster "${loadTestPath}" -n ${params.Namespace} ${masterPod}:${jmeterDir}/load_test.sh"""
                   sh """kubectl exec -c jmmaster -n ${params.Namespace} ${masterPod} -- /bin/bash  "${jmeterDir}/load_test.sh" """
                }
            }
        }
    }
}
