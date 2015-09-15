// This is the same module block from 01-ssh-keypair.
module "ssh_keys" {
  source = "../ssh_keys"
  name   = "terraform-tutorial"
}

// This is the same resource block from 02-single-instance.
resource "aws_instance" "web" {
  count = 3
  ami   = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${module.ssh_keys.key_name}"
  subnet_id     = "${aws_subnet.terraform-tutorial.id}"

  vpc_security_group_ids = ["${aws_security_group.terraform-tutorial.id}"]

  tags { Name = "web-${count.index}" }

  connection {
    user     = "ubuntu"
    key_file = "${module.ssh_keys.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get --yes install apache2",
      "echo \"<h1>${self.public_dns}</h1>\" | sudo tee /var/www/html/index.html",
      "echo \"<h2>${self.public_ip}</h2>\"  | sudo tee -a /var/www/html/index.html",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul.conf"
    destination = "/tmp/consul.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/web.json"
    destination = "/tmp/web.json"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${module.consul.address} > /tmp/consul-address",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul.sh"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/index.html.ctmpl"
    destination = "/tmp/index.html.ctmpl"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul-template-apache.conf"
    destination = "/tmp/consul-template.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul-template.sh"
    ]
  }
}

// This is replacing the ELB from 04-load-balancer. Instead of using Amazon's
// load balancer, we will use our own. Most of these attributes should already
// be familiar to you, so we will skip down to the provisioner.
resource "aws_instance" "haproxy" {
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${module.ssh_keys.key_name}"
  subnet_id     = "${aws_subnet.terraform-tutorial.id}"

  vpc_security_group_ids = ["${aws_security_group.terraform-tutorial.id}"]

  tags { Name = "haproxy" }

  connection {
    user     = "ubuntu"
    key_file = "${module.ssh_keys.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul.conf"
    destination = "/tmp/consul.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${module.consul.address} > /tmp/consul-address",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get --yes install haproxy",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy.cfg.ctmpl"
    destination = "/tmp/haproxy.cfg.ctmpl"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul-template-haproxy.conf"
    destination = "/tmp/consul-template.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul-template.sh"
    ]
  }
}

// This is the address of the ELB.
output "haproxy-address" { value = "${aws_instance.haproxy.public_dns}" }
