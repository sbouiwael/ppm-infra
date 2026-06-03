resource "kubernetes_namespace_v1" "this" {
  for_each = var.namespaces

  metadata {
    name   = each.key
    labels = each.value
  }
}

output "names" {
  value = [for n in kubernetes_namespace_v1.this : n.metadata[0].name]
}
