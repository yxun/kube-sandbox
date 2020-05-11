package install

type system interface{}

type linux struct{}
type fedora struct{}
type mac struct{}
type windows struct{}

var (
	testLinux  = &linux{}
	testFedora = &fedora{}
)
