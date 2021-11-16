#!/bin/bash

set -o pipefail

cd ${GITHUB_WORKSPACE}/.

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

tag_without_v="${tag:1}"

incremented_tag="$(($tag_without_v + 1))"

new="v$incremented_tag"

echo "new tag will be $new"

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

 git fetch --prune --prune-tags
 tags_to_remove=$(git tag --sort=-creatordate | tail -n +31)
 if [ -z "$tags_to_remove" ]
 then
   exit 0
 fi

 echo "this tags are going to be removed: $tags_to_remove"

 for tag in $tags_to_remove
 do
   git tag --delete $tag
   git push --no-verify --delete origin $tag
 done
