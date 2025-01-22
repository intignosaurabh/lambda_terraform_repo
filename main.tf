terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">=1.5.0"
}

provider "aws" {
  region = "ap-southeast-2"
}

#s3 bucket
resource "aws_s3_bucket" "intigno_terraform_bucket" {
  bucket = "intigno_terraform_bucket"
}

#IAM Role for Lambda
resource "aws_iam_role" "intigno_terraform_lambda_role" {
  name = "intigno_lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

#IAM Policy
resource "aws_iam_role_policy_attachment" "intigno_lambda_policy" {
  role       = aws_iam_role.intigno_terraform_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "null_resource" "build_lambda_package" {
  provisioner "local-exec" {
    command = <<EOT
        mkdir -p ${path.module}/package
        pip install requests -t ${path.module}/package/
        cp ${path.module}/lambda_function.py ${path.module}/package/
        cd ${path.module}/package
        zip -r ../package.zip .
        cd ${path.module}
        rm -rf ${path.module}/package
    EOT
  }
}
#Lambda Function
resource "aws_lambda_function" "intigno_example_lambda" {
  function_name = "intigno_terraform_lambda"
  runtime       = "python3.9"
  role          = aws_iam_role.intigno_terraform_lambda_role
  handler       = "lambda_function.lambda_handler"
  filename      = "${path.module}/package.zip"

  depends_on = [null_resource.build_lambda_package]

  source_code_hash = filebase64sha256("${path.module}/package.zip")
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.intigno_terraform_bucket.bucket
    }
  }
}
