variable "project" {
  description = "This is project-id"
  type        = string
  default     = "sturdy-method-477514-i6"

}

variable "region" {
  description = "This is gcp region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "This is gcp zone"
  type        = string
  default     = "us-central1-a"

}

variable "K8s_version" {
  description = "This is gke version"
  type        = string
  default     = "1.33.5-gke.1201000"
}
variable "node_count" {
  description = "This is gke node count"
  type        = number
  default     = 1
}
