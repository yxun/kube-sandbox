package install

import (
	"fmt"
	"runtime"
	"strings"

	"github.com/yxun/util-shell/sh"
)

// cgroupRevert if cgroup v2 is enabled in Fedora 31, revert back to cgroup v1
func cgroupRevert() error {
	log.Info("Checking OS version")
	os := runtime.GOOS
	if os != "linux" {
		return fmt.Errorf("Platform is not supported: %s", os)
	}

	releaseMsg, err := sh.Shell("cat /etc/*-release | grep release")
	if err != nil {
		return err
	}
	if strings.Contains(releaseMsg, "Fedora release 31") {
		log.Info("Checking cgroup version")
		cgroupMsg, err := sh.Shell("cat /proc/cmdline | grep systemd.unified_cgroup_hierarchy=0")
		if err != nil {
			return err
		}
		if len(cgroupMsg) > 0 {
			log.Info("cgroup has been reverted to v1")
		} else {
			log.Info("Reverting back to cgroup v1")
			sh.ShellMuteOutput("sudo dnf install grubby -y")
			sh.Shell("sudo grubby --update-kernel=ALL --args=\"systemd.unified_cgroup_hierarchy=0\"")
			sh.Shell("sudo reboot")
		}
	}
	return nil
}

// InstallDocker installs docker-ce from https://download.docker.com/linux/fedora/docker-ce.repo
func InstallDocker(user string) error {
	cgroupRevert()
	sh.Shell("sudo dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo")
	sh.ShellMuteOutput("sudo dnf install docker-ce -y")
	// sh.Shell("sudo groupadd docker")
	sh.Shell("sudo usermod -aG docker %s", user)
	sh.Shell("sudo systemctl restart docker")
	sh.Shell("sudo systemctl enable docker")
	// sh.Shell("newgrp docker")
	sh.Shell("sudo chown %s:docker /var/run/docker.sock", user)
	_, err := sh.Shell("docker version")
	return err
}

// UninstallDocker uninstalls docker-ce
func UninstallDocker(user string) error {
	sh.Shell("sudo systemctl disable docker")
	if _, err := sh.Shell("sudo systemctl stop docker"); err != nil {
		return err
	}
	if _, err := sh.ShellMuteOutput("sudo dnf remove docker-ce -y"); err != nil {
		return err
	}
	sh.Shell("sudo gpasswd -d %s docker", user)
	sh.Shell("sudo groupdel docker")
	sh.Shell("sudo rm /etc/yum.repos.d/docker-ce.repo")
	return nil
}
