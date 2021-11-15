#!/bin/bash

set -o pipefail

# config
source=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
verbose=${VERBOSE:-true}

cd ${GITHUB_WORKSPACE}/${source}

echo "*** CONFIGURATION ***"
echo -e "\tSOURCE: ${source}"
echo -e "\tDRY_RUN: ${dryrun}"
echo -e "\tVERBOSE: ${verbose}"

# fetch tags
git fetch --tags

tag=$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' | grep -E "^v?[0-9]+$" | head -n1)

log=$(git log --pretty='%B')

# get current commit hash for tag
tag_commit=$(git rev-list -n 1 $tag)

# get current commit hash
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    echo ::set-output name=tag::$tag
    exit 0
fi

# echo log if verbose is wanted
if $verbose
then
  echo $log
fi

tag_without_v="${tag:1}"

echo ">>>>>>>>>>> $tag_without_v"

((tag_without_v++))

echo ">>>>>>>>>>> $tag_without_v"

new="v$tag_without_v"

echo ">>>>>>>>>>> $new"

# use dry run to determine the next tag
if $dryrun
then
    echo "dryrun new tag will be $new"
    exit 0
fi

echo " >>>>>>>>>>>> new tag will be $new"

# create local git tag
git tag $new

# push new tag ref to github
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url $GITHUB_EVENT_PATH | tr -d '"' | sed 's/{\/sha}//g')

echo "$dt: **pushing tag $new to repo $full_name"

git_refs_response=$(
curl -s -X POST $git_refs_url \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF

{
  "ref": "refs/tags/$new",
  "sha": "$commit"
}
EOF
)

git_ref_posted=$( echo "${git_refs_response}" | jq .ref | tr -d '"' )

echo "::debug::${git_refs_response}"
if [ "${git_ref_posted}" = "refs/tags/${new}" ]; then
  exit 0
else
  echo "::error::Tag was not created properly."
  exit 1
fi
