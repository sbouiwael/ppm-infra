# ppm-infra — Couche IaC portable pour PPM BIAT

> **Mémoire de fin d'études — PPM (Project Portfolio Management).**
> Cette couche Infrastructure-as-Code amène un cluster Kubernetes *vide*
> à un cluster *complètement gouverné par GitOps* en une seule commande.
> Volontairement **portable** : tourne en Minikube en local et reste
> valide sur n'importe quel cluster managé (EKS / GKE / AKS / OpenShift)
> sans changer une ligne de Terraform.

---

## 1. Pourquoi cette couche existe

Avant `ppm-infra`, le projet avait :

- `ppm-backend` (Spring Boot) et `ppm-frontend` (Angular) avec leurs
  pipelines GitHub Actions « 10/10 » (test → trivy → docker → SBOM →
  cosign → SLSA → promote-test).
- `ppm-gitops` avec les charts Helm et les `Application` Argo CD pour
  test/staging/prod.

**Trou** : la procédure pour passer d'un kubeconfig vide à un cluster
qui fait tourner PPM tenait dans un README de 30 lignes,
manuelle et propre à chaque environnement. Démontrer le projet en
soutenance impliquait de bricoler des `kubectl apply` à la main.

`ppm-infra` couvre ce trou : **un seul `terraform apply` boostrappe
l'ensemble** et c'est ensuite Argo CD qui maintient le cluster
synchronisé sur `ppm-gitops`.

## 2. Contraintes que respecte cette couche

| Règle | Comment elle est respectée |
|---|---|
| Aucun secret réel dans Git | `*.tfvars` gitignored ; les secrets sont générés par `random_password` à l'`apply` et matérialisés en `Secret` Kubernetes. Le `tfstate` reste local (jamais commité). |
| Pas de Terraform cloud | Providers utilisés : `kubernetes`, `helm`, `kubectl`, `random`. **Aucun** `aws/azurerm/google` ou équivalent. |
| Pas de TLS / DNS public / LB cloud | `ingress-nginx` exposé en `NodePort` (configurable). `argocd-server` en `ClusterIP` + `--insecure`. Ingress applicatif désactivé en local — accès par `kubectl port-forward`. |
| Ne pas casser les pipelines CI/CD | `values-test.yaml` (backend & frontend) **non modifiés**. Le contrat `sed` du job `promote-test` (`^  tag:.*` ligne unique à 2 espaces) est inchangé. Les fichiers nouveaux sont `values-local.yaml`, isolés. |
| Respecter le contrat `promote-test` | Voir §6 ci-dessous. |

## 3. Architecture cible (local)

```
                              ┌─────────────────────────────────┐
                              │  GitHub : ppm-gitops (vérité)   │
                              └──────────────┬──────────────────┘
                                             │   git pull (Argo CD)
                                             ▼
   ┌────────────────────────────────────────────────────────────────┐
   │  Cluster Kubernetes (Minikube par défaut, n'importe quel cluster)
   │                                                                  │
   │   ┌──────────────┐    ┌──────────────────────────────────────┐   │
   │   │  argocd ns   │───▶│  Application: ppm-apps-local         │   │
   │   │  (Helm)      │    │   └─ child: ppm-backend-local        │   │
   │   └──────────────┘    │   └─ child: ppm-frontend-local       │   │
   │                       └──────────────────────────────────────┘   │
   │                                       │                          │
   │   ┌────────────────┐  ┌──────────────────────────────────────┐   │
   │   │ ingress-nginx  │  │  ppm-local ns                        │   │
   │   │   ns (Helm)    │  │   ├─ ppm-backend  (Spring Boot 3.5)  │   │
   │   │   NodePort     │  │   ├─ ppm-frontend (Angular + Nginx)  │   │
   │   │   30080/30443  │  │   └─ ppm-mysql    (Bitnami chart)    │   │
   │   └────────────────┘  │   Secret: ppm-backend-secrets-local  │   │
   │                       └──────────────────────────────────────┘   │
   │                                                                  │
   └────────────────────────────────────────────────────────────────┘
                              ▲
                              │ terraform apply (envs/local)
                              │
              ┌───────────────┴────────────────┐
              │  ppm-infra (cette repo)        │
              │   modules/                     │
              │     ├─ namespaces              │
              │     ├─ argocd                  │
              │     ├─ ingress-nginx           │
              │     ├─ mysql-local             │
              │     ├─ ppm-secrets             │
              │     └─ app-of-apps             │
              │   envs/local/                  │
              └────────────────────────────────┘
```

Argo CD gouverne les workloads applicatifs. Terraform gouverne la
plate-forme (CRDs, secrets, ingress, DB locale) — c'est le pattern
*"Terraform pour ce qui doit exister avant le GitOps,
GitOps pour le reste"*.

## 4. Démarrage rapide (Minikube)

Pré-requis : `minikube`, `kubectl`, `terraform >= 1.5`, `helm` *(optionnel : Helm est invoqué par Terraform, mais utile pour le debug)*.

```bash
# 1. Cluster vierge
make minikube-up

# 2. Bootstrap (env local)
make bootstrap

# 3. Mot de passe Argo CD
make argocd-password

# 4. Tunnels (UI Argo CD + frontend + backend)
make port-forward
#   → http://localhost:8080  Argo CD (admin)
#   → http://localhost:4200  Frontend
#   → http://localhost:8082  Backend (Actuator)

# 5. Suivre la sync GitOps
make sync-status
```

Tear-down :

```bash
make destroy        # supprime tout ce que Terraform a créé
make minikube-stop  # garde le profil (rapide à relancer)
make minikube-delete  # supprime aussi le profil
```

## 5. Démarrage sur un autre cluster

Aucune modification de Terraform n'est requise. Il suffit de pointer
les providers sur le bon contexte kubeconfig :

```bash
export TF_VAR_kube_context=<your-context>          # ex: kind-ppm, docker-desktop, eks-ppm
export TF_VAR_install_ingress_nginx=false          # si le cluster gère déjà l'ingress
export TF_VAR_install_mysql_local=false            # si on cible une DB managée
make bootstrap
```

Dans ce cas, le `Secret` `ppm-backend-secrets-local` n'est plus
auto-rempli — il faut fournir `db_password` via un `terraform.tfvars`
(gitignored) ou, mieux, déployer External Secrets Operator et
laisser ESO matérialiser le Secret depuis le gestionnaire cloud.
Voir les questions ouvertes §7.

## 6. Contrat avec les pipelines CI existants

Le job `promote-test` (backend & frontend) exécute :

```bash
sed -i "s|^  tag:.*|  tag: \"${TAG}\"|" gitops/charts/ppm-{backend|frontend}/values-test.yaml
```

⚠️ **Ne JAMAIS** modifier dans `ppm-gitops` :

- l'arborescence `charts/ppm-backend/values-test.yaml` et
  `charts/ppm-frontend/values-test.yaml` ;
- la ligne `  tag: "..."` (deux espaces d'indentation, unique par
  fichier) — c'est sur elle que `sed` tape.

Les fichiers ajoutés par cette couche (`values-local.yaml`,
`apps/environments/local/*`, `namespaces/ppm-local.yaml`) sont **hors
du chemin de promotion CI** : la pipeline `promote-test` ne les touche
pas, donc rien ne casse.

## 7. Décisions qui attendent l'encadrant

Ces points ne sont pas tranchés et sont **délibérément laissés en
configuration neutre** pour ne pas figer le projet :

1. **Cloud provider cible** (AWS / Azure / GCP / on-prem ?)
   → conditionne : registry (ECR / ACR / GCR), DB managée
   (RDS / Cloud SQL / Azure DB), Object Storage pour les uploads
   (`/app/projects`), IAM (IRSA / Workload Identity).
2. **Stratégie de secrets managés** : `External Secrets Operator`
   (ESO) + cloud secret manager, *ou* `sealed-secrets`, *ou*
   `Vault` ? Aujourd'hui : `Secret` Kubernetes brut généré par Terraform.
3. **Ingress de production** : `ingress-nginx`, `Traefik`, ou ingress
   natif du cloud (ALB / Application Gateway / GKE Ingress) ?
4. **TLS / DNS** : `cert-manager` + Let's Encrypt sur un domaine
   réel — quel domaine ? quel registrar ?
5. **Image registry de production** : conserver GHCR ou pousser
   aussi vers le registry du cloud cible ?
6. **Bug applicatif identifié** : `BACKEND_URL` est mis à port **8080**
   dans `values-test.yaml` / `values-staging.yaml` / `values-prod.yaml`
   du frontend, alors que le backend écoute sur **8082**. Corrigé
   uniquement dans `values-local.yaml`. Faut-il propager le correctif
   maintenant, ou attendre une fenêtre de release ?
7. **Migration des uploads** vers object storage (S3 / Blob / GCS) :
   prérequis pour activer HPA backend (le PVC RWO bloque à 1 réplique).
8. **Observabilité** : prom-stack + Loki/ELK gérés par cette couche
   ou par une équipe plate-forme distincte ?

## 8. Layout du repo

```
ppm-infra/
├── README.md                # ← vous êtes ici (= guide de soutenance)
├── Makefile                 # raccourcis make minikube-up / bootstrap / port-forward
├── .gitignore               # exclut tfstate, tfvars, kubeconfig, .env
├── .editorconfig
├── docs/
│   └── architecture.md      # détails extension cloud + diagramme étendu
├── scripts/
│   ├── minikube-up.sh
│   ├── minikube-down.sh
│   ├── bootstrap.sh
│   ├── argocd-password.sh
│   └── port-forward.sh
└── terraform/
    ├── envs/
    │   └── local/                   # composition Minikube
    │       ├── main.tf
    │       ├── providers.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── versions.tf
    │       └── terraform.tfvars.example
    └── modules/
        ├── namespaces/
        ├── argocd/                  # Helm release argo-cd
        ├── ingress-nginx/           # Helm release ingress-nginx (NodePort)
        ├── mysql-local/             # Helm release bitnami/mysql (dev only)
        ├── ppm-secrets/             # kubernetes_secret (DB_PASSWORD + JWT_SECRET)
        └── app-of-apps/             # kubectl_manifest = Application racine
```

## 9. Idempotence & destruction

`terraform apply` est idempotent : ré-exécuté il ne change rien si
rien n'a bougé. La destruction est non-destructive pour les données
applicatives par défaut : le PVC `ppm-backend-uploads` est annoté
`helm.sh/resource-policy: keep`. Pour repartir de zéro :

```bash
make destroy
kubectl delete pvc --all -n ppm-local   # si on veut vraiment perdre les uploads
make minikube-delete
```

## 10. Notes de soutenance — points à défendre

- **Séparation des responsabilités** : Terraform gère la plate-forme
  (CRDs, ingress, secrets, DB), Argo CD gère les workloads
  applicatifs. Aucun chevauchement.
- **Portabilité réelle** : zéro provider cloud Terraform ⇒ le même
  code marche sur Minikube le matin, sur EKS l'après-midi.
- **Supply-chain de bout en bout** : la CI signe, atteste, scanne ;
  GitOps trace tout déploiement à un commit ; IaC trace toute
  ressource d'infra à un `terraform apply` reproductible.
- **Pipelines intactes** : la couche IaC respecte le contrat
  `promote-test` sans rien casser.
- **Démontrable en 5 commandes** : `minikube-up` → `bootstrap` →
  `argocd-password` → `port-forward` → ouvrir le navigateur.
