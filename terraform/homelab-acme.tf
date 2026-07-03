
# Homelab DNS + ACME credentials
#
# The Synology NAS runs Traefik behind the LAN; these records let LAN clients
# resolve *.home.<zone> and let Traefik validate a wildcard Let's Encrypt
# certificate via the ACME DNS-01 challenge. The private RFC1918 target in
# public DNS is intentional — nothing is exposed to the internet.

resource "aws_route53_record" "homelab_wildcard" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.${var.homelab_domain}"
  type    = "A"
  ttl     = 300
  records = [var.homelab_nas_ip]
}

resource "aws_route53_record" "homelab_apex" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.homelab_domain
  type    = "A"
  ttl     = 300
  records = [var.homelab_nas_ip]
}

# Dedicated IAM user for the ACME client (lego inside Traefik). The key lives
# on the NAS, so the policy is scoped down to forging ACME challenges only:
# it can touch nothing but the TXT record at _acme-challenge.<homelab_domain>.
resource "aws_iam_user" "homelab_acme" {
  name = "homelab-acme"
}

resource "aws_iam_access_key" "homelab_acme" {
  user = aws_iam_user.homelab_acme.name
}

data "aws_iam_policy_document" "homelab_acme" {
  statement {
    sid       = "GetChange"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  # No route53:ListHostedZones* — lego skips zone discovery because
  # AWS_HOSTED_ZONE_ID is set on the NAS.
  statement {
    sid       = "ListRecordSets"
    actions   = ["route53:ListResourceRecordSets"]
    resources = [data.aws_route53_zone.main.arn]
  }

  statement {
    sid       = "ChangeAcmeChallengeOnly"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [data.aws_route53_zone.main.arn]

    # DNS-01 for both <homelab_domain> and *.<homelab_domain> writes its TXT
    # record at exactly _acme-challenge.<homelab_domain>. ForAllValues: every
    # change in the batch must match, so no other record can ride along.
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsNormalizedRecordNames"
      values   = ["_acme-challenge.${var.homelab_domain}"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }
}

resource "aws_iam_user_policy" "homelab_acme" {
  name   = "homelab-acme-dns01"
  user   = aws_iam_user.homelab_acme.name
  policy = data.aws_iam_policy_document.homelab_acme.json
}
