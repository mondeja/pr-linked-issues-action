#!/bin/sh

REPOSITORY_OWNER="$INPUT_REPOSITORY_OWNER"
REPOSITORY_NAME="$INPUT_REPOSITORY_NAME"
PULL_REQUEST="$INPUT_PULL_REQUEST"


prepareInputs() {
  if [ -z "$REPOSITORY_OWNER" ]; then
    REPOSITORY_OWNER=$(cat "$GITHUB_EVENT_PATH" | jq -r ".repository.owner.login")
  fi;

  if [ -z "$REPOSITORY_NAME" ]; then
    REPOSITORY_NAME=$(cat "$GITHUB_EVENT_PATH" | jq -r ".repository.name")
  fi;

  if [ -z "$PULL_REQUEST" ]; then
    PULL_REQUEST=$(cat "$GITHUB_EVENT_PATH" | jq ".number")
    if [ "$PULL_REQUEST" = "null" ]; then
      printf "PR number can't be retrieved from event data.\n" >&2
      printf "You must define a pull request number using 'pr_number' input or"
      printf " execute the action using a pull request event.\n"
      exit 1
    fi;
  fi;
}


main() {
  prepareInputs

  script="query{repository(name:\\\"$REPOSITORY_NAME\\\",owner:\\\"$REPOSITORY_OWNER\\\"){pullRequest(number:$PULL_REQUEST){closingIssuesReferences(first:100){nodes{number}}}}}"
  response="$(curl -s -H 'Content-Type: application/json' \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -X POST -d "{ \"query\": \"$script\"}" https://api.github.com/graphql)"
  echo ::set-output name=issues::$(echo $response \
    | jq .data.repository.pullRequest.closingIssuesReferences.nodes[].number? \
    | tr "\n" "," | sed 's/,$//')
}


main
