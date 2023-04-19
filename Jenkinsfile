// This jenkins file is for Products Deployment 
// this consists of , build, tests, scans, image build, image push, deployments.

pipeline {
    agent any
    parameters {
        choice(name: 'scanOnly',
            choices: 'no\nyes',
            description: 'This will scan the application'
        )
        choice(name: 'buildOnly',
            choices: 'no\nyes',
            description: 'This will only build the Application'
        )
        choice(name: 'dockerPush',
            choices: 'no\nyes',
            description: 'This will trigger app build, docker build and docker push '
        )
        choice(name: 'deployToDev',
            choices: 'no\nyes',
            description: 'This will Deploy the app to Dev env'
        )
        choice(name: 'deployToTest',
            choices: 'no\nyes',
            description: 'This will Deploy the app to Test env'
        )
        choice(name: 'deployToStage',
            choices: 'no\nyes',
            description: 'This will Deploy the app to Stage env'
        )
        choice(name: 'deployToProd',
            choices: 'no\nyes',
            description: 'This will Deploy the app to Prod env'
        )
    }
    environment {
        APPLICATION_NAME = "learner-user"
        GIT_CREDS = credentials('learner_siva_git_creds')
        POM_VERSION = readMavenPom().getVersion()
        POM_PACKAGING = readMavenPom().getPackaging()
        DOCKER_CREDS = credentials('dockerhub_creds')
        DOCKER_HUB = "docker.io/devopswithcloudhub"
        DOCKER_REPO = "jenkinsspring"
        USER_NAME = "devopswithcloudhub"
    }
    tools {
        maven 'Maven-3.8.8'
        jdk 'JDK-17'
    }
    stages {
        stage ('Build') {
            when {
                anyOf {
                    expression {
                        params.dockerPush == 'yes'
                    }
                    expression {
                        params.buildOnly == 'yes'                      
                    }
                }
            }
            // Build happens here 
            steps {
                script {
                    buildApp().call()
                }
                // mvn clean package -DskipTests or mvn clean package -Dmaven.test.skip=true
            }
        }
        stage ('Unit Tests- Junit and Jacoco'){
            when {
                anyOf {
                    expression {
                        params.dockerPush == 'yes'
                        params.buildOnly == 'yes'
                    }
                }
            }
            steps {
                echo "Performing Unit tests for ${env.APPLICATION_NAME} application"
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }
        stage ('Sonar') {
            when {
                anyOf {
                    expression {
                        params.scanOnly == 'yes'
                        params.dockerPush == 'yes'
                        params.buildOnly == 'yes'
                    }
                }
            }
            steps {
                echo "Starting Sonar Scan"
                withSonarQubeEnv('SonarQube'){
                    sh """
                        mvn sonar:sonar \
                            -Dsonar.projectKey=learner-eureka \
                            -Dsonar.host.url=http://34.125.111.119:9000 \
                            -Dsonar.login=1856d46d17e67fbe26137d63aefaa95c92cd2eff
                    """
                    // -Dsonar.login=08cfc6b66ae7ed1ccbc136be3afd43496d3ab04e is optional, as we are 
                    // already using withSonarQubeEnv
                }
                timeout (time: 2, unit: 'MINUTES'){ // //values: NANOSECONDS, MICROSECONDS, MILLISECONDS, SECONDS, MINUTES, HOURS, DAYS
                    script {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        stage ('Docker Build and Push'){
            when {
                anyOf {
                    expression {
                        params.dockerPush == 'yes'
                    }
                }
            }
            steps {
                script { //learner-eureka-0.0.1-SNAPSHOT.jar
                    //git branch: ${BRANCH_NAME}, credentialsId: 'learner_siva_git_creds', url: 'https://github.com/varresiva/learner-eureka.git'
                    dockerBuildandPush().call() 
                }
            }
        }
        stage ('Deploy to Dev'){
            when {
                expression {
                    params.deployToDev == 'yes'
                }
            }
            steps {
                script {
                // dockerDeploy(env, portnumber)
                imageValidation().call()
                dockerDeploy('dev', '8000').call()
                }

            }
        }
        stage ('Deploy to Test'){
            when {
                expression {
                    params.deployToTest == 'yes'
                }
            }
            steps {
                script {
                    imageValidation().call()
                    dockerDeploy('tst', '8001').call()
                }
            }
        }
        stage ('Deploy to Stage'){
            when {
                expression {
                    params.deployToStage == 'yes'
                }
            }
            steps {
                script {
                    imageValidation().call()
                    dockerDeploy('stage', '8002').call()
                }
            }
        }
        stage ('Deploy to Prod'){
            when {
                allOf {
                    anyOf {
                        expression {
                            params.deployToProd == 'yes'
                        }
                    }
                    anyOf {
                            branch 'release-*'
                    }
                }

            }
            steps {
                timeout(time: 200, unit: 'SECONDS') {
                    input message: "Deploy to ${env.APPLICATION_NAME} ?? ", ok: 'yes', submitter: 'krish'
                }
                script {
                    imageValidation().call()
                    dockerDeploy('prod', '8003').call()
                }
            }
        }
        stage('Clean') {
            steps {
                cleanWs()
            }
        }
    }
 
}

def dockerDeploy(envDeploy, port) {
    return {
        echo "Deploying to $envDeploy env"
        echo "Docker hub is ${env.DOCKER_HUB}"
        withCredentials([usernamePassword(credentialsId: 'siva_docker_vm_passwd', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
            script {
                sh "sshpass -p '$PASSWORD' -v ssh -o StrictHostKeyChecking=no $USERNAME@$dev_ip \"docker pull ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:$GIT_COMMIT\""
                try {
                // If we execute the below command without try block it will fail for the first time, and if container is not avilable even
                echo "Stopping the Container"
                sh "sshpass -p '$PASSWORD' -v ssh -o StrictHostKeyChecking=no $USERNAME@$dev_ip \"docker stop ${env.APPLICATION_NAME}-$envDeploy\""
                echo "Docker removing the Container"
                sh "sshpass -p '$PASSWORD' -v ssh -o StrictHostKeyChecking=no $USERNAME@$dev_ip \"docker rm ${env.APPLICATION_NAME}-$envDeploy\""
                } catch (err) {
                    echo: 'Caught the error: $err'
                }
                sh "sshpass -p '$PASSWORD' -v ssh -o StrictHostKeyChecking=no $USERNAME@$dev_ip \"docker run --restart always --name ${env.APPLICATION_NAME}-$envDeploy -e JAVA_OPTS='-Dspring.profiles.active=dev -Dserver.port=8080' -p $port:8080 -d ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:$GIT_COMMIT\""
            }
        }
    }
}

def imageValidation () {
    return {
        println("Pulling the docker image")
        try {
            sh "docker pull ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:$GIT_COMMIT"
        }
        catch (Exception e) {
            println('OOPS, docker image with this tag is not available')
            buildApp().call()
            dockerBuildandPush().call()
        }
    }
}

def dockerBuildandPush() {
    return {
        echo "********************** Building Docker Image***************************"
        sh "cp ${workspace}/target/${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING} ./.cicd"
        sh "docker build --force-rm --no-cache --pull --rm=true --build-arg JAR_SOURCE=${env.APPLICATION_NAME}-${env.POM_VERSION}.${env.POM_PACKAGING} --build-arg JAR_DEST=${env.APPLICATION_NAME}-${currentBuild.number}-${BRANCH_NAME}.${env.POM_PACKAGING} \
            -t ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:$GIT_COMMIT  ./.cicd"
        echo "Pushing the image to repo"
        echo "******** Logging to Docker Registry********"
        sh "docker login ${env.DOCKER_HUB} -u ${DOCKER_CREDS_USR} -p ${DOCKER_CREDS_PSW}"
        sh "docker push ${env.DOCKER_HUB}/${env.APPLICATION_NAME}:$GIT_COMMIT"
    }
}
def buildApp() {
    return {
        echo "Building the ${env.APPLICATION_NAME} application"
        sh 'mvn clean package -DskipTests=true'
        archive 'target/*.jar'
    }
}