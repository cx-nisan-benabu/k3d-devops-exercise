pipelineJob('K8s-Worker-Pod-Job') {
    triggers {
        cron('H/5 * * * *')
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent {
                        kubernetes {
                            defaultContainer 'psql-client'
                            yaml \"\"\"
                            apiVersion: v1
                            kind: Pod
                            metadata:
                              labels:
                                app: jenkins-worker
                            spec:
                              serviceAccountName: jenkins
                              containers:
                              - name: jnlp
                                image: jenkins/inbound-agent:latest
                                args: ['\\$(JENKINS_SECRET)', '\\$(JENKINS_NAME)']
                                tty: true
                              - name: psql-client
                                image: postgres:latest
                                command: ["sleep", "3600"]
                                tty: true
                                env:
                                  - name: PGPASSWORD
                                    valueFrom:
                                      secretKeyRef:
                                        name: postgresql-secret
                                        key: postgres-password
                            \"\"\"
                        }
                    }

                    stages {
                        stage('Insert Timestamp to DB') {
                            steps {
                                sh """
                                    echo "🚀 Connecting to PostgreSQL..."
                                    psql -h postgresql.default.svc.cluster.local -U postgres -d devops -c "INSERT INTO logs (timestamp) VALUES (NOW());"
                                    echo "✅ Data successfully inserted into PostgreSQL."
                                """
                            }
                        }
                    }
                }
            ''')
        }
    }
}
