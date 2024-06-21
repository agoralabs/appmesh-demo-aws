
provider "aws" {
  region = "us-east-1"  # Lambda@Edge doit être déployé dans us-east-1
  alias  = "us_east_1"
}

#LAMBDA EDGE

# Cette ressource peut être utilisée pour déclencher la création et le zip du fichier
resource "null_resource" "trigger_create_and_zip" {
  triggers = {
    # Changez ce déclencheur pour forcer la recréation du fichier et du zip
    always_run = "${timestamp()}"
  }

  depends_on = [null_resource.create_file]
}


resource "null_resource" "create_directory" {
  # Cette provisioner crée un répertoire
  provisioner "local-exec" {
    when = create
    command = "rm -rf ${var.lambda_edge_source_dir} && rm -rf ${var.lambda_edge_source_dir}.zip && mkdir -p ${var.lambda_edge_source_dir}"
  }
}

data "archive_file" "lambda_archive" {
  type = "zip"

  source_dir  = "${var.lambda_edge_source_dir}"
  output_path = "${var.lambda_edge_source_dir}.zip"

  depends_on = [ null_resource.create_file ]
}

resource "null_resource" "create_file" {
  # Cette dépendance assure que cette ressource s'exécute après la création du répertoire
  depends_on = [null_resource.create_directory]

  triggers = {
    always_run = "${timestamp()}"
    lambda_edge_source_dir = "${var.lambda_edge_source_dir}"
    lambda_edge_code_dependencies = "${var.lambda_edge_code_dependencies}"
  }

  # Cette provisioner exécute des commandes locales
  provisioner "local-exec" {
    when = create
    command = "rm -rf ${var.lambda_edge_source_dir} && rm -rf ${var.lambda_edge_source_dir}.zip && mkdir -p ${var.lambda_edge_source_dir} && cp ${var.lambda_edge_source_code} ${var.lambda_edge_source_dir}/${var.lambda_edge_name}.js && cp ${var.lambda_edge_code_dependencies} ${var.lambda_edge_source_dir}/package.json && cd ${var.lambda_edge_source_dir} && npm install"
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -rf ${self.triggers.lambda_edge_source_dir} && rm -rf ${self.triggers.lambda_edge_source_dir}.zip"
  }

}

resource "aws_lambda_function" "lambda_edge" {
  function_name = "${var.lambda_edge_name}"

  runtime = "${var.lambda_edge_runtime}"
  handler = "${var.lambda_edge_name}.handler"
  timeout = var.lambda_edge_timeout

  role = aws_iam_role.iam_for_lambda.arn

  # Utilisation du fichier ZIP créé à partir du code
  filename      = "${data.archive_file.lambda_archive.output_path}"

  # environment {
  #   variables = local.env_vars
  # }

  publish = true
  provider = aws.us_east_1
  depends_on = [ null_resource.create_file ]

}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_edge_name}-lambda_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
            "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
            "ssm:*"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
            "iam:*"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
            "route53:*"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
            "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.lambda_edge_name}_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

locals {
  parameters = jsondecode(file("${var.env_vars_file}"))
}

# Créer les paramètres dans le Parameter Store
resource "aws_ssm_parameter" "env_vars" {
  for_each = local.parameters

  name  = each.key
  type  = "String"
  value = each.value
  provider = aws.us_east_1
}
