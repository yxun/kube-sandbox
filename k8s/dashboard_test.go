package k8s

import (
	"testing"
)

func TestInstallDashboard(t *testing.T) {
	if err := InstallDashboard(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestUninstallDashboard(t *testing.T) {
	if err := UninstallDashboard(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}
