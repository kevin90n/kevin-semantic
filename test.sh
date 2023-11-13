#!/usr/bin/env bash
set -euo pipefail

while getopts b:h: flag
do
    case "${flag}" in
        b) basebranch=${OPTARG};;
        h) headbranch=${OPTARG};;
    esac
done
    
pr_id=$(curl -L  -X POST  https://api.github.com/repos/kevin90n/kevin-semantic/pulls \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d '{"title":"chore: automatic merge","body":"Please pull these awesome changes in!","head":"'"$headbranch"'","base":"'"$basebranch"'"}'  |  jq -r .node_id) || request_status=$?

echo $pr_id
echo ${request_status+x}


if [[ -z ${request_status+x} && -n $pr_id && $pr_id != null ]]
then
    enabled_at=$(curl -X POST https://api.github.com/graphql \
         -H 'Content-Type: application/json' \
         -H "Authorization: bearer $GITHUB_TOKEN" \
         -d '{"query": "mutation {enablePullRequestAutoMerge(input: {pullRequestId: \"'"$pr_id"'\"}) {pullRequest {autoMergeRequest{enabledAt}}}}"' | jq .data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest.enabledAt)  || request_status=$?
    if [[ -z ${request_status+x} && -n $enabled_at ]]
    then
      echo "failed to enable automerge for the PR: #$pr_id"
      exit 1
    fi  
else
  echo "failed to get pull request ID. Exiting"
  exit 1
fi
