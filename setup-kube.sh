#!/bin/bash
sleep 30

# Configurer kubectl
docker exec floci-eks-odoo-cluster \
  cat /etc/rancher/k3s/k3s.yaml > /home/ubuntu/.kube/config
sed -i "s|https://127.0.0.1:6443|https://localhost:6500|g" \
  /home/ubuntu/.kube/config

sleep 10

# Récupérer l'IP du RDS dynamiquement
PG_IP=$(docker inspect floci-rds-odoo-db \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' \
  2>/dev/null | tr ' ' '\n' | grep -v '^$' | head -1)
echo "PG IP: $PG_IP"

# Mettre à jour le configmap avec la nouvelle IP
if [ -n "$PG_IP" ]; then
  sed -i "s|db_host = .*|db_host = $PG_IP|g" \
    /home/ubuntu/floci-odoo/k8s/odoo-prod-configmap.yml

  # Appliquer le configmap
  kubectl apply -f /home/ubuntu/floci-odoo/k8s/odoo-prod-configmap.yml \
    2>/dev/null || true

  # Redémarrer les pods pour prendre en compte la nouvelle IP
  kubectl rollout restart deployment/odoo-prod -n odoo-prod \
    2>/dev/null || true

  echo "✅ ConfigMap mis à jour avec PG IP: $PG_IP"
fi

# Supprimer les anciens nodes NotReady
for node in $(kubectl get nodes --no-headers 2>/dev/null | \
  grep "NotReady" | awk '{print $1}'); do
  echo "Suppression ancien node: $node"
  kubectl delete node $node 2>/dev/null || true
done

# Port forward Nginx Ingress
pkill -f "port-forward.*ingress-nginx" 2>/dev/null || true
sleep 3
kubectl port-forward \
  -n ingress-nginx \
  service/ingress-nginx-controller \
  80:80 \
  --address=0.0.0.0 &

echo "✅ Setup terminé !"
kubectl get nodes -o wide
