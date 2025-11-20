# Blutag Website - Setup Checklist

## ✅ Completed

- [x] GitHub Actions CI/CD workflow created
- [x] Dockerfile with optimized nginx configuration
- [x] GitOps manifests in eladhayun/gitops repository
- [x] ArgoCD application definition
- [x] Terraform outputs for image URLs
- [x] Domain configured: blutag.jshipster.io
- [x] ACR registry: prodacr1234.azurecr.io
- [x] GitHub Secrets configured in repository
- [x] External-DNS controller configured for automatic DNS management

## 🔧 Remaining Setup Steps

### 1. ~~Configure GitHub Secrets~~ ✅ DONE

GitHub Secrets are already configured in the repository with:
- `ACR_REGISTRY_NAME` = prodacr1234
- `ACR_USERNAME` = ACR credentials
- `ACR_PASSWORD` = ACR credentials
- `GITOPS_PAT` = GitHub Personal Access Token

### 2. DNS Configuration (Automated)

DNS is automatically managed by external-dns controller with Cloudflare provider.

The DNS record for `blutag.jshipster.io` will be created automatically when the ingress is deployed.

Verify DNS record creation:

```bash
# Check external-dns logs
kubectl logs -n external-dns -l app=external-dns --tail=50

# Verify DNS propagation (may take 1-2 minutes)
nslookup blutag.jshipster.io
dig blutag.jshipster.io
```

### 3. Verify ArgoCD Application

```bash
# Check if ArgoCD application is created
kubectl get application blutag-website -n argocd

# If not created, apply the manifest
kubectl apply -f gitops/apps/blutag-website.yaml
```

### 4. Initial Deployment

#### Option A: Trigger via Git Push (Recommended)

```bash
cd /path/to/blutag-website
git add .
git commit -m "Initial setup complete"
git push origin main
```

The GitHub Actions workflow will automatically:
1. Run tests
2. Build Docker image
3. Push to ACR
4. Update GitOps repository
5. ArgoCD will sync and deploy

#### Option B: Manual Build and Push

```bash
# Build image
docker build -t prodacr1234.azurecr.io/blutag-website:v1.0.0 .

# Login to ACR
az acr login --name prodacr1234

# Push image
docker push prodacr1234.azurecr.io/blutag-website:v1.0.0

# Update deployment
cd /path/to/gitops/blutag-website
sed -i 's|image: prodacr1234.azurecr.io/blutag-website:.*|image: prodacr1234.azurecr.io/blutag-website:v1.0.0|g' deployment.yaml
git add deployment.yaml
git commit -m "Initial deployment v1.0.0"
git push
```

### 5. Verify TLS Certificate

After deployment, check if cert-manager created the TLS certificate:

```bash
# Check certificate status
kubectl get certificate blutag-website-tls

# Should show READY=True after a few minutes
# NAME                   READY   SECRET                 AGE
# blutag-website-tls     True    blutag-website-tls     2m
```

If certificate is not ready:

```bash
# Check certificate details
kubectl describe certificate blutag-website-tls

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

## 🧪 Testing

### Test Local Build

```bash
# Build and run locally
docker build -t blutag-website-test .
docker run -p 8080:80 blutag-website-test

# Test in browser
open http://localhost:8080

# Test health endpoint
curl http://localhost:8080/health
```

### Test Production Deployment

```bash
# Check pods
kubectl get pods -l app=blutag-website

# Check logs
kubectl logs -l app=blutag-website --tail=50

# Test service
kubectl port-forward service/blutag-website 8080:80
open http://localhost:8080

# Test production URL (after DNS is configured)
curl -I https://blutag.jshipster.io
```

## 🔍 Verification Commands

```bash
# Check ArgoCD sync status
kubectl get application blutag-website -n argocd
kubectl describe application blutag-website -n argocd

# Check deployment
kubectl get deployment blutag-website
kubectl describe deployment blutag-website

# Check service
kubectl get service blutag-website
kubectl describe service blutag-website

# Check ingress
kubectl get ingress blutag-website
kubectl describe ingress blutag-website

# Check pods
kubectl get pods -l app=blutag-website
kubectl logs -l app=blutag-website --tail=100

# Test from inside cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside the pod:
apk add curl
curl http://blutag-website.default.svc.cluster.local
```

## 📈 Monitoring

### GitHub Actions

Monitor CI/CD pipelines: https://github.com/eladhayun/blutag-website/actions

### ArgoCD Dashboard

If ArgoCD UI is available, check: http://argocd.yourdomain.com/applications/blutag-website

### Kubernetes

```bash
# Watch pods
kubectl get pods -l app=blutag-website -w

# Watch events
kubectl get events --sort-by='.lastTimestamp' | grep blutag-website
```

## 🐛 Common Issues

### Issue: GitHub Actions fails to push to GitOps repo
**Solution**: Verify `GITOPS_PAT` secret has correct permissions (repo scope)

### Issue: Pods in ImagePullBackOff
**Solution**: Verify AKS can pull from ACR:
```bash
az aks check-acr --name prod-aks --resource-group prod-rg --acr prodacr1234.azurecr.io
```

### Issue: TLS certificate not issuing
**Solution**: 
1. Check cert-manager is installed
2. Verify letsencrypt-prod ClusterIssuer exists
3. Check DNS is pointing to correct IP

### Issue: Website returns 404
**Solution**: 
1. Check nginx logs: `kubectl logs -l app=blutag-website`
2. Verify static files are copied in Dockerfile
3. Test locally with Docker

## 📝 Next Steps

After successful deployment:

1. Set up monitoring/alerting
2. Configure backup strategy
3. Document any custom configurations
4. Set up staging environment
5. Configure automated security scanning

## 🎉 Success Criteria

Deployment is successful when:

- [ ] GitHub Actions workflow runs without errors
- [ ] Docker image is in ACR: `az acr repository show-tags --name prodacr1234 --repository blutag-website`
- [ ] Pods are running: `kubectl get pods -l app=blutag-website` shows 2/2 READY
- [ ] Service is accessible: `kubectl get service blutag-website` shows ClusterIP
- [ ] Ingress is configured: `kubectl get ingress blutag-website` shows ADDRESS
- [ ] TLS certificate is ready: `kubectl get certificate blutag-website-tls` shows READY=True
- [ ] Website loads: `curl -I https://blutag.jshipster.io` returns 200 OK
- [ ] HTTPS redirects work: `curl -I http://blutag.jshipster.io` redirects to HTTPS
- [ ] Health endpoint responds: `curl https://blutag.jshipster.io/health` returns "healthy"

