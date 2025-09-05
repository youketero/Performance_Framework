pipeline {
    agent any

    stages {
        stage('download git repository') {
            steps {
                git branch: 'main', url: 'https://github.com/youketero/Performance_Framework'
            }
        }
        stage('start sh script') {
            steps {
                sh "cd k8s_jmeter && ls && chmod +x start_test.sh && ./start_test.sh -j Google_basic.jmx -n performance -m -i 3 -r"
            }
        }
    }
}
