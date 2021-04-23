#!/bin/bash

export INPUT_REPOSITORY_OWNER="mondeja"
export INPUT_REPOSITORY_NAME="pr-linked-issues-action-testing"

function checkDependencies() {
  if [ "$(command -v "shunit2")" = "" ]; then
    printf "You need to install shunit2 or add it to PATH to run tests.\n" >&2
    exit 1
  fi;
}

function testNoLinkedPRs() {
  assertEquals "::set-output name=issues::" "$(INPUT_PULL_REQUEST=5 bash entrypoint.sh)"
}

function testLinkedPR() {
  assertEquals "::set-output name=issues::1" "$(INPUT_PULL_REQUEST=4 bash entrypoint.sh)"
}

function testLinkedPRs() {
  assertEquals "::set-output name=issues::1,2" "$(INPUT_PULL_REQUEST=3 bash entrypoint.sh)"
}

function main() {
  checkDependencies
  . shunit2
}

main
