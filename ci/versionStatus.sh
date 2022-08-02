#!/usr/bin/env bash
# short=8 returns a unique hash with at least 8 characters
git_commit=$(git rev-parse --short=8 HEAD)

if [[ -z "$BRANCH_NAME" ]]; then
    git_branch=$(git rev-parse --abbrev-ref HEAD)
else
    git_branch=$BRANCH_NAME
fi

branch_slug=${git_branch//[^a-zA-Z0-9.-]/-}
# Limit Docker tag to 127 characters depending on git_commit length
# Docker supports 128 characters but Bazel accepts only 127 characters for tag length
docker_tag="${branch_slug:0:126-${#git_commit}}-${git_commit}"
cat << EOF
STABLE_VERSION ${docker_tag}
BRANCH_NAME ${git_branch}
EOF
