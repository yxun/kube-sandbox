package k8s

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/yxun/util-shell/sh"
)

const (
	podFailedGet string = "Failed_Get"
	// The index of STATUS field in kubectl CLI output.
	statusField int = 2
	// backoff increases by this factor on each retry
	backoffFactor float64 = 1.3
)

// Break the retry loop if the error returned is of this type.
type Break struct {
	Err error
}

func (e Break) Error() string {
	return e.Err.Error()
}

// Retrier contains the retry configuration parameters
type Retrier struct {
	// BaseDelay is the minimum delay between retry attempts.
	BaseDelay time.Duration
	// MaxDelay is the maximum delay allowed between retry attempts.
	MaxDelay time.Duration
	// MaxDuration is the maximum cumulative duration allowed for all retries.
	MaxDuration time.Duration
	// Retries defines number of retry attempts
	Retries int
}

// Backoff returns a random value in [0, maxDelay] that increases exponetially retries.
// It is the Go equivalent to C++'s //util/time/backoff.cc
func Backoff(baseDelay, maxDelay time.Duration, retries int) time.Duration {
	backoff, max := float64(baseDelay), float64(maxDelay)
	for backoff < max && retries > 0 {
		backoff *= backoffFactor
		retries--
	}
	if backoff > max {
		backoff = max
	}

	if backoff < 0 {
		return 0
	}
	return time.Duration(backoff)
}

// Retry calls the given function a number of times, unless it returns a nil or a Break
func (r Retrier) Retry(ctx context.Context, fn func(ctx context.Context, retryIndex int) error) (int, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if r.MaxDuration > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, r.MaxDuration)
		defer cancel()
	}

	var err error
	var i int
	if r.Retries <= 0 {
		log.Warnf("retries must to be >= 1. Got %d, setting to 1", r.Retries)
		r.Retries = 1
	}
	for i = 1; i <= r.Retries; i++ {
		err = fn(ctx, i)
		if err == nil {
			return i, nil
		}
		if be, ok := err.(Break); ok {
			return i, be.Err
		}

		select {
		case <-ctx.Done():
			return i - 1, ctx.Err()
		case <-time.After(Backoff(r.BaseDelay, r.MaxDelay, i)):
		}
	}
	return i - 1, err
}

// GetPodName gets the pod name for the given namespace and label selector
func GetPodName(n, labelSelector string) (pod string, err error) {
	pod, err = sh.Shell("kubectl -n %s get pod -l %s -o jsonpath='{.items[0].metadata.name}'", n, labelSelector)
	if err != nil {
		log.Errorf("could not get %s pod: %v", labelSelector, err)
		return "", err
	}
	pod = strings.Trim(pod, "'")
	log.Infof("%s pod name: %s", labelSelector, pod)
	return pod, nil
}

// GetPodStatus gets status of a pod from a namespace
func GetPodStatus(n, pod string) string {
	status, err := sh.Shell("kubectl -n %s get pods %s --no-headers", n, pod)
	if err != nil {
		log.Errorf("Failed to get status of pod %s in namespace %s: %s", pod, n, err)
		status = podFailedGet
	}
	f := strings.Fields(status)
	if len(f) > statusField {
		return f[statusField]
	}
	return ""
}

// CheckPodRunning return if a given pod with labeled name in a namespace are in "Running" status
func CheckPodRunning(n, name string) error {
	retry := Retrier{
		BaseDelay: 10 * time.Second,
		MaxDelay:  30 * time.Second,
		Retries:   6,
	}

	retryFn := func(_ context.Context, i int) error {
		pod, err := GetPodName(n, name)
		if err != nil {
			return err
		}
		ready := true
		if status := GetPodStatus(n, pod); status != "Running" {
			log.Infof("%s in namespace %s is not running: %s", pod, n, status)
			ready = false
		}

		if !ready {
			return fmt.Errorf("pod %s is not ready", pod)
		}
		return nil
	}

	ctx := context.Background()
	_, err := retry.Retry(ctx, retryFn)
	if err != nil {
		return err
	}
	log.Infof("Got the pod name=%s running.", name)
	return nil
}
