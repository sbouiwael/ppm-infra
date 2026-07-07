# ==============================================================
# Observability stack (platform layer) — metrics, logs, dashboards, alerts.
#   - kube-prometheus-stack : Prometheus + Grafana + Alertmanager
#                             + node-exporter + kube-state-metrics
#   - loki-stack            : Loki (logs store) + Promtail (log shipper)
# Grafana is wired to BOTH datasources (Prometheus + Loki).
# Tuned to stay light on a single Minikube node.
# ==============================================================

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "ppm-observability"
    }
  }
}

locals {
  # Only set storageClassName when explicitly provided; otherwise use cluster default.
  prometheus_pvc_spec = merge(
    {
      accessModes = ["ReadWriteOnce"]
      resources   = { requests = { storage = var.prometheus_storage_size } }
    },
    var.storage_class != "" ? { storageClassName = var.storage_class } : {},
  )
}

# ── Metrics + Grafana + Alerting ─────────────────────────────────────────────
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version

  create_namespace = false
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      # ---- Grafana ----
      grafana = {
        adminPassword = var.grafana_admin_password
        # Wire Loki so logs are queryable alongside metrics in one UI.
        additionalDataSources = [
          {
            name      = "Loki"
            type      = "loki"
            access    = "proxy"
            url       = "http://loki.${var.namespace}.svc.cluster.local:3100"
            isDefault = false
          },
        ]
        persistence = { enabled = false } # ephemeral dashboards state is fine for local
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { memory = "256Mi" }
        }
      }

      # ---- Prometheus ----
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention

          # CRUCIAL: by default the operator only discovers ServiceMonitors that
          # carry this chart's release label. Setting these to false makes
          # Prometheus pick up ANY ServiceMonitor/PodMonitor/Rule in the cluster
          # — including the ppm-backend one we add in phase 2.
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
          probeSelectorNilUsesHelmValues          = false

          resources = {
            requests = { cpu = "100m", memory = "400Mi" }
            limits   = { memory = "1Gi" }
          }

          storageSpec = {
            volumeClaimTemplate = {
              spec = local.prometheus_pvc_spec
            }
          }
        }
      }

      # ---- Alertmanager (kept, but minimal) ----
      alertmanager = {
        alertmanagerSpec = {
          resources = {
            requests = { cpu = "20m", memory = "64Mi" }
            limits   = { memory = "128Mi" }
          }
        }
      }

      # ---- Alertes applicatives PPM ----
      # Le chart génère une PrometheusRule à partir de cette map (avec le label
      # `release` attendu par Prometheus). C'est la source de vérité IaC : elle
      # remplace le `kubectl apply` manuel de manifests/ppm-backend-alerts.yaml,
      # et évite le problème de timing CRD d'une ressource kubernetes_manifest
      # (la CRD PrometheusRule est fournie par ce même chart).
      additionalPrometheusRulesMap = {
        ppm-backend-alerts = {
          groups = [
            {
              name = "ppm-backend.rules"
              rules = [
                # Disponibilité : l'API backend ne répond plus / n'est plus scrapée.
                {
                  alert = "PpmBackendDown"
                  expr  = "absent(up{job=\"ppm-backend-local\"} == 1)"
                  "for" = "1m"
                  labels = {
                    severity    = "critical"
                    application = "ppm-backend"
                  }
                  annotations = {
                    summary     = "Backend PPM injoignable"
                    description = "Aucune cible up=1 pour le job ppm-backend-local depuis 1 minute : l'API backend est down ou n'est plus scrapée par Prometheus."
                  }
                },
                # Qualité de service : taux d'erreurs 4xx anormalement élevé.
                {
                  alert = "PpmHighHttp4xxRate"
                  expr  = "sum(rate(http_server_requests_seconds_count{application=\"ppm-backend\",status=~\"4..\"}[5m])) > 0.2"
                  "for" = "2m"
                  labels = {
                    severity    = "warning"
                    application = "ppm-backend"
                  }
                  annotations = {
                    summary     = "Taux d'erreurs HTTP 4xx élevé sur le backend PPM"
                    description = "Plus de 0.2 requête/s en erreur 4xx (côté client) sur les 5 dernières minutes — possible problème d'authentification ou de routes invalides."
                  }
                },
                # Saturation : mémoire heap JVM > 80%.
                {
                  alert = "PpmJvmHeapHigh"
                  expr  = "sum(jvm_memory_used_bytes{application=\"ppm-backend\",area=\"heap\"}) / sum(jvm_memory_max_bytes{application=\"ppm-backend\",area=\"heap\"}) > 0.8"
                  "for" = "5m"
                  labels = {
                    severity    = "warning"
                    application = "ppm-backend"
                  }
                  annotations = {
                    summary     = "Mémoire heap JVM > 80% sur le backend PPM"
                    description = "Le heap de la JVM backend dépasse 80% de sa capacité maximale depuis 5 minutes — risque de GC intensif voire d'OutOfMemoryError."
                  }
                },
              ]
            },
          ]
        }
      }

      # ---- Control-plane scrape jobs disabled on Minikube ----
      # These endpoints aren't reachable on a single-node Minikube and would only
      # produce permanently-"down" targets and noisy alerts. kubelet + cAdvisor
      # (per-pod CPU/mem) and node-exporter still give the real value.
      kubeControllerManager = { enabled = false }
      kubeScheduler         = { enabled = false }
      kubeEtcd              = { enabled = false }
      kubeProxy             = { enabled = false }
    }),
  ]

  depends_on = [kubernetes_namespace_v1.monitoring]
}

# ── Logs ─────────────────────────────────────────────────────────────────────
resource "helm_release" "loki_stack" {
  name       = "loki"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.loki_stack_version

  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      loki = {
        enabled     = true
        isDefault   = false
        persistence = { enabled = false }
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { memory = "256Mi" }
        }
      }
      promtail = {
        enabled = true
        resources = {
          requests = { cpu = "20m", memory = "64Mi" }
          limits   = { memory = "128Mi" }
        }
      }
      # Grafana & Prometheus come from kube-prometheus-stack — disable the bundled ones.
      grafana    = { enabled = false }
      prometheus = { enabled = false }
    }),
  ]

  depends_on = [kubernetes_namespace_v1.monitoring]
}

output "namespace" {
  value = var.namespace
}

output "grafana_release" {
  value = helm_release.kube_prometheus_stack.name
}