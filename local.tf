locals {
  gateways = yamldecode(data.local_file.configuration.content).gateways
}