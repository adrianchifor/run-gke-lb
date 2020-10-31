# GKE LB on Cloud Run

[![Docker](https://github.com/adrianchifor/run-gke-lb/workflows/Publish%20Docker/badge.svg)](https://github.com/adrianchifor/run-gke-lb/actions?query=workflow%3A%22Publish+Docker%22)

Simple, auto-configuring, auto-scaling nginx container acting as a load balancer for your GKE node pool. Expose your GKE ingress controller/edge proxy without paying $18/month for a GCP LB.

[![Run on Google Cloud](https://deploy.cloud.run/button.svg)](https://deploy.cloud.run)

## Configuration (env vars)

```
GKE_CLUSTER (required) - name of your GKE cluster
GKE_NODE_POOL (required) - name of your GKE node pool
GKE_NODE_PORT (required) - node port of your ingress controller/edge proxy

PRIVATE_CLUSTER (optional, default false) - if true it will use the private IPs of the GKE nodes, needs Serverless VPC Access Connector
NGINX_TIMEOUT (optional, default 30s) - nginx timeout for proxy_pass
NGINX_PROTOCOL (optional, default http) - nginx protocol for proxy_pass (set to 'https' if your ingress controller/edge proxy is listening over TLS)
HEALTH_CHECK_TIMEOUT (optional, default 5) - node heath check timeout; if HC fails, node is removed from nginx upstream list until it's back online
CHECK_INTERVAL (optional, default 30) - seconds between checks of GKE node pool IP changes
```

## Setup

### Build container

```
echo "FROM adrianchifor/run-gke-lb:latest" > Dockerfile
gcloud builds submit --tag eu.gcr.io/YOUR_PROJECT/run-gke-lb . --project YOUR_PROJECT
```

### IAM service account

```
gcloud iam service-accounts create run-gke-lb --project YOUR_PROJECT

gcloud projects add-iam-policy-binding YOUR_PROJECT \
  --member='serviceAccount:run-gke-lb@YOUR_PROJECT.iam.gserviceaccount.com' \
  --role='roles/compute.viewer' \
  --project YOUR_PROJECT
```

### Deploy container

```
gcloud run deploy run-gke-lb \
  --image eu.gcr.io/YOUR_PROJECT/run-gke-lb \
  --region europe-west1 \
  --platform managed \
  --allow-unauthenticated \
  --service-account run-gke-lb@YOUR_PROJECT.iam.gserviceaccount.com \
  --concurrency 50 \
  --timeout 30 \
  --memory 256Mi \
  --update-env-vars GKE_CLUSTER=YOUR_CLUSTER,GKE_NODE_POOL=YOUR_NODE_POOL,GKE_NODE_PORT=YOUR_NODE_PORT \
  --project YOUR_PROJECT
```

If you have a private GKE cluster, you can create a [Serverless VPC Access Connector](https://cloud.google.com/vpc/docs/configure-serverless-vpc-access) and link it to the `run-gke-lb` Cloud Run service by adding:

```
gcloud beta run deploy run-gke-lb \
  ...
  --vpc-connector CONNECTOR_NAME \
  --update-env-vars ... PRIVATE_CLUSTER=true
```

### Custom domain
Follow https://cloud.google.com/run/docs/mapping-custom-domains
