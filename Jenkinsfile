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
        stage('Download macOS artifacts') {
            agent { label 'mob-e2e-mac-01' }
            options {
              lock("mob-e2e-mac-01")
            }
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
          agent { label 'mob-e2e-mac-01' }
          options {
            lock("mob-e2e-mac-01")
          }
          steps {
            sh '''
              set -euo pipefail
              chmod +x run_tests.sh
              ./run_tests.sh "$CBL_VERSION"
            '''
          }
        }

        stage('Download Debian artifacts') {
          agent { label 'mob-e2e-deb-02' }
          options {
            lock("mob-e2e-deb-02")
          }
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
          agent { label 'mob-e2e-deb-02' }
          options {
            lock("mob-e2e-deb-02")
          }
          steps {
            sh '''
              set -euo pipefail
              chmod +x run_tests_debian.sh
              ./run_tests_debian.sh "$CBL_VERSION"
            '''
          }
        }

        stage('Download Windows artifacts') {
          agent { label 'mob-e2e-win-01' }
          options {
            lock("mob-e2e-win-01")
          }
          steps {
            checkout scm
            powershell '''
              $ErrorActionPreference = "Stop"
              .\\verify_java_windows.ps1 $env:CBL_VERSION
            '''
          }
        }
        stage('Run Windows tests') {
          agent { label 'mob-e2e-win-01' }
          options {
            lock("mob-e2e-win-01")
          }
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
