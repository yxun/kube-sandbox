#!/bin/bash

# Copyright 2018 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

WD=$(dirname "$0")
WD=$(cd "$WD" || exit; pwd)

function date_cmd() {
  case "$(uname)" in
    "Darwin")
      [ -z "$(which gdate)" ] && echo "gdate is required for OSX. Try installing coreutils from MacPorts or Brew."
      gdate "$@"
      ;;
    *)
      date "$@"
      ;;
  esac
}

# Output a message, with a timestamp matching istio log format
function log() {
  echo -e "$(date_cmd -u '+%Y-%m-%dT%H:%M:%S.%NZ')\t$*"
}

# Download and unpack istio release artifacts.
function download_untar_istio_release() {
  local url_path=${1}
  local tag=${2}
  local dir=${3:-.}
  # Download artifacts
  LINUX_DIST_URL="${url_path}/istio-${tag}-linux.tar.gz"

  wget  -q "${LINUX_DIST_URL}" -P "${dir}"
  tar -xzf "${dir}/istio-${tag}-linux.tar.gz" -C "${dir}"
}
