variable "region" {
  type    = string
  default = "us-west-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "task_family" {
  type    = string
  default = "weby"
}

variable "container_name" {
  type    = string
  default = "weby"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "service_name" {
  type    = string
  default = "weby-service"
}

variable "service_cpu" {
  type    = number
  default = 256
}

variable "service_memory" {
  type    = number
  default = 512
}

variable "app_port" {
  type    = number
  default = 3000
}

variable "host_port" {
  type    = number
  default = 3000
}

variable "service_count" {
  type    = number
  default = 5
}

variable "autoscale_min" {
  description = "Minimum autoscale (number of EC2)"
  default     = "1"
}

variable "autoscale_max" {
  description = "Maximum autoscale (number of EC2)"
  default     = "10"
}

variable "autoscale_desired" {
  description = "Desired number of service instances"
  type        = number
  default     = 1
}
