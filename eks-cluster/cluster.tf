#EKS 

resource "aws_eks_cluster" "exam-eks" {
  name     = "Eks-cluster"
  role_arn = aws_iam_role.exam-eksrole.arn


  vpc_config {
    subnet_ids         = ["subnet-09dd0886d97cbfbeb", "subnet-0263efb726a0baa2e"]
    security_group_ids = ["sg-02a319aec05ef80f7"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.exam-eksrole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.exam-eksrole-AmazonEKSVPCResourceController,
  ]
}


output "endpoint" {
  value = aws_eks_cluster.exam-eks.endpoint
}

# IAM ROLE

resource "aws_iam_role" "exam-eksrole" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "exam-eksrole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.exam-eksrole.name
}

resource "aws_iam_role_policy_attachment" "exam-eksrole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.exam-eksrole.name
}


data "tls_certificate" "ekstls" {
  url = aws_eks_cluster.exam-eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eksopidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.exam-eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eksdoc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}