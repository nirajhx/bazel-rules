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

# Locate Helm binary
HELM_SH=$(rlocation shared_bazel_rules/ci/helm/helm_binary)
if [[ ! -f "${HELM_SH:-}" ]]; then
  echo >&2 "ERROR: could not look up the Helm tool path"
  exit 1
fi

# Locate yq binary
YQ_SH=$(rlocation shared_bazel_rules/tools/yq/yq_binary)
if [[ ! -f "${YQ_SH:-}" ]]; then
  echo >&2 "ERROR: could not look up the yq tool path"
  exit 1
fi

# find Chart.yaml in the filegroup
CHARTLOC=$(dirname $CHART)

if [[ $APP_VERSION_STAMPED == "false" ]]; then
    VERSION="$APP_VERSION"
else
    VERSION=$(grep $APP_VERSION $VERSION_FILES | cut -d ' ' -f 2)
fi

# copy over to temp to get rid of the symlinks
mkdir -p temp/$CHARTLOC
cp -RL $CHARTLOC/* temp/$CHARTLOC

# resolve dependencies
if [[ "$DEPS" != "" ]]; then
    mkdir -p temp/$CHARTLOC/charts/

    IFS=',' read -ra DEP <<< "$DEPS"
    for i in "${DEP[@]}"; do
        tar xvf $i -C temp/$CHARTLOC/charts/ 2>/dev/null
    done
fi

# Only set .build_info for Developer Service if commit_id and branch_name is set at rule
if [[ -f "temp/${CHARTLOC}/values.yaml" && "$COMMIT_ID_VAR_NAME" != "" && "$BRANCH_NAME_VAR_NAME" != "" ]]; then
    # PROJECT_SHORT_NAME, REPOSITORY_NAME and REPOSITORY_PROVIDER are passed with --action_env during Jenkins pipeline
    # Only set if Bazel is called by Jenkins pipeline or manually passed to Bazel
    if [[ ! -z "${PROJECT_SHORT_NAME:-}" ]]; then
        $YQ_SH eval ".build_info.project_short_name=\"${PROJECT_SHORT_NAME}\"" -i temp/$CHARTLOC/values.yaml
    fi
    if [[ ! -z "${REPOSITORY_NAME:-}" ]]; then
        $YQ_SH eval ".build_info.repository_name=\"${REPOSITORY_NAME}\"" -i temp/$CHARTLOC/values.yaml
    fi
    if [[ ! -z "${REPOSITORY_PROVIDER:-}" ]]; then
        $YQ_SH eval ".build_info.repository_provider=\"${REPOSITORY_PROVIDER}\"" -i temp/$CHARTLOC/values.yaml
    fi
    # Git branch and commit_id are resolved with ctx.info_file containing STABLE_* keys
    GIT_COMMIT=$(grep $COMMIT_ID_VAR_NAME $VERSION_FILES | cut -d ' ' -f 2)
    $YQ_SH eval ".build_info.commit_id=\"${GIT_COMMIT}\"" -i temp/$CHARTLOC/values.yaml
    GIT_BRANCH=$(grep $BRANCH_NAME_VAR_NAME $VERSION_FILES | cut -d ' ' -f 2)
    $YQ_SH eval ".build_info.branch=\"${GIT_BRANCH}\"" -i temp/$CHARTLOC/values.yaml
fi

$HELM_SH package --app-version=$VERSION $FLAGS temp/$CHARTLOC 1>/dev/null
mv *tgz $OUTPUT
