variable "name" {
  type        = string
  description = "Name of the Service Account"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Name in which the service account to be created"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to be added to the service account"
}

variable "annotations" {
  type        = map(string)
  default     = {}
  description = "Annotations that need to be added to SA"
}
