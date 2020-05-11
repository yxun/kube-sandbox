package install

import (
	"testing"
)

func TestInstallKubectl(t *testing.T) {
	if err := InstallKubectl(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestUninstallKubectl(t *testing.T) {
	if err := UninstallKubectl(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}
