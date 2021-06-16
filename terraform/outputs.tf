output "app_url" {
  value = "http://${data.terraform_remote_state.infra.outputs.address}"
}
