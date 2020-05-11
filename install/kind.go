package install

import (
	"fmt"

	"github.com/yxun/util-shell/sh"
)

// InstallKind ...
func InstallKind() error {
	url := fmt.Sprintf("https://kind.sigs.k8s.io/dl/%s/kind-%s-amd64",
		kindVersion, goos)
	sh.Shell("curl -Lo ./kind %s", url)
	sh.Shell("chmod +x ./kind")
	sh.Shell("mkdir -p ${HOME}/bin")
	sh.Shell("mv ./kind ${HOME}/bin/kind")
	_, err := sh.Shell("kind --version")
	return err
}

// UninstallKind ...
func UninstallKind() error {
	_, err := sh.Shell("rm $(which kind)")
	return err
}

// CreateKindCluster ...
func CreateKindCluster(name string) error {
	sh.Shell("kind create cluster --name %s", name)
	_, err := sh.Shell("kubectl cluster-info --context kind-%s", name)
	return err
}

// DeleteKindCluster ...
func DeleteKindCluster(name string) error {
	_, err := sh.Shell("kind delete cluster --name %s", name)
	return err
}
