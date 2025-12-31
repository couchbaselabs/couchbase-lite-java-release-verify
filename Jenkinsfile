pipeline {
  agent none

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  parameters {
    string(name: 'CBL_VERSION', defaultValue: '4.0.2', description: 'Couchbase Lite version')
  }

  stages {
    stage('Verify Java release') {
      parallel {
        stage('macOS') {
          agent { label 'mob-e2e-mac-01' }
          stages {
            stage('Download macOS artifacts') {
              steps {
                checkout scm
                sh '''
                  set -euo pipefail
                  chmod +x verify_java.sh
                  ./verify_java.sh "$CBL_VERSION"
                '''
              }
            }
            stage('Run macOS tests') {
              steps {
                sh '''
                  set -euo pipefail
                  chmod +x run_tests.sh
                  ./run_tests.sh "$CBL_VERSION"
                '''
              }
            }
          }
        }

        stage('Debian') {
          agent { label 'mob-e2e-deb-01' }
          stages {
            stage('Download Debian artifacts') {
              steps {
                checkout scm
                sh '''
                  set -euo pipefail
                  chmod +x verify_java_debian.sh
                  ./verify_java_debian.sh "$CBL_VERSION"
                '''
              }
            }
            stage('Run Debian tests') {
              steps {
                sh '''
                  set -euo pipefail
                  chmod +x run_tests_debian.sh
                  ./run_tests_debian.sh "$CBL_VERSION"
                '''
              }
            }
          }
        }

        stage('Windows') {
          agent { label 'mob-e2e-win-01' }
          stages {
            stage('Download Windows artifacts') {
              steps {
                checkout scm
                powershell '''
                  $ErrorActionPreference = "Stop"
                  .\\verify_java_windows.ps1 $env:CBL_VERSION
                '''
              }
            }
            stage('Run Windows tests') {
              steps {
                powershell '''
                  $ErrorActionPreference = "Stop"
                  .\\run_tests_windows.ps1 $env:CBL_VERSION
                '''
              }
            }
          }
        }
      }
    }
  }
}
