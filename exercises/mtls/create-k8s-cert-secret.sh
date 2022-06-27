#!/usr/bin/env bash

cat << EOF > httpbin-services-mtls.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-ca-cert
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    konghq.com/ca-cert: 'true'
type: Opaque
stringData:
  cert: |
    
  id: cce8c384-721f-4f58-85dd-50834e3e733a
EOF

