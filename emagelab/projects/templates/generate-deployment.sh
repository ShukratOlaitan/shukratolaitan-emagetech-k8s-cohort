#!/bin/bash
set -e

echo "=================================================="
echo "      Kubernetes Deployment YAML Generator"
echo "=================================================="
echo ""

# Prompt for configuration values with sensible defaults
read -p "Enter Application Name [my-app]: " APP_NAME
APP_NAME=${APP_NAME:-my-app}

read -p "Enter Namespace [default]: " NAMESPACE
NAMESPACE=${NAMESPACE:-default}

read -p "Enter Container Image (e.g., nginx:1.25.4) [nginx:1.25.4]: " IMAGE
IMAGE=${IMAGE:-nginx:1.25.4}

read -p "Enter Replica Count [2]: " REPLICAS
REPLICAS=${REPLICAS:-2}

read -p "Enter CPU Request [100m]: " CPU_REQ
CPU_REQ=${CPU_REQ:-100m}

read -p "Enter Memory Request [128Mi]: " MEM_REQ
MEM_REQ=${MEM_REQ:-128Mi}

read -p "Enter CPU Limit [500m]: " CPU_LIMIT
CPU_LIMIT=${CPU_LIMIT:-500m}

read -p "Enter Memory Limit [256Mi]: " MEM_LIMIT
MEM_LIMIT=${MEM_LIMIT:-256Mi}

# Define output filename
OUTPUT_FILE="${APP_NAME}-deployment.yaml"

# Write out the filled-in Kubernetes Deployment manifest
cat <<EOF > "$OUTPUT_FILE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
    version: "1.0.0"
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${APP_NAME}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  revisionHistoryLimit: 3
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      terminationGracePeriodSeconds: 30
      containers:
        - name: ${APP_NAME}
          image: ${IMAGE}
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "${CPU_REQ}"
              memory: "${MEM_REQ}"
            limits:
              cpu: "${CPU_LIMIT}"
              memory: "${MEM_LIMIT}"
          readinessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 20
EOF

echo ""
echo "=================================================="
echo " Success! Generated deployment manifest: ${OUTPUT_FILE}"
echo "=================================================="