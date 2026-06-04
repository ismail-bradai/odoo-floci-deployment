# 🚀 Odoo 15 Deployment on Floci (Local AWS Emulator)

## 📋 Overview
Full production-grade Odoo 15 Community deployment on Floci 
simulating AWS cloud architecture with EKS, RDS PostgreSQL, 
S3 Object Storage, K3s node pools, and Nginx Ingress.

---

## 🏗️ Architecture
floci-vm (Ubuntu 22.04 — Multipass)
│
├── Floci (AWS Emulator) :4566
│   ├── S3 → odoo-prod-filestore + odoo-test-filestore
│   ├── EKS → odoo-cluster (K3s)
│   └── RDS → odoo-db (PostgreSQL 16)
│
└── K3s Cluster
├── control-plane (floci-eks-odoo-cluster)
├── nodepool-prod (t3.medium) → Odoo prod pods
└── nodepool-test (t3.small)  → Odoo test pods

---

## ⚙️ Stack

| Service | Technology | Version |
|---------|-----------|---------|
| Odoo | Community | 15.0 |
| Kubernetes | K3s | v1.34.1 |
| Database | PostgreSQL | 16 |
| Object Storage | S3 (Floci) | - |
| Ingress | Nginx Ingress | Latest |
| AWS Emulator | Floci | 1.5.22 |
| Container Runtime | containerd | 2.1.4 |

---

## 📁 Project Structure
floci-odoo/
├── docker-compose.yml        # Main stack (Floci, EKS, node pools)
├── setup-kube.sh             # Auto-setup script (kubectl + PG IP)
├── init/
│   └── setup.sh              # AWS services init (S3, RDS, EKS, IAM)
└── k8s/
├── odoo-prod-secret.yml      # AWS S3 credentials
├── odoo-prod-configmap.yml   # Odoo configuration
├── odoo-prod-deployment.yml  # Odoo deployment (3 replicas)
├── odoo-prod-service.yml     # ClusterIP service
├── odoo-prod-pv-pvc.yml      # Persistent volumes
├── odoo-ingress.yml          # Nginx Ingress rules
└── ...                       # Test environment

---

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04 VM (4 CPUs, 8GB RAM, 40GB disk)
- Docker + Docker Compose v2
- kubectl, helm

### 1. Clone the repository
```bash
git clone https://github.com/ismail-bradai/odoo-floci-deployment.git
cd odoo-floci-deployment
```

### 2. Start the stack
```bash
docker compose up -d
```

### 3. Wait for services to be ready
```bash
# Check nodes
kubectl get nodes -o wide

# Check RDS
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' \
  --output table

# Check S3
aws s3 ls
```

### 4. Deploy Odoo
```bash
cd k8s
kubectl create namespace odoo-prod
kubectl apply -f .
```

### 5. Access Odoo
Add to Windows hosts file:
192.168.2.171    odoo-prod.local
192.168.2.171    odoo-test.local

Open browser: `http://odoo-prod.local`

---

## 🔄 Persistence & Auto-Recovery

| Component | Persistence | Method |
|-----------|-------------|--------|
| PostgreSQL | ✅ | Floci RDS volume `floci-rds-*` |
| S3 Files | ✅ | Floci volume `floci-data:/app/data` |
| EKS State | ✅ | Floci `eks-clusters.json` |
| K8s Deployments | ✅ | Auto-redeploy on startup |
| PG IP | ✅ | Dynamic update via `setup-kube.sh` |

### Auto-start on reboot
```bash
sudo systemctl enable floci-odoo.service
```

---

## 📦 S3 Storage Module

Custom Odoo module `s3_attachment_manager_v2` for S3-only file storage:
- All attachments stored in S3
- No local filestore usage
- Compatible with horizontal pod scaling

---

## 🌐 Node Pools

| Pool | Instance Type | Role | Taint |
|------|--------------|------|-------|
| nodepool-prod | t3.medium | Production | role=prod:NoSchedule |
| nodepool-test | t3.small | Testing | role=test:NoSchedule |

---

## 🔧 Environment Variables

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export KUBECONFIG=/home/ubuntu/.kube/config
```

---

## 📊 Monitoring

```bash
# Cluster status
kubectl get nodes -o wide
kubectl get pods -A

# Resource usage
kubectl top nodes
kubectl top pods -n odoo-prod

# S3 usage
aws s3 ls s3://odoo-prod-filestore --recursive | wc -l
```

---

## 🐛 Known Issues & Solutions

| Issue | Solution |
|-------|----------|
| EKS not in Floci after reboot | Auto-registered via `init/setup.sh` |
| PG IP changes after reboot | Auto-updated via `setup-kube.sh` |
| Node password rejected | Fixed hostname in docker-compose |
| S3 files lost | PERSISTENCE=1 + floci-data volume |

---

## 👤 Author
**Ismail Bradai** — Infrastructure Intern 2026  
[@ismail-bradai](https://github.com/ismail-bradai)

---

## 📄 License
MIT
bash# Créer le README sur la VM
cat > ~/floci-odoo/README.md << 'README'
# 🚀 Odoo 15 Deployment on Floci (Local AWS Emulator)
... (coller le contenu ci-dessus)
README

# Commiter et pusher
cd ~/floci-odoo
git add README.md
git commit -m "docs: add comprehensive README"
git push github main
git push origin dev
