#!/bin/sh
echo "=== Init AWS Services ==="

# S3
aws s3 mb s3://odoo-prod-filestore 2>/dev/null || true
aws s3 mb s3://odoo-test-filestore 2>/dev/null || true
echo "✅ S3 OK"

# IAM
aws iam create-role \
  --role-name eks-cluster-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  2>/dev/null || true
echo "✅ IAM OK"

# RDS
RDS_STATUS=$(aws rds describe-db-instances \
  --db-instance-identifier odoo-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text 2>/dev/null)

if [ "$RDS_STATUS" != "available" ]; then
  aws rds create-db-instance \
    --db-instance-identifier odoo-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --engine-version "16" \
    --master-username odoo_admin \
    --master-user-password "Valorant#12345" \
    --allocated-storage 20 \
    --db-name postgres \
    --no-multi-az \
    --publicly-accessible 2>/dev/null || true

  WAIT=0
  while [ $WAIT -lt 60 ]; do
    STATUS=$(aws rds describe-db-instances \
      --db-instance-identifier odoo-db \
      --query 'DBInstances[0].DBInstanceStatus' \
      --output text 2>/dev/null)
    if [ "$STATUS" = "available" ]; then
      break
    fi
    echo "  Attente RDS..."
    sleep 5
    WAIT=$((WAIT + 5))
  done
fi

echo "✅ RDS OK"
echo "=== ✅ Init terminé ! ==="
aws s3 ls

# EKS — enregistrer le cluster dans Floci
EKS_STATUS=$(aws eks describe-cluster \
  --name odoo-cluster \
  --query 'cluster.status' \
  --output text 2>/dev/null)

if [ "$EKS_STATUS" != "ACTIVE" ]; then
  echo "Enregistrement cluster EKS dans Floci..."
  aws eks create-cluster \
    --name odoo-cluster \
    --role-arn arn:aws:iam::000000000000:role/eks-cluster-role \
    --resources-vpc-config subnetIds=subnet-00000001,securityGroupIds=sg-00000001 \
    2>/dev/null || true
fi

aws eks describe-cluster \
  --name odoo-cluster \
  --query 'cluster.[name,status]' \
  --output table 2>/dev/null
echo "✅ EKS enregistré dans Floci"
