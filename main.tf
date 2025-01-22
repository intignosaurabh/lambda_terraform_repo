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

resource "random_string" "suffix" {
  length  = 8
  special = false
}
#s3 bucket
resource "aws_s3_bucket" "intigno_terraform_bucket" {
  bucket = "intigno-terraform-bucket"
}

#IAM Role for Lambda
resource "aws_iam_role" "intigno_terraform_lambda_role" {
  name = "intigno_lambda_execution_role_new"
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
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

#Lambda Function
resource "aws_lambda_function" "intigno_example_lambda" {
  function_name = "intigno_terraform_lambda"
  runtime       = "python3.9"
  role          = aws_iam_role.intigno_terraform_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  filename      = "${path.module}/package.zip"

  source_code_hash = filebase64sha256("${path.module}/package.zip")
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.intigno_terraform_bucket.bucket
    }
  }
}
