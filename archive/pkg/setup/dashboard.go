package setup

import (
	"fmt"
	"time"

	"github.com/yxun/util-shell/sh"
)

var (
	dashboardYaml string = fmt.Sprintf("https://raw.githubusercontent.com/kubernetes/dashboard/%s/aio/deploy/recommended.yaml",
		dashboardVersion)
	dashboardURL string = fmt.Sprintf("http://%s:%s/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/", testHost, proxyPort)
)

// InstallDashboard ...
func InstallDashboard() error {
	sh.Shell("kubectl apply -f %s", dashboardYaml)
	CheckPodRunning("kubernetes-dashboard", "k8s-app=dashboard-metrics-scraper")
	CheckPodRunning("kubernetes-dashboard", "k8s-app=kubernetes-dashboard")

	sh.Shell("kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default")
	sh.ShellBackground("kubectl proxy --port=%s", proxyPort)
	log.Info("Access token")
	sh.Shell("kubectl get secrets -o jsonpath=\"{.items[?(@.metadata.annotations['kubernetes\\.io/service-account\\.name']=='default')].data.token}\"|base64 -d")
	log.Infof("dashboard URL: %s", dashboardURL)
	log.Info("Remote access: check sshd AllowTcpForwarding yes")
	log.Infof("Remote access ssh local forward: ssh -f -N -L [localport]:localhost:%s %s", proxyPort, testHost)
	time.Sleep(5 * time.Second)
	_, err := sh.Shell("netstat -anp | grep %s", proxyPort)
	return err
}

// UninstallDashboard ...
func UninstallDashboard() error {
	sh.Shell("kill $(lsof -t -i:%s)", proxyPort)
	sh.Shell("kubectl delete clusterrolebinding default-admin")
	_, err := sh.Shell("kubectl delete -f %s", dashboardYaml)
	return err
}
