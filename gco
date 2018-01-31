#!/bin/bash

set -e

git status 1>/dev/null 2>/dev/null

BRANCHES=$(git branch -a)

TAGS=$(git tag -l | sed -e 's/^/  /')

ALLREFS=$(cat <<- EOF
$BRANCHES
$TAGS
EOF
)

REF=$(echo "${ALLREFS[@]}" | fzf)

git checkout -t $REF 2>/dev/null || git checkout ${REF##*/}
