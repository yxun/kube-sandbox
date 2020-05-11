package install

import (
	"fmt"
	"strings"

	"github.com/yxun/util-shell/sh"
)

func (f *fedora) InstallLibvirt() error {
	sh.ShellMuteOutput("sudo dnf install -y @virtualization")
	sh.Shell("sudo usermod --append --groups libvirt $(whoami)")
	sh.Shell("sudo systemctl start libvirtd")
	sh.Shell("sudo systemctl enable libvirtd")
	msg, err := sh.Shell("lsmod | grep kvm")
	if strings.Contains(msg, "kvm_intel") || strings.Contains(msg, "kvm_amd") {
		log.Info("kvm installed successfully.")
	} else {
		log.Errorf("kvm installation failed: %v", msg)
		return fmt.Errorf("kvm installation failed")
	}
	return err
}
