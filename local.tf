locals {
  gateways = yamldecode(data.local_file.configuration.content).gateways

  ssl_certs = flatten([
    for gateways, gateway in local.gateways : [
      for cert in gateway.ssl_certificates : {
        name = "${cert.certificate_name}"
      }
    ]
  ])
}