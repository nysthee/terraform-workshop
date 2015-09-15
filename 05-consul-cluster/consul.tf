// This is the Consul Terraform module. This module is actually bundled within
// Consul at https://github.com/hashicorp/consul in the Terraform folder.
module "consul" {
  // This is the source of the Consul module.
  source = "../consul"

  // This is the specific AMI id to use for the Consul servers.
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  // This tells the Consul module to create 3 servers.
  servers = 3

  // This tells the Consul module to launch inside our VPC
  subnet_id      = "${aws_subnet.terraform-tutorial.id}"
  security_group = "${aws_security_group.terraform-tutorial.id}"

  // These two arguments use outputs from another module. The ssh_keys module
  // we have been using outputs the key name and key path. The Consul module
  // takes those values as arguments.
  key_name         = "${module.ssh_keys.key_name}"
  private_key_path = "${module.ssh_keys.private_key_path}"
}

// This will output the address of the first Consul instance where we can access
// the Web UI on port 8500.
output "consul-address" { value = "${module.consul.address}" }

// Before we can try to plan, we need to tell Terraform to download this new
// module:
//
//     $ terraform get 05-consul-cluster
//
// If you run `terraform plan 05-consul-cluster`, the plan output will feel
// somewhat empty. This is because, by default, Terraform collapses all module
// data into a single "resource". You can tell Terraform to expand the module
// output by specifying -module-depth=1.
//
//     $ terraform plan -module-depth=1 05-consul-cluster
//
// Now you will see there are three instances and a security group being created
// by this module.
