package k8s

import (
	"runtime"

	"github.com/yxun/util-shell/sh"
)

const (
	goos             string = runtime.GOOS
	arch             string = "amd64"
	kubectlVersion   string = "v1.18.0"
	kindVersion      string = "v0.7.0"
	dashboardVersion string = "v2.0.0"
	minikubeVersion  string = "v1.9.2"
	minikubeDriver   string = "kvm2"
	k8sVersion       string = "v1.18.0"
	helmVersion      string = "v3.2.0"
)

var (
	log = sh.NewTextLogger()
)
