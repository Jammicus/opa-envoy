kubectl apply opa-policy -f services/ping/policy.rego -n ping
kubectl apply opa-policy -f services/pong/policy.rego -n pong