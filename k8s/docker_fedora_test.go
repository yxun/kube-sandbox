package k8s

import (
	"testing"
)

const (
	testUser string = "yxu"
)

func TestInstallDocker(t *testing.T) {
	if err := InstallDocker(testUser); err != nil {
		t.Errorf("Failed in installation: %v", err)
	}
}

func TestUninstallDocker(t *testing.T) {
	if err := UninstallDocker(testUser); err != nil {
		t.Errorf("Failed in uninstallation: %v", err)
	}
}
