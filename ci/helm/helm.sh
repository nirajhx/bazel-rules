#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{ echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# Find helm binary
platform=$(uname)
if [ "$platform" == "Darwin" ]; then
    BINARY=$(rlocation helm_osx/darwin-amd64/helm)
elif [ "$platform" == "Linux" ]; then
    BINARY=$(rlocation helm/linux-amd64/helm)
else
    echo "Helm does not have a binary for $platform"
    exit 1
fi

# Setup helm env
export HELM_HOME="$(pwd)/.helm"
export PATH="$(dirname $BINARY):$PATH"

# Configuration for AWS
export AWS_REGION=eu-central-1

cd "${BUILD_WORKING_DIRECTORY:-}"

$BINARY $*
