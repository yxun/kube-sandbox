package k8s

import (
	"runtime"

	"github.com/yxun/util-shell/sh"
)

const (
	goos             string = runtime.GOOS
	kubectlVersion   string = "v1.18.0"
	kindVersion      string = "v0.7.0"
	dashboardVersion string = "v2.0.0"
)

var (
	log = sh.NewTextLogger()
)
