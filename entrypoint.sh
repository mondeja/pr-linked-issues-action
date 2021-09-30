#!/bin/sh

REPOSITORY_OWNER="$INPUT_REPOSITORY_OWNER"
REPOSITORY_NAME="$INPUT_REPOSITORY_NAME"
PULL_REQUEST="$INPUT_PULL_REQUEST"


prepareInputs() {
  if [ -z "$REPOSITORY_OWNER" ]; then
    REPOSITORY_OWNER=$(cat "$GITHUB_EVENT_PATH" | jq -r ".repository.owner.login")
  fi

  if [ -z "$REPOSITORY_NAME" ]; then
    REPOSITORY_NAME=$(cat "$GITHUB_EVENT_PATH" | jq -r ".repository.name")
  fi

  if [ -z "$PULL_REQUEST" ]; then
    PULL_REQUEST=$(cat "$GITHUB_EVENT_PATH" | jq ".number")
    if [ "$PULL_REQUEST" = "null" ]; then
      printf "PR number can't be retrieved from event data.\n" >&2
      printf "You must define a pull request number using 'pr_number' input or"
      printf " execute the action using a pull request event.\n"
      exit 1
    fi
  fi
}

get_issues() {
  script="query{repository(name:\\\"$REPOSITORY_NAME\\\",owner:\\\"$REPOSITORY_OWNER\\\"){pullRequest(number:$PULL_REQUEST){closingIssuesReferences(first:100){nodes{number}}}}}"
  response="$(curl -s -H 'Content-Type: application/json' \
    -H "authorization: Bearer $GITHUB_TOKEN" \
    -X POST -d "{ \"query\": \"$script\"}" https://api.github.com/graphql)"
  echo $response \
    | jq .data.repository.pullRequest.closingIssuesReferences.nodes[].number? \
    | tr "\n" "," \
    | sed 's/,$//'
}

main() {
  prepareInputs
  issues="$(get_issues)"
  echo "::set-output name=issues::$issues"

  # if we need to get the issue owners
  if [ -n "$INPUT_OWNERS" ]; then
    PULL_REQUEST_OPENER="$(
      curl -s "https://api.github.com/repos/$REPOSITORY_OWNER/$REPOSITORY_NAME/pulls/$PULL_REQUEST" \
        -H "authorization: Bearer $GITHUB_TOKEN" \
      | jq -r .user.login
    )"

    opener=""
    others=""
    touch /tmp/opener.txt /tmp/others.txt

    # iterate through linked issues
    echo "$issues\n" | tr ',' '\n' | while read issue; do
      owner="$(
        curl -s "https://api.github.com/repos/$REPOSITORY_OWNER/$REPOSITORY_NAME/issues/$issue" \
          -H "authorization: Bearer $GITHUB_TOKEN" \
        | jq -r .user.login
      )"
      if [ "$owner" = "$PULL_REQUEST_OPENER" ]; then
        printf "$issue," >> /tmp/opener.txt
      else
        printf "$issue," >> /tmp/others.txt
      fi
    done

    opener="$(< /tmp/opener.txt sed 's/,\{1,\}$//')"
    others="$(< /tmp/others.txt sed 's/,\{1,\}$//')"

    rm -f /tmp/opener.txt /tmp/others.txt

    echo "::set-output name=opener::$opener"
    echo "::set-output name=others::$others"
  fi
}


main
