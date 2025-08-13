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

SHELL := /usr/bin/env bash -o pipefail

export GO111MODULE ?= on
export GOPROXY ?= https://proxy.golang.org
export GOSUMDB ?= sum.golang.org

GO ?= go

GOARCH_LOCAL := $(TARGET_ARCH)
GOOS_LOCAL := $(TARGET_OS)

#-----------------------------------------------------------------------------
# Output control
#-----------------------------------------------------------------------------
# Invoke make VERBOSE=1 to enable echoing of the command being executed
export VERBOSE ?= 0
# Place the variable Q in front of a command to control echoing of the command being executed.
Q = $(if $(filter 1,$VERBOSE),,@)
# Use the variable H to add a header (equivalent to =>) to informational output
H = $(shell printf "\033[34;1m=>\033[0m")

export ARTIFACTS ?= $(TARGET_OUT)
export JUNIT_OUT ?= $(ARTIFACTS)/junit.xml
export REPO_ROOT := $(shell git rev-parse --show-toplevel)

# Make directories needed by the build system
$(shell mkdir -p $(TARGET_OUT_LINUX))
$(shell mkdir -p $(TARGET_OUT_LINUX)/logs)
$(shell mkdir -p $(dir $(JUNIT_OUT)))

# Need separate target for init:
$(TARGET_OUT):
  @mkdir -p $@

# If the hub is not explicitly set, use default to localhost.
HUB ?=localhost
ifeq ($(HUB),)
  $(error "HUB cannot be empty")
endif

# For dockerx builds, allow HUBS which is a space separated list of hubs. Default to HUB.
HUBS ?= $(HUB)

# If tag not explicitly set in users' .istiorc.mk or command line, default to the git sha.
TAG ?= $(shell git rev-parse --verify HEAD)
ifeq ($(TAG),)
  $(error "TAG cannot be empty")
endif

PULL_POLICY ?= IfNotPresent
ifeq ($(TAG),latest)
  PULL_POLICY = Always
endif
ifeq ($(PULL_POLICY),)
  $(error "PULL_POLICY cannot be empty")
endif

.PHONY: default
default: init build test

.PHONY: init
# Downloads envoy, based on the SHA defined in the base pilot Dockerfile
init: $(TARGET_OUT)/istio_is_init init-ztunnel-rs
	@mkdir -p ${TARGET_OUT}/logs
	@mkdir -p ${TARGET_OUT}/release

$(TARGET_OUT)/istio_is_init: bin/init.sh istio.deps | $(TARGET_OUT)
	@# Add a retry, as occasionally we see transient connection failures to GCS
	@# Like `curl: (56) OpenSSL SSL_read: SSL_ERROR_SYSCALL, errno 104`
	TARGET_OUT=$(TARGET_OUT) ISTIO_BIN=$(ISTIO_BIN) GOOS_LOCAL=$(GOOS_LOCAL) bin/retry.sh SSL_ERROR_SYSCALL bin/init.sh
	touch $(TARGET_OUT)/istio_is_init

.PHONY: init-ztunnel-rs
init-ztunnel-rs:
	TARGET_OUT=$(TARGET_OUT) bin/build_ztunnel.sh

# Pull dependencies such as envoy
depend: init | $(TARGET_OUT)

DIRS_TO_CLEAN := $(TARGET_OUT)
DIRS_TO_CLEAN += $(TARGET_OUT_LINUX)

$(OUTPUT_DIRS):
	@mkdir -p $@



RELEASE_LDFLAGS='-extldflags -static -s -w'

# List of all binaries to build
# We split the binaries into "agent" binaries and standard ones. This corresponds to build "agent".
# This allows conditional compilation to avoid pulling in costly dependencies to the agent, such as XDS and k8s.
AGENT_BINARIES:=./pilot/cmd/pilot-agent
STANDARD_BINARIES:=./istioctl/cmd/istioctl \
  ./pilot/cmd/pilot-discovery \

CNI_BINARIES:=./cni/cmd/istio-cni \
	./cni/cmd/install-cni
# These are binaries that require Linux to build, and should
# be skipped on other platforms. Notably this includes the current Linux-only Istio CNI plugin
LINUX_AGENT_BINARIES:=$(CNI_BINARIES) \
  $(AGENT_BINARIES)

BINARIES:=$(STANDARD_BINARIES) $(AGENT_BINARIES) $(LINUX_AGENT_BINARIES)

RELEASE_SIZE_TEST_BINARIES:=pilot-discovery pilot-agent istioctl envoy ztunnel

# agent: enables agent-specific files. Usually this is used to trim dependencies where they would be hard to trim through standard refactoring
# disable_pgv: disables protoc-gen-validation. This is not used buts adds many MB to Envoy protos
# not set vtprotobuf: this adds some performance improvement, but at a binary cost increase that is not worth it for the agent
# notrace: helps with https://github.com/istio/istio/issues/56636 and reduces bnary size
AGENT_TAGS=agent,disable_pgv,grpcnotrace,retrynotrace
# disable_pgv: disables protoc-gen-validation. This is not used buts adds many MB to Envoy protos
# vtprotobuf: enables optimized protobuf marshalling.
STANDARD_TAGS=vtprotobuf,disable_pgv

.PHONY: build
build: depend ## Builds all go binaries.
	GOOS=$(GOOS_LOCAL) GOARCH=$(GOARCH_LOCAL) LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $(TARGET_OUT)/ -tags=$(STANDARD_TAGS) $(STANDARD_BINARIES)
	GOOS=$(GOOS_LOCAL) GOARCH=$(GOARCH_LOCAL) LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $(TARGET_OUT)/ -tags=$(AGENT_TAGS) $(AGENT_BINARIES)

.PHONY: build-cni
build-cni: depend
	GOOS=$(GOOS_LOCAL) GOARCH=$(GOARCH_LOCAL) LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $(TARGET_OUT)/ -tags=$(AGENT_TAGS) $(CNI_BINARIES)



