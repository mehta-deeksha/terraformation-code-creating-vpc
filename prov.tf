provider "aws" {
  profile = var.profile
  region  = var.region-jenkins-master
  alias   = "master-region"
}

provider "aws" {
  profile = var.profile
  region  = var.region-jenkins-worker
  alias   = "worker-region"
}