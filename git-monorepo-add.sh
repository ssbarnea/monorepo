#!/bin/bash
set -e

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters. Please call it with: $0 <dest_repo> <src_repo>"
fi

SRC_REPO=$2
DST_REPO=$1
SRC_NAME=$(basename "$SRC_REPO" ".${SRC_REPO##*.}")
DST_NAME=$(basename "$DST_REPO" ".${DST_REPO##*.}")

TMP_SRC_REPO=$SRC_NAME.tmp
TMP_DST_REPO=$DST_NAME.tmp

subdir="src/"

rm -rf $TMP_SRC_REPO
# this approach assures that all remote branches are cloned locally, something needed later
git clone --mirror $SRC_REPO $TMP_SRC_REPO/.git
git -C "${TMP_SRC_REPO}" config --bool core.bare false
git -C "${TMP_SRC_REPO}" checkout

echo "INFO:	Preparing source repository..."
git -C "${TMP_SRC_REPO}" filter-branch --prune-empty --tree-filter "
if [[ ! -e $subdir${SRC_NAME} ]]; then
    mkdir -p $subdir${SRC_NAME}
    git ls-tree --name-only \$GIT_COMMIT | xargs -I {} mv {} $subdir${SRC_NAME}
fi" --tag-name-filter cat -- --all

if [ ! -d $TMP_DST_REPO ]; then
    git clone $DST_REPO $TMP_DST_REPO
fi

echo "INFO:	Merging patched source repository '$SRC_REPO' into '$DST_REPO'"
git -C "$TMP_DST_REPO" fetch --no-tags ../${TMP_SRC_REPO} \
    refs/heads/*:refs/heads/${SRC_NAME}/* \
    refs/tags/*:refs/tags/${SRC_NAME}/*
git -C "$TMP_DST_REPO" merge  --no-commit --allow-unrelated-histories ${SRC_NAME}/master
#-s ours
#git -C "$TMP_DST_REPO" read-tree -u ${SRC_NAME}/master
git -C "$TMP_DST_REPO" commit -m "merged in 'master' from project $SRC_NAME"
# --no-commit
echo "INFO: Suceeded, don't forget to push changes from inside $DST_NAME/ "
