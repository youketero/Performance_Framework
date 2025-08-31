pipeline {
    agent any

    stages {
        stage('Check kubectl') {
            steps {
                echo 'Checking kubectl'
                sh 'kubectl get pods -n default'
            }
        }
        stage('Checkout git') {
            steps {
                echo 'Downloading git repository'
                git branch: 'main', url: 'https://github.com/youketero/Performance_Framework.git'
            }
        }
        stage('Navigate to git folder') {
            steps {
                sh 'ls'
            }
        }	
		stage('Recreate performance namespace') {
            steps {
                script {
                    echo 'Recreating performance namespace...'
                    def exists = sh(script: "kubectl get ns | grep performance || true", returnStdout: true).trim()
                    dir('k8s_jmeter') {
                        sh 'kubectl apply -f namespace.yaml'
                    }
                    sh 'kubectl get ns performance'
					sleep 10
                }
            }
        }
        stage('Cleanup old ECK operator') {
            steps {
                script {
                    echo 'Checking if ECK operator exists...'
                    // Якщо є namespace elastic-system → видаляємо все
                    def exists = sh(script: "kubectl get ns | grep elastic-system || true", returnStdout: true).trim()
                    if (exists) {
                        echo "ECK operator detected, deleting..."
                        sh '''
                          kubectl delete -f https://download.elastic.co/downloads/eck/3.1.0/operator.yaml || true
                          kubectl delete -f https://download.elastic.co/downloads/eck/3.1.0/crds.yaml || true
                          kubectl delete ns elastic-system --ignore-not-found=true
                        '''
                        sh '''
                          kubectl delete crd elasticsearches.elasticsearch.k8s.elastic.co --ignore-not-found=true
                          kubectl delete crd kibanas.kibana.k8s.elastic.co --ignore-not-found=true
                          kubectl delete crd beats.beat.k8s.elastic.co --ignore-not-found=true
                          kubectl delete crd agents.agent.k8s.elastic.co --ignore-not-found=true
                          kubectl delete crd enterprisesearches.enterprisesearch.k8s.elastic.co --ignore-not-found=true
                          kubectl delete crd stackconfigpolicies.stackconfigpolicy.k8s.elastic.co --ignore-not-found=true
                        '''
                        echo "Old ECK operator deleted"
                    } else {
                        echo "No ECK operator found, skipping cleanup"
                    }
                    echo "Cleaning up old workloads (elasticsearch, kibana, logstash, filebeat)..."
                    sleep 30
                }
            }
        }
        stage('Deploying ECK orkestrator') {
            steps {
                echo 'deploying eck orcestrator' 
                sh 'kubectl create -f https://download.elastic.co/downloads/eck/3.1.0/crds.yaml'
                echo 'applying eck orkestrator'
                sh 'kubectl apply -f https://download.elastic.co/downloads/eck/3.1.0/operator.yaml' 
                echo 'applying ended waiting 5 seconds'
                sleep 5
                sh 'kubectl get -n elastic-system pods' 
            }
        }
        stage('Deploying elasticsearch') {
            steps {
                echo 'Deploying elasticsearch'
                dir('k8s_jmeter') {
                    sh 'kubectl apply -f elasticsearch.yaml'
                    sleep 5
                    sh 'kubectl wait --for=condition=ready pod -l elasticsearch.k8s.elastic.co/cluster-name=quickstart -n performance --timeout=180s'
                    echo 'Deploying ended'
                }
                script {
                    // отримуємо пароль з Kubernetes secret
                    def esPassword = sh(
                        script: "kubectl get secret quickstart-es-elastic-user -n performance -o go-template='{{.data.elastic | base64decode}}'",
                        returnStdout: true
                    ).trim()

                    // зберігаємо у середовищі Jenkins для подальшого використання
                    env.ES_PASSWORD = esPassword
                    sh "echo 'Elasticsearch password is: ${env.ES_PASSWORD}'"
                }
            }
        }
        stage('Deploying kibana') {
            steps {
                echo "echo"
                echo 'Deploying kibana'
                dir('k8s_jmeter') {
                    sh 'kubectl apply -f kibana.yaml'
                    sh 'kubectl wait --for=condition=ready pod -l elasticsearch.k8s.elastic.co/cluster-name=quickstart -n performance --timeout=180s'
                }
                echo 'Deploying ended'
            }
        }
         stage('Deploying logstash') {
            steps {
                echo "echo"
                echo 'Deploying logstash'
                dir('k8s_jmeter') {
                    sh 'kubectl apply -f logstash.yaml'
                    sh 'kubectl wait --for=condition=ready pod -l elasticsearch.k8s.elastic.co/cluster-name=quickstart -n performance --timeout=180s'
                }
                echo 'Deploying ended'
            }
        }
        stage('Deploying filebeat') {
            steps {
                echo "echo"
                echo 'Deploying filebeat'
                dir('k8s_jmeter') {
                    sh 'kubectl apply -f filebeat.yaml'
                    sh 'kubectl wait --for=condition=ready pod -l elasticsearch.k8s.elastic.co/cluster-name=quickstart -n performance --timeout=180s'
                }
                echo 'Deploying ended'
            }
        }
    }
}
