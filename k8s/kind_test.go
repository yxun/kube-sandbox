package k8s

import (
	"testing"
)

const (
	testCluster string = "kindTest"
)

func TestInstallKind(t *testing.T) {
	if err := InstallKind(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestUninstallKind(t *testing.T) {
	if err := UninstallKind(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestCreateKindCluster(t *testing.T) {
	if err := CreateKindCluster(testCluster); err != nil {
		t.Errorf("Failed: %v", err)
	}
}

func TestDeleteKindCluster(t *testing.T) {
	if err := DeleteKindCluster(testCluster); err != nil {
		t.Errorf("Failed: %v", err)
	}
}
