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

# Setup and install Helm push plugin
# Find correct operating system version of Helm push plugin
platform=$(uname)
if [ "$platform" == "Darwin" ]; then
    HELM_PUSH_YAML=$(rlocation helm_push_osx/plugin.yaml)
elif [ "$platform" == "Linux" ]; then
    HELM_PUSH_YAML=$(rlocation helm_push/plugin.yaml)
else
    echo "Helm does not have a binary for $platform"
    exit 1
fi

# Get Helm push plugin directory
HELM_PUSH_DIR=$(dirname $HELM_PUSH_YAML)
# Check for Helm push plugin and install if not present
if [[ $($HELM_SH plugin list | grep push) ]]; then
    echo "Helm push plugin already installed. Skip further installation of Helm push plugin."
else
    $HELM_SH plugin install $HELM_PUSH_DIR 1>/dev/null
fi

# Add VWNI ChartMuseum Helm repository
# Env set by Jenkins pipeline
# --action_env=ACCESS_TOKEN for request token from ChartMuseum Auth-Server
# --action_env=REPO_SLUG for ChartMuseum Auth-Server request and ChartMuseum repo URL
# --action_env=chart_version for next available HelmChart version from ChartMuseum
CHARTMUSEUM_URL="https://chartmuseum.meta.infrastructure.vwn.cloud/${REPO_SLUG}"
echo "ChartMuseum URL: ${CHARTMUSEUM_URL}"
$HELM_SH repo add chartmuseum ${CHARTMUSEUM_URL} 1>/dev/null

# Get token for Helm push to ChartMuseum
OAUTH_SCOPE="artifact-repository:${REPO_SLUG}:push"
AUTH_SERVER="http://chart-auth.chartmuseum.svc.cluster.local/oauth/token?scope=${OAUTH_SCOPE}&grant_type=client_credentials"
echo "ChartMuseum Auth-Server URL: ${AUTH_SERVER}"

# Please note: cURL establishes a connection to an in-cluster domain.
# If running locally for local development an active VPN connection is needed to request a token from ChartMuseum's Auth-Server.

# with jq
#export HELM_REPO_ACCESS_TOKEN=$(curl -s -X POST -H "Authorization: Bearer ${ACCESS_TOKEN}" ${AUTH_SERVER} | jq .access_token -r)
# without jq, with bash
curl_token=$(curl -s -X POST -H "Authorization: Bearer ${ACCESS_TOKEN}" ${AUTH_SERVER})
# Remove leading '"access_token":"'
curl_token_prefix=${curl_token#"{\"access_token\":\""}
# Remove trailing '"}'
curl_token_prefix_suffix=${curl_token_prefix%"\"}"}
export HELM_REPO_ACCESS_TOKEN=$curl_token_prefix_suffix

# Overwrite HelmChart version with version from Jenkins Pipeline and push HelmChart
PUSH_RESULT=$($HELM_SH push $1 --version="${chart_version}" chartmuseum)
# Echo result to shell
echo ${PUSH_RESULT}
# Echo result in file for Bazel action output
echo ${PUSH_RESULT} > $2
