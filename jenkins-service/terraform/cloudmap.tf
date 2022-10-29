resource "aws_service_discovery_private_dns_namespace" "jenkins" {
  name = local.service_discovery_namespace_name
  vpc  = aws_vpc.jenkins.id
}

resource "aws_service_discovery_service" "jenkins" {
  name = local.service_discovery_service_name

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.jenkins.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }
}
