package k8s

import (
	"fmt"

	"github.com/yxun/util-shell/sh"
)

// InstallHelm ...
func InstallHelm() error {
	helmdist := fmt.Sprintf("helm-%s-%s-%s.tar.gz", helmVersion, goos, arch)
	url := fmt.Sprintf("https://get.helm.sh/%s", helmdist)
	sh.Shell("curl -Lo %s %s", helmdist, url)
	sh.Shell("tar -zxvf %s", helmdist)
	sh.Shell("chmod +x ./%s-%s/helm", goos, arch)
	sh.Shell("mkdir -p ${HOME}/bin")
	sh.Shell("mv ./%s-%s/helm ${HOME}/bin/helm", goos, arch)
	sh.Shell("rm %s", helmdist)
	sh.Shell("rm -r %s-%s", goos, arch)
	_, err := sh.Shell("helm version")
	return err
}

// UninstallHelm ...
func UninstallHelm() error {
	_, err := sh.Shell("rm $(which helm)")
	return err
}
