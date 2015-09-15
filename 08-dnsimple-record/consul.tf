// This is the same Consul module as from 05-consul-cluster.
module "consul" {
  source = "../consul"

  ami     = "${lookup(var.aws_amis, var.aws_region)}"
  servers = 3

  subnet_id      = "${aws_subnet.terraform-tutorial.id}"
  security_group = "${aws_security_group.terraform-tutorial.id}"

  key_name         = "${module.ssh_keys.key_name}"
  private_key_path = "${module.ssh_keys.private_key_path}"
}
