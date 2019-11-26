#!/bin/bash
set -ex

################################################
# functions
################################################

function deploy_to_dockerhub(){
  echo "Deploy to docker hub"

  DOCKER_TAG=${1:-$TRAVIS_BRANCH}
  DBVTK_DEV_BRANCH=${2:-$TRAVIS_BRANCH}

  if [[ "$DOCKER_TAG" != "latest" ]]; then
    docker tag keeps/dbvtk:latest keeps/dbvtk:$TRAVIS_BRANCH
  fi

  # Push to https://hub.docker.com/r/keeps/dbvtk/
  docker push keeps/dbvtk:$DOCKER_TAG

  ## Docker App BETA
  #   curl -fsSL --output "/tmp/docker-app-linux.tar.gz" "https://github.com/docker/app/releases/download/v0.8.0-beta2/docker-app-linux.tar.gz"
  #   tar xf "/tmp/docker-app-linux.tar.gz" -C /tmp/
  #   sudo install -b "/tmp/docker-app-standalone-linux" /usr/local/bin/docker-app
    
  #   cd deploys/development
  #   docker-app inspect 
  #   docker-app push --tag keeps/dbvtk:$DOCKER_TAG
  #   cd $TRAVIS_BUILD_DIR

  # Trigger external builds
  if [ "$TRAVIS_BRANCH" == "staging" ]; then
    curl  --progress-bar -o /dev/null -L --request POST \
          --form ref=$DBVTK_DEV_BRANCH \
          --form token=$GITLAB_DBVTK_DEV_TRIGGER_TOKEN \
          --form "variables[DOCKER_TAG]=$DOCKER_TAG" \
          $GITLAB_DBVTK_DEV_TRIGGER
  fi
}

################################################
# Deploy
################################################

if [[ ! -z "$DOCKER_USERNAME" ]]; then
  # init
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

  if [ "$TRAVIS_BRANCH" == "master" ]; then
    echo "Logic for master branch"
    deploy_to_dockerhub "latest" "$TRAVIS_BRANCH"

  elif [ "$TRAVIS_BRANCH" == "staging" ]; then
    echo "Logic for staging branch"
    deploy_to_dockerhub "$TRAVIS_BRANCH" "staging"

  elif [ "`echo $TRAVIS_BRANCH | egrep "^v[1-9]+" | wc -l`" -eq "1" ]; then
    echo "Logic for tags"
    deploy_to_dockerhub "$TRAVIS_BRANCH" "master"
  fi

  # clean up
  docker logout
fi