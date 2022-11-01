data "aws_route53_zone" "main" {
  name = "${var.main_domain_name}."
}

resource "aws_route53_zone" "jenkins" {
  name = var.domain_name
}

resource "aws_route53_record" "jenkins-ns" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.jenkins.name_servers
}

resource "aws_route53_record" "jenkins-www" {
  zone_id = aws_route53_zone.jenkins.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.jenkins.dns_name
    zone_id                = aws_lb.jenkins.zone_id
    evaluate_target_health = true
  }
}
