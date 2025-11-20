# Blutag Website

Static website for Blutag, served with nginx and deployed to Kubernetes via ArgoCD.

## 🌐 Deployment

- **Production URL**: https://blutag.jshipster.io
- **Container Registry**: prodacr1234.azurecr.io/blutag-website
- **Kubernetes Namespace**: default

## 🏗️ Architecture

- **Frontend**: Static HTML/CSS/JavaScript
- **Web Server**: nginx (Alpine Linux)
- **CI/CD**: GitHub Actions
- **GitOps**: ArgoCD
- **Infrastructure**: Azure Kubernetes Service (AKS)

## 🌐 DNS Management

DNS is automatically managed by [external-dns](https://github.com/kubernetes-sigs/external-dns) controller with Cloudflare provider. When the ingress is deployed, external-dns automatically creates/updates the DNS A record for `blutag.jshipster.io` pointing to the ingress controller's load balancer IP.

No manual DNS configuration is required.

## 🔧 Local Development

### Run locally with Docker

```bash
# Build the Docker image
docker build -t blutag-website .

# Run the container
docker run -p 8080:80 blutag-website

# Open browser
open http://localhost:8080
```

### Run locally with a simple HTTP server

```bash
# Using Python
python3 -m http.server 8080

# Using Node.js
npx http-server -p 8080
```

## 🚀 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) automatically:

1. **Test**: Validates HTML files
2. **Build**: Creates Docker image
3. **Push**: Pushes to Azure Container Registry
4. **Deploy**: Updates GitOps repository with new image tag

### Required GitHub Secrets

Configure these secrets in the GitHub repository settings:

- `ACR_REGISTRY_NAME`: `prodacr1234`
- `ACR_USERNAME`: Azure Container Registry username
- `ACR_PASSWORD`: Azure Container Registry password
- `GITOPS_PAT`: GitHub Personal Access Token with repo access to eladhayun/gitops

### Triggering Deployments

Deployments are triggered automatically on:
- Push to `main` branch
- Pull requests to `main` (test only, no deployment)

## 📦 Docker Image

The Dockerfile includes:
- nginx Alpine Linux base image
- Optimized nginx configuration with:
  - Gzip compression
  - Static asset caching
  - Security headers
  - Health check endpoint

### Health Check

```bash
curl http://blutag.jshipster.io/health
```

## 🔐 GitOps Repository

Kubernetes manifests are stored in the [eladhayun/gitops](https://github.com/eladhayun/gitops) repository:

- `blutag-website/deployment.yaml` - Kubernetes Deployment
- `blutag-website/service.yaml` - Kubernetes Service
- `blutag-website/ingress.yaml` - Ingress with TLS
- `apps/blutag-website.yaml` - ArgoCD Application

## 🔄 Manual Deployment

If you need to manually update the deployment:

```bash
# Build and tag image
docker build -t prodacr1234.azurecr.io/blutag-website:manual .

# Login to ACR
az acr login --name prodacr1234

# Push image
docker push prodacr1234.azurecr.io/blutag-website:manual

# Update deployment in gitops repo
cd /path/to/gitops/blutag-website
sed -i 's|image: prodacr1234.azurecr.io/blutag-website:.*|image: prodacr1234.azurecr.io/blutag-website:manual|g' deployment.yaml
git add deployment.yaml
git commit -m "Manual deployment"
git push
```

## 📊 Monitoring

Check deployment status in ArgoCD:

```bash
kubectl get application blutag-website -n argocd
```

Check pods:

```bash
kubectl get pods -l app=blutag-website
kubectl logs -l app=blutag-website
```

## 🛠️ Troubleshooting

### Website not loading

1. Check pod status:
```bash
kubectl get pods -l app=blutag-website
kubectl describe pod -l app=blutag-website
```

2. Check ingress:
```bash
kubectl get ingress blutag-website
kubectl describe ingress blutag-website
```

3. Check ArgoCD sync status:
```bash
kubectl get application blutag-website -n argocd
```

### Image pull errors

Verify AKS has access to ACR:
```bash
az aks check-acr --name prod-aks --resource-group prod-rg --acr prodacr1234.azurecr.io
```

## 📝 License

Copyright © 2025 Blutag

