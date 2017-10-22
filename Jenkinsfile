#!/usr/bin/env groovy

pipeline {
  agent {
    dockerfile true
  }
  stages {
    stage("Prepare") {
      steps {
        checkout scm
        sh "gem install bundler"
        sh "bundle install"
      }
    }
    stage("Build") {
      steps {
        sh "bundle exec rake"
      }
    }
    stage("Archive") {
      steps {
        archiveArtifacts artifacts: 'pkg/*.gem', fingerprint: true
        juint 'test/reports/**/*.xml'
      }
    }
  }
}