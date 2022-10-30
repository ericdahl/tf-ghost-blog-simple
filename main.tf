provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name = "tf-ghost-blog-simple"
    }
  }
}

