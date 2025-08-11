package client

import (
	"testing"
)

func TestNumberOfPods(t *testing.T) {
	if err := CheckNumberOfPods(); err != nil {
		t.Errorf("Failed: %v", err)
	}
}
