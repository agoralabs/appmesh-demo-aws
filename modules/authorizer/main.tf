locals {
  api_id = "${data.external.thumbprint.result.thumbprint}"
  authorizer_id = aws_apigatewayv2_authorizer.api_gw.id
  env_vars = jsondecode(file(var.env_vars_file))

}

#LAMBDA AUTHORIZER

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
    command = "rm -rf ${var.authorizer_source_dir} && rm -rf ${var.authorizer_source_dir}.zip && mkdir -p ${var.authorizer_source_dir}"
  }
}

data "archive_file" "lambda_archive" {
  type = "zip"

  source_dir  = "${var.authorizer_source_dir}"
  output_path = "${var.authorizer_source_dir}.zip"

  depends_on = [ null_resource.create_file ]
}

resource "null_resource" "create_file" {
  # Cette dépendance assure que cette ressource s'exécute après la création du répertoire
  depends_on = [null_resource.create_directory]

  triggers = {
    always_run = "${timestamp()}"
    authorizer_source_dir = "${var.authorizer_source_dir}"
    authorizer_code_dependencies = "${var.authorizer_code_dependencies}"
  }

  # Cette provisioner exécute des commandes locales
  provisioner "local-exec" {
    when = create
    command = "rm -rf ${var.authorizer_source_dir} && rm -rf ${var.authorizer_source_dir}.zip && mkdir -p ${var.authorizer_source_dir} && cp ${var.authorizer_source_code} ${var.authorizer_source_dir}/${var.authorizer_name}.js && cp ${var.authorizer_code_dependencies} ${var.authorizer_source_dir}/package.json && cd ${var.authorizer_source_dir} && npm install"
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -rf ${self.triggers.authorizer_source_dir} && rm -rf ${self.triggers.authorizer_source_dir}.zip"
  }

}

resource "aws_lambda_function" "authorizer" {
  function_name = "${var.authorizer_name}"

  runtime = "${var.authorizer_runtime}"
  handler = "${var.authorizer_name}.handler"
  timeout = var.authorizer_timeout

  role = aws_iam_role.iam_for_lambda.arn

  # Utilisation du fichier ZIP créé à partir du code
  filename      = "${data.archive_file.lambda_archive.output_path}"

  environment {
    variables = local.env_vars
  }

  depends_on = [ null_resource.create_file ]

}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.authorizer_name}-lambda_policy"
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
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
            "codedeploy:CreateDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetApplicationRevision"
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


resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.authorizer_name}_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "external" "thumbprint" {
  program = ["${path.module}/files/thumbprint.sh", "${var.api_gateway_name}", "${var.region}"]
}

data "aws_apigatewayv2_api" "api_gw" {
  api_id = "${local.api_id}"
}


#Integrate with API GATEWAY

resource "aws_apigatewayv2_authorizer" "api_gw" {
  api_id   = "${local.api_id}"
  authorizer_type = "REQUEST"
  authorizer_uri  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer.arn}/invocations"
  #identity_sources = ["$request.header.Authorization","$request.header.Host"]
  #identity_sources = ["$request.header.Host"]
  name            = "${var.authorizer_name}"
  authorizer_payload_format_version = "2.0"

  depends_on = [
    aws_lambda_permission.allow_apigateway
  ]
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_apigatewayv2_api.api_gw.execution_arn}/*/*"
}

#ATTACH/DETACH Authorizer to API Gateway
resource "null_resource" "attach_authorizer" {
  # Cette dépendance assure que cette ressource s'exécute après la création de l'authorizer
  depends_on = [aws_apigatewayv2_authorizer.api_gw]

  triggers = {
    always_run = "${timestamp()}"
    API_NAME = "${var.api_gateway_name}"
    REGION = "${var.region}"
    AUTHORIZER_ID = "${local.authorizer_id}"
  }

  # Cette provisioner exécute des commandes locales
  provisioner "local-exec" {
    when = create
    command = "chmod +x ${path.module}/files/manage_api_gw_route.sh && COMMAND=ATTACH API_NAME=${self.triggers.API_NAME} REGION=${self.triggers.REGION} AUTHORIZER_ID=${self.triggers.AUTHORIZER_ID} ${path.module}/files/manage_api_gw_route.sh"
  }

  provisioner "local-exec" {
    when = destroy
    command = "chmod +x ${path.module}/files/manage_api_gw_route.sh && COMMAND=DETACH API_NAME=${self.triggers.API_NAME} REGION=${self.triggers.REGION} AUTHORIZER_ID=${self.triggers.AUTHORIZER_ID} ${path.module}/files/manage_api_gw_route.sh"
  }

}

