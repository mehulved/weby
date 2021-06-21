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

variable "autoscale_min" {
  description = "Minimum autoscale"
  default     = 1
}

variable "autoscale_max" {
  description = "Maximum autoscale"
  default     = 5
}

variable "autoscale_desired" {
  description = "Desired number of service instances"
  type        = number
  default     = 1
}

variable "weby_hostname" {
  description = "Hostname for the service to listen"
  type        = string
  default     = "lvh.me"
}
