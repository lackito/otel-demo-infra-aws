output "namespace" {
  value = helm_release.this.namespace
}

output "release_name" {
  value = helm_release.this.name
}

output "release_version" {
  value = helm_release.this.version
}

output "status" {
  value = helm_release.this.status
}
