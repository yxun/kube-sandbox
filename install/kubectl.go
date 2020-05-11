package install

import (
	"fmt"

	"github.com/yxun/util-shell/sh"
)

// InstallKubectl ...
func InstallKubectl() error {
	url := fmt.Sprintf("https://storage.googleapis.com/kubernetes-release/release/%s/bin/%s/amd64/kubectl",
		kubectlVersion, goos)
	sh.Shell("curl -Lo ./kubectl %s", url)
	sh.Shell("chmod +x ./kubectl")
	sh.Shell("mkdir -p ${HOME}/bin")
	sh.Shell("mv ./kubectl ${HOME}/bin/kubectl")
	_, err := sh.Shell("kubectl version --client")
	return err
}

// UninstallKubectl ...
func UninstallKubectl() error {
	_, err := sh.Shell("rm $(which kubectl)")
	return err
}
