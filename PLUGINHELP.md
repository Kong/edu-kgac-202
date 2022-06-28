## Replicate MTLS failure to enforce

We use scripts to deploy the cluster inside our vendor's environment and we search the local hosts file for a kongcluster entry to use the IP as the host of the k8s cluster for testing local ingress. 

1. Clone the repo
```bash
git clone https://github.com/Kong/kong-course-gateway-ops-for-kubernetes.git
cd kong-course-gateway-ops-for-kubernetes
```

2. Deploy the Kind Cluster (Optional + possible local config changes)
Note:  Review the script in automation/install.sh to see the kind config.  This is designed to be run inside our vendor's environment.  Skip this step if you already have a cluster

Examine the scripts below if you want to modify for your own environment and use.
```bash
vi base/install.sh
vi base/patch.sh
# source base/reset-kongcluster.sh
```

3. Be sure the httpbin app in the cluster is running
```bash
kubectl apply -f base/httpbin.yaml
```

4. Create a certificate
Note:  Examine the script and adjust the location of where the cert is being created.  We need a cert to inject into k8s to be absorbed then by the plugin CRD.
```bash
cd exercises/mtls/
vi create-certificate.sh
./create-certificate.sh
```

5. Create the service and route:
```bash
kubectl apply -f ./httpbin-ingress.yaml
# Test the app with kongcluster being your node IP
http get kongcluster:30000/ip
http get kongcluster:30000/uuid
```

6. Configure mtls for httpbin ingress
Note:  Update the path to the cert in your environment for upload to k8s
```bash
kubectl create secret generic httpbin-mtls \
  --from-literal=id=cce8c384-721f-4f58-85dd-50834e3e733a \
  --from-file=cert=/home/labuser/.certificates/ca.cert.pem \
  -o yaml --dry-run=client > ./httpbin-mtls-secret.yaml
kubectl apply -f ./httpbin-mtls-secret.yaml
kubectl label secret httpbin-mtls konghq.com/ca-cert='true'
kubectl annotate secret httpbin-mtls kubernetes.io/ingress.class=kong
kubectl apply -f ./httpbin-ingress-mtls.yaml
```

7. Verification
Note:  Here we should be getting 401s now since the mtls is applied.  Verify in your Kong Manager to see how the mtls is applied to the route.  The issue is we still get 200s for both.
```bash
http get kongcluster:30000/ip
http get kongcluster:30000/uuid
```
