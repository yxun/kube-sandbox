package k8s

type system interface{}

type linux struct{}
type fedora struct{}
type mac struct{}
type windows struct{}

var (
	testLinux  = &linux{}
	testFedora = &fedora{}
)
