service_name               = "my-service"
environment                = "dev"
region                     = "us-west-1"
vpc_tag_filters            = { Name = "my-vpc" }
public_subnet_tag_filters  = { Tier = "public" }
private_subnet_tag_filters = { Tier = "private" }
container_port             = 3000
desired_count              = 1
cpu                        = "256"
memory                     = "512"
image_tag                  = "latest"
health_check_path          = "/"
assign_public_ip           = true
tags = {
  service            = "my-service"
  environment        = "dev"
  managed-by         = "terraform"
  direct_task_access = "true"
}
