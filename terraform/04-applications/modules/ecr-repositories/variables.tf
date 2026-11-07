variable "repositories" {
  description = "Map of ECR repositories"

  type = map(object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "force_delete" {
  description = "Delete repositories including all images on destroy; enable only for disposable environments."
  type        = bool
  default     = false
}
