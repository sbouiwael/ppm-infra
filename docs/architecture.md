# Architecture étendue — extensions cloud

Ce document décrit comment la couche `ppm-infra` actuelle (locale, portable)
s'étend vers un cloud cible *une fois la décision prise*. Aucun de ces
fichiers n'existe encore : ils sont posés ici comme plan de route.

## 1. Carte d'extension

```
terraform/envs/
  ├── local/         ← présent aujourd'hui
  ├── aws/           ← à créer après choix
  ├── azure/         ← à créer après choix
  └── gcp/           ← à créer après choix

terraform/modules/
  ├── namespaces/        ← réutilisable tel quel
  ├── argocd/            ← réutilisable tel quel
  ├── ingress-nginx/     ← garder, ou remplacer par le LB cloud
  ├── mysql-local/       ← NE PAS utiliser en cloud (DB managée à la place)
  ├── ppm-secrets/       ← à remplacer par external-secrets
  ├── app-of-apps/       ← réutilisable tel quel
  │
  ├── aws-eks/           ← futur — créé après choix AWS
  ├── aws-rds-mysql/     ← futur
  ├── aws-s3-uploads/    ← futur — remplace PVC RWO
  ├── aws-ecr/           ← futur — registry alternatif à GHCR
  ├── azure-aks/         ← idem famille Azure
  ├── azure-database/
  ├── azure-blob/
  ├── azure-acr/
  ├── gcp-gke/           ← idem famille GCP
  ├── gcp-cloudsql/
  ├── gcp-gcs/
  ├── gcp-gar/
  └── external-secrets/  ← commun aux trois clouds, branchement via SecretStore
```

## 2. Chemin de migration applicative

### 2.1 Storage des uploads (PVC RWO → object storage)

Aujourd'hui : `Deployment ppm-backend` monte un PVC `ReadWriteOnce`
sur `/app/projects`. Conséquence : **HPA bloqué à 1 réplique**.

Cible :

1. Ajouter un module `<cloud>-object-storage` qui provisionne le bucket
   + un ServiceAccount IAM (IRSA / Workload Identity / Federated Identity).
2. Modifier `ppm-backend` pour écrire dans le bucket via un client S3
   abstrait (Spring `S3Client`). Continuer à monter le PVC en transition
   le temps de migrer les fichiers existants.
3. Désactiver le PVC (`persistence.enabled=false`) après migration.
4. Activer HPA (`autoscaling.enabled=true`, `minReplicas=2`).

### 2.2 Base MySQL (Bitnami local → DB managée)

`mysql-local` n'est qu'un *helper de dev*. En cloud :

```hcl
module "rds" {
  source         = "../../modules/aws-rds-mysql"
  instance_class = "db.t4g.small"
  storage_gb     = 50
  vpc_id         = var.vpc_id
  subnet_ids     = var.private_subnet_ids
}
```

Le `Secret` `ppm-backend-secrets-<env>` est alors géré par
External Secrets Operator (ESO) avec un `SecretStore` qui pointe
vers le secret manager cloud — `db_password` n'est JAMAIS touché
par Terraform.

### 2.3 Ingress de production

Trois options selon le provider :

| Cloud | Ingress |
|---|---|
| AWS | `aws-load-balancer-controller` + ALB ingress class |
| Azure | `application-gateway-kubernetes-ingress` ou ingress-nginx + AGIC |
| GCP | GKE Ingress (`kubernetes.io/ingress.class: gce`) |

Chacun se branche en mettant `ingress.className` dans les
`values-<env>.yaml` (déjà paramétré dans les charts).

### 2.4 TLS

Cert-manager + Let's Encrypt (DNS-01 challenge sur le DNS cloud).
Module `cert-manager` à ajouter, `ClusterIssuer` par environnement.
Les charts ont déjà des blocs `tls:` prêts à recevoir un `secretName`.

## 3. Ce qu'on ne touche jamais

- Le contrat `promote-test` sur `values-test.yaml` (cf. README §6).
- L'organisation du chart Helm (déjà cloud-friendly via annotations
  ServiceAccount et StorageClass override).
- Le pipeline CI/CD : il continue de pousser sur GHCR et de bumper
  `values-test.yaml`. Si on choisit un autre registry, seul l'étape
  `Login to registry` du workflow change.
