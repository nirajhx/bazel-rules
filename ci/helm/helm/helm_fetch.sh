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

HELM_SH=$(rlocation shared_bazel_rules/ci/helm/helm_binary)
if [[ ! -f "${HELM_SH:-}" ]]; then
  echo >&2 "ERROR: could not look up the Helm tool path"
  exit 1
fi

if [[ "$VERSION_FILES" != "" ]]; then
    VERSION=$(grep STABLE_VERSION $VERSION_FILES | cut -d ' ' -f 2)
fi

$HELM_SH fetch --version $VERSION $CHART --repo $REPOSITORY 1>/dev/null
mv *tgz $OUTPUT
