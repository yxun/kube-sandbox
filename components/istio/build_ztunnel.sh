#!/bin/bash

# Copyright Istio Authors
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

LOCAL_ARCH=$(uname -m)

# Pass environment set target architecture to build system
if [[ ${TARGET_ARCH} ]]; then
    # Target explicitly set
    :
elif [[ ${LOCAL_ARCH} == x86_64 ]]; then
    TARGET_ARCH=amd64
elif [[ ${LOCAL_ARCH} == armv8* ]]; then
    TARGET_ARCH=arm64
elif [[ ${LOCAL_ARCH} == arm64* ]]; then
    TARGET_ARCH=arm64
elif [[ ${LOCAL_ARCH} == aarch64* ]]; then
    TARGET_ARCH=arm64
elif [[ ${LOCAL_ARCH} == armv* ]]; then
    TARGET_ARCH=arm
elif [[ ${LOCAL_ARCH} == s390x ]]; then
    TARGET_ARCH=s390x
elif [[ ${LOCAL_ARCH} == ppc64le ]]; then
    TARGET_ARCH=ppc64le
else
    echo "This system's architecture, ${LOCAL_ARCH}, isn't supported"
    exit 1
fi

TARGET_OUT_LINUX="${TARGET_OUT_LINUX:-$(pwd)/out/linux_${TARGET_ARCH}}"

# Gets the download command supported by the system (currently either curl or wget)
DOWNLOAD_COMMAND=""
function set_download_command () {
  # Try curl.
  if command -v curl > /dev/null; then
    if curl --version | grep Protocols  | grep https > /dev/null; then
      DOWNLOAD_COMMAND="curl -fLSs --retry 5 --retry-delay 1 --retry-connrefused"
      return
    fi
    echo curl does not support https, will try wget for downloading files.
  else
    echo curl is not installed, will try wget for downloading files.
  fi

  # Try wget.
  if command -v wget > /dev/null; then
    DOWNLOAD_COMMAND="wget -qO -"
    return
  fi
  echo wget is not installed.

  echo Error: curl is not installed or does not support https, wget is not installed. \
       Cannot download envoy. Please install wget or add support of https to curl.
  exit 1
}

# Params:
#   $1: The URL of the ztunnel binary to be downloaded.
#   $2: The full path of the output binary.
#   $3: Non-versioned name to use
function download_ztunnel_if_necessary () {
  if [[ -f "$2" ]]; then
    return
  fi
  # Enter the output directory.
  mkdir -p "$(dirname "$2")"
  pushd "$(dirname "$2")" || exit

  # Download and make the binary executable
  echo "Downloading ztunnel: $1 to $2"
  time ${DOWNLOAD_COMMAND} --header "${AUTH_HEADER:-}" "$1" > "$2"
  chmod +x "$2"

  # Make a copy named just "ztunnel" in the same directory (overwrite if necessary).
  echo "Copying $2 to $(dirname "$2")/${3}"
  cp -f "$2" "$(dirname "$2")/${3}"
  popd || exit

  # Also copy it to out/$os_arch/ztunnel as that's whats used in the build
  echo "Copying '${2}' to ${TARGET_OUT_LINUX}/ztunnel"
  cp -f "${2}" "${TARGET_OUT_LINUX}/ztunnel"
}
