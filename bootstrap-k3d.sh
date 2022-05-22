k3d cluster create envoy -p "8080:30080@agent:0" --agents 2

kubectl create ns ping

kubectl create deployment ingess-nginx --image=nginx



kubectl wait --namespace ingress-nginx \
  --for=condition=ready deployment \
  --selector=app=nginx \
  --timeout=90s

# Should get from the server rather than be secrets
kubectl create secret generic opa-policy --from-file services/ping/policy.rego -n ping


kubectl create configmap proxy-config --from-file services/ping/envoy.yaml -n ping

kubectl apply -f services/ping/deployment.yaml
kubectl apply -f services/ping/svc.yaml
kubectl apply -f services/ping/ingress.yaml

echo "Waiting for components to become ready"
kubectl wait --for=condition=available --timeout=300s deployment/ping-server -n ping
sleep 15


# should pass
curl -ivvv  http://127.0.0.1:8080/ping
# should fail
curl -ivvv  http://127.0.0.1:8080/pong