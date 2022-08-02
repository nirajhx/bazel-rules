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

# Find yq binary
platform=$(uname)
if [ "$platform" == "Darwin" ]; then
    BINARY=$(rlocation yq_osx/yq_darwin_amd64)
elif [ "$platform" == "Linux" ]; then
    BINARY=$(rlocation yq/yq_linux_amd64)
else
    echo "yq does not have a binary for $platform"
    exit 1
fi

# Setup yq env
export PATH="$(dirname $BINARY):$PATH"

cd "${BUILD_WORKING_DIRECTORY:-}"

$BINARY $*
