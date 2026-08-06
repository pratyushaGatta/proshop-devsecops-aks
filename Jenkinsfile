pipeline {
    agent any

    environment {
        ACR_NAME          = 'proshopacrzoyd3'
        ACR_LOGIN_SERVER  = 'proshopacrzoyd3.azurecr.io'
        AKS_RESOURCE_GROUP = 'rg-proshop-dev'
        AKS_CLUSTER_NAME   = 'aks-proshop-dev'
        IMAGE_NAME         = 'proshop-app'
        HELM_RELEASE       = 'proshop-dev'
        HELM_NAMESPACE     = 'proshop-dev'
        IMAGE_TAG          = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
                sh 'npm ci --prefix frontend'
            }
        }

        stage('Build Frontend') {
            steps {
                sh 'npm run build --prefix frontend'
            }
        }

        stage('Snyk Scan') {
            steps {
                withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                    sh '''
                        snyk auth "$SNYK_TOKEN"
                        snyk test --severity-threshold=high || true
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      --ignore-unfixed \
                      ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Azure Login') {
            steps {
                withCredentials([
                    string(credentialsId: 'azure-client-id', variable: 'AZURE_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'AZURE_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'AZURE_TENANT_ID'),
                    string(credentialsId: 'azure-subscription-id', variable: 'AZURE_SUBSCRIPTION_ID')
                ]) {
                    sh '''
                        az login \
                          --service-principal \
                          --username "$AZURE_CLIENT_ID" \
                          --password "$AZURE_CLIENT_SECRET" \
                          --tenant "$AZURE_TENANT_ID"

                        az account set \
                          --subscription "$AZURE_SUBSCRIPTION_ID"
                    '''
                }
            }
        }

        stage('Push Image to ACR') {
            steps {
                sh '''
                    az acr login --name ${ACR_NAME}
                    docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Connect to AKS') {
            steps {
                sh '''
                    az aks get-credentials \
                      --resource-group ${AKS_RESOURCE_GROUP} \
                      --name ${AKS_CLUSTER_NAME} \
                      --overwrite-existing
                '''
            }
        }

        stage('Helm Lint') {
            steps {
                withCredentials([
                    string(credentialsId: 'mongo-uri', variable: 'MONGO_URI'),
                    string(credentialsId: 'jwt-secret', variable: 'JWT_SECRET')
                ]) {
                    sh '''
                        helm lint ./helm/proshop \
                          --set-string secret.mongoUri="$MONGO_URI" \
                          --set-string secret.jwtSecret="$JWT_SECRET"
                    '''
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                withCredentials([
                    string(credentialsId: 'mongo-uri', variable: 'MONGO_URI'),
                    string(credentialsId: 'jwt-secret', variable: 'JWT_SECRET')
                ]) {
                    sh '''
                        helm upgrade --install ${HELM_RELEASE} ./helm/proshop \
                          --namespace ${HELM_NAMESPACE} \
                          --create-namespace \
                          --set image.repository=${ACR_LOGIN_SERVER}/${IMAGE_NAME} \
                          --set image.tag=${IMAGE_TAG} \
                          --set-string secret.mongoUri="$MONGO_URI" \
                          --set-string secret.jwtSecret="$JWT_SECRET"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl rollout status \
                      deployment/${HELM_RELEASE}-proshop \
                      --namespace ${HELM_NAMESPACE} \
                      --timeout=180s

                    kubectl get pods -n ${HELM_NAMESPACE}
                    kubectl get services -n ${HELM_NAMESPACE}
                    kubectl get hpa -n ${HELM_NAMESPACE}
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully. Image tag: ${IMAGE_TAG}"
        }

        failure {
            echo "Pipeline failed. Check the failed stage and console logs."
        }

        always {
            sh 'az logout || true'
        }
    }
}