package k8s

import (
	"testing"
)

func TestInstallMinikube(t *testing.T) {
	if err := testLinux.InstallMinikube(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestUninstallMinikube(t *testing.T) {
	if err := testLinux.UninstallMinikube(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestCreateMinikubeCluster(t *testing.T) {
	if err := testLinux.CreateMinikubeCluster(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestDeleteMinikubeCluster(t *testing.T) {
	if err := testLinux.DeleteMinikubeCluster(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}
