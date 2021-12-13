#!/bin/sh

REPOSITORY_OWNER="$INPUT_REPOSITORY_OWNER"
REPOSITORY_NAME="$INPUT_REPOSITORY_NAME"
PULL_REQUEST="$INPUT_PULL_REQUEST"
ADD_LINKS_BY_CONTENT="$INPUT_ADD_LINKS_BY_CONTENT"


prepareInputs() {
  if [ -z "$REPOSITORY_OWNER" ]; then
    REPOSITORY_OWNER=$(< "$GITHUB_EVENT_PATH" jq -r ".repository.owner.login")
  fi

  if [ -z "$REPOSITORY_NAME" ]; then
    REPOSITORY_NAME=$(< "$GITHUB_EVENT_PATH" jq -r ".repository.name")
  fi

  if [ -z "$PULL_REQUEST" ]; then
    PULL_REQUEST=$(< "$GITHUB_EVENT_PATH" jq ".number")
    if [ "$PULL_REQUEST" = "null" ]; then
      printf "PR number can't be retrieved from event data.\n" >&2
      printf "You must define a pull request number using 'pr_number' input or" >&2
      printf " execute the action using a pull request event.\n" >&2
      exit 1
    fi
  fi
}

get_issues() {
  # create a temporal directory to store unique pull request numbers
  linked_issues_tmpdir="/tmp/pr-linked-issues"
  rm -rf "$linked_issues_tmpdir"
  mkdir -p "$linked_issues_tmpdir"

  # get linked issued from GraphQL API
  script="query{repository(name:\\\"$REPOSITORY_NAME\\\",owner:\\\"$REPOSITORY_OWNER\\\"){pullRequest(number:$PULL_REQUEST){closingIssuesReferences(first:100){nodes{number}}}}}"
  linked_issues_response="$(curl -s -H 'Content-Type: application/json' \
    -H "authorization: Bearer $GITHUB_TOKEN" \
    -X POST -d "{ \"query\": \"$script\"}" https://api.github.com/graphql)"

  # iterate over PRs and create files for each one of them
  echo $linked_issues_response \
  | jq ".data.repository.pullRequest.closingIssuesReferences.nodes[].number?" \
  | while read linked_issue_number; do
    touch "$linked_issues_tmpdir/$linked_issue_number"
  done;

  # add links to other issues by content
  if [ -n "$ADD_LINKS_BY_CONTENT" ]; then
    if [ -z "$REPOSITORY_OWNER" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$PULL_REQUEST" ]; then
      # get body from event pull request
      pull_request_body="$(< "$GITHUB_EVENT_PATH" jq ".pull_request.body")"
    else
      # get body from Github API
      pull_request_body="$(
        curl -s \
          -H "Accept: application/vnd.github.v3+json" \
          -H "authorization: Bearer $GITHUB_TOKEN" \
          https://api.github.com/repos/$REPOSITORY_OWNER/$REPOSITORY_NAME/pulls/$PULL_REQUEST \
        | jq .body)"
    fi;

    # iterate over placeholder expressions
    echo "$ADD_LINKS_BY_CONTENT" | while read placeholder_line; do
      # ignore empty input lines
      if [ -z "$placeholder_line" ]; then
        continue
      fi;

      # check that every line contains the '{issue_number}' placeholder
      contains_pull_request_placeholder="$(echo "$placeholder_line" | grep "{issue_number}")"
      if [ -z "$contains_pull_request_placeholder" ]; then
        printf "The line '%s' of the input 'add_links_by_content'" "$placeholder_line" >&2
        printf " does not contains the '{issue_number}' placeholder.\n" >&2
        exit 1
      fi;

      # build regex replacing '{issue_number}' with digit matcher using Posix ERE and escape it
      #
      # Current limitations:
      #   - Number of occurrences using {#}
      #   - Grouping using ()
      regex="$(
        echo "$placeholder_line" \
        | sed -e "s/\*/\\\\*/g" \
              -e "s/\\+/\\\\+/g" \
              -e "s/\./\\\\./g" \
              -e "s/\[/\\\\[/g" \
              -e "s/\]/\\\\]/g" \
              -e "s/\\^/\\\\^/g" \
              -e "s/\\$/\\\\$/g" \
              -e "s/{issue_number}/([[:digit:]]+)/"
      )"

      more_linked_issues_by_content="$(
        echo "$pull_request_body" \
        | grep -Eo "$regex" \
        | grep -Eo "[[:digit:]]+"
      )"

      echo "$more_linked_issues_by_content" | while read linked_issue_by_content; do
        if [ -n "$linked_issue_by_content" ]; then
          linked_issue_filepath="$linked_issues_tmpdir/$linked_issue_by_content"
          if [ ! -f "$linked_issue_filepath" ]; then
            touch "$linked_issue_filepath"
          fi;
        fi;
      done;
    done;
  fi;

  ls -1 "$linked_issues_tmpdir" | tr '\n' ',' | sed 's/,$//'
  rm -rf "$linked_issues_tmpdir"
}

main() {
  prepareInputs
  issues="$(get_issues)"
  echo "::set-output name=issues::$issues"

  # if we need don't need to get the issue owners, exit now
  if [ -z "$INPUT_OWNERS" ]; then
    return 0
  fi;

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

  opener="$(< /tmp/opener.txt sed 's/[n,]\{1,\}$//')"
  others="$(< /tmp/others.txt sed 's/[n,]\{1,\}$//')"

  rm -f /tmp/opener.txt /tmp/others.txt

  echo "::set-output name=opener::$opener"
  echo "::set-output name=others::$others"
}


main
