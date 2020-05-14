package setup

import (
	"testing"
)

func TestInstallHelm(t *testing.T) {
	if err := InstallHelm(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestUninstallHelm(t *testing.T) {
	if err := UninstallHelm(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}
