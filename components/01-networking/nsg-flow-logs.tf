module "nsg-flow-logs" {
  source                    = "../../../modules/nsg-flow-logs"
  storage_account_name      = data.terraform_remote_state.global.outputs.flows_storage_account_name
  network_security_group_id = module.clusternetworking-regional.k8s_network_security_group_id
}
