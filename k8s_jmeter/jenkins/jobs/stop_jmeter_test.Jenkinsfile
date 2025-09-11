properties([[$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false], 
    parameters([string(defaultValue: 'performance', description: 'Select namespace from which services will be deleted', name: 'Namespace', trim: true)])])

pipeline {
    agent any

    stages {
        stage('Stop Jmeter test') {
            steps {
                script{
                    def masterPod = sh(script: """kubectl get pod -n ${params.Namespace} -l jmeter_mode=master -o jsonpath="{.items[0].metadata.name}" """,returnStdout: true).trim()
                    def jmeterDir = sh(script: """kubectl exec -n ${params.Namespace} -c jmmaster ${masterPod} -- sh -c 'find /opt -maxdepth 1 -type d -name "apache-jmeter*" | head -n1' """,, returnStdout: true).trim() 
                    sh """kubectl exec -c jmmaster -n ${params.Namespace} ${masterPod} -- /bin/bash  "${jmeterDir}/bin/stoptest.sh" """
                }
            }
        }
    }
}
