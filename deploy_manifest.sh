#!/bin/bash
docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORT"
docker pull $REPO-s390x:$TRAVIS_BUILD_NUMBER
docker pull $REPO-amd64:$TRAVIS_BUILD_NUMBER
docker manifest create "$REPO:$PUBTAG" "${REPO}-s390x:${TRAVIS_BUILD_NUMBER}" "${REPO}-amd64:${TRAVIS_BUILD_NUMBER}"
docker manifest annotate --arch=s390x --os=linux "${REPO}:${TRAVIS_BUILD_NUMBER}" "${REPO}-s390x:${TRAVIS_BUILD_NUMBER}"
docker manifest annotate --arch=amd64 --os=linux "${REPO}:${TRAVIS_BUILD_NUMBER}" "${REPO}-amd64:${TRAVIS_BUILD_NUMBER}"
docker manifest inspect "${REPO}:${PUBTAG}"
docker manifest push -p "${REPO}:${PUBTAG}"
docker logout