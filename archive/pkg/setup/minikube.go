package setup

import (
	"fmt"

	"github.com/yxun/util-shell/sh"
)

func (l *linux) checkVirt() error {
	_, err := sh.ShellMuteOutput("grep -E --color 'vmx|svm' /proc/cpuinfo")
	return err
}

// InstallMinikube ...
func (l *linux) InstallMinikube() error {
	if err := l.checkVirt(); err != nil {
		return err
	}

	// InstallKubectl, need to be updated

	// InstallHypervisor
	if err := testFedora.InstallLibvirt(); err != nil {
		return err
	}

	// Install minikube
	url := fmt.Sprintf("https://storage.googleapis.com/minikube/releases/%s/minikube-%s-amd64",
		minikubeVersion, goos)
	sh.Shell("curl -Lo ./minikube %s", url)
	sh.Shell("chmod +x ./minikube")
	sh.Shell("mkdir -p ${HOME}/bin")
	sh.Shell("mv ./minikube ${HOME}/bin/minikube")
	_, err := sh.Shell("minikube version")
	return err
}

// UninstallMinikube ...
func (l *linux) UninstallMinikube() error {
	_, err := sh.Shell("rm $(which minikube)")
	return err
}

// CreateMinikubeCluster ...
func (l *linux) CreateMinikubeCluster() error {
	sh.Shell("minikube start --driver=%s --kubernetes-version %s", minikubeDriver, k8sVersion)
	sh.Shell("minikube status")
	sh.Shell("sleep 20")
	log.Info("When reboot machine, run minikube start m01")
	sh.ShellBackground("kubectl proxy --port=%s", proxyPort)
	log.Info("Remote access: check sshd AllowTcpForwarding yes")
	log.Infof("Remote access ssh local forward: ssh -f -N -L [localport]:localhost:%s %s", proxyPort, testHost)
	_, err := sh.Shell("minikube kubectl -- get po -A")
	return err
}

// DeleteMinikubeCluster ...
func (l *linux) DeleteMinikubeCluster() error {
	sh.Shell("kill $(lsof -t -i:%s)", proxyPort)
	sh.Shell("minikube stop")
	_, err := sh.Shell("minikube delete --all")
	return err
}
