# GKE LB on Cloud Run

Simple, auto-configuring, auto-scaling nginx container acting as a load balancer for your GKE node pool. Expose your GKE ingress controller/edge proxy without paying $18/month for a GCP LB.

[![Run on Google Cloud](https://deploy.cloud.run/button.svg)](https://deploy.cloud.run)

## Configuration (env vars)
```
GKE_CLUSTER (required) - name of your GKE cluster
GKE_NODE_POOL (required) - name of your GKE node pool
GKE_NODE_PORT (required) - node port of your ingress controller/edge proxy

NGINX_TIMEOUT (optional, default 30s) - nginx timeout for proxy_pass
NGINX_PROTOCOL (optional, default http) - nginx protocol for proxy_pass (set to 'https' if your ingress controller/edge proxy is listening over TLS)
CHECK_INTERVAL (optional, default 30) - seconds between checks of GKE node pool IP changes
```

## Setup

### Build container
```
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
gcloud beta run deploy run-gke-lb --image eu.gcr.io/YOUR_PROJECT/run-gke-lb \
  --region europe-west1 \
  --platform managed \
  --allow-unauthenticated \
  --service-account run-gke-lb@YOUR_PROJECT.iam.gserviceaccount.com \
  --concurrency 50 \
  --timeout 30 \
  --memory 128Mi \
  --update-env-vars GKE_CLUSTER=YOUR_CLUSTER,GKE_NODE_POOL=YOUR_NODE_POOL,GKE_NODE_PORT=YOUR_NODE_PORT \
  --project YOUR_PROJECT
```

### Custom domain
Follow https://cloud.google.com/run/docs/mapping-custom-domains
