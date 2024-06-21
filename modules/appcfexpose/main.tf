locals {
  cf_domain_name = data.aws_cloudfront_distribution.cf.domain_name
  alias_to_add = "${var.dns_record_name}.${var.dns_domain}"
}

data "aws_route53_zone" "dns_zone" {
  name = "${var.dns_domain}"
}

data "aws_cloudfront_distribution" "cf" {
  id = "${var.cf_distribution_id}"
}

/*
resource "aws_route53_record" "dnscf" {
  name = "${var.dns_record_name}"
  type = "A"
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  alias {
    evaluate_target_health = false
    name = data.aws_cloudfront_distribution.cf.domain_name
    zone_id = data.aws_cloudfront_distribution.cf.hosted_zone_id
  }
}
*/

resource "aws_route53_record" "dnscf" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${var.dns_record_name}"
  type    = "CNAME"
  records = [local.cf_domain_name]
  ttl     = 300
}


resource "null_resource" "alias" {
  
  triggers = {
    always_run = "${timestamp()}"
    DISTRIBUTION_ID = "${var.cf_distribution_id}"
    ALIAS = "${local.alias_to_add}"
    AWS_REGION = "${var.region}"
  }

  provisioner "local-exec" {
    when = create
    command = "chmod +x ${path.module}/files/alias.sh && DISTRIBUTION_ID=${var.cf_distribution_id} ALIAS=${local.alias_to_add} ACTION=ADD AWS_REGION=${var.region} ${path.module}/files/alias.sh"
  }


  provisioner "local-exec" {
    when = destroy
    command = "chmod +x ${path.module}/files/alias.sh && DISTRIBUTION_ID=${self.triggers.DISTRIBUTION_ID} ALIAS=${self.triggers.ALIAS} ACTION=REMOVE AWS_REGION=${self.triggers.AWS_REGION} ${path.module}/files/alias.sh"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ aws_route53_record.dnscf ]
}
