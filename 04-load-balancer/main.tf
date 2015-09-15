// This is the same module block from 01-ssh-keypair. Terraform will know the
// old resource exists because of the state file it created. We will discuss
// that more later.
module "ssh_keys" {
  source = "../ssh_keys"
  name   = "terraform-tutorial"
}

// This is the same resource block from 02-single-instance.
resource "aws_instance" "web" {
  // This tells Terraform to create 3 of the same instance. Instead of copying
  // and pasting this resource block multiple times, we can easily scale forward
  // and backward with the count parameter. Usually this is left as a variable,
  // but we will hardcode here for simplicity.
  count = 3

  ami = "${lookup(var.aws_amis, var.aws_region)}"

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
    // This is a slightly modified provisioner from before. In addition to
    // installing apache, this provisioner script adds a static HTML file that
    // includes information about the instance.
    inline = [
      "sudo apt-get update",
      "sudo apt-get --yes install apache2",
      "echo \"<h1>${self.public_dns}</h1>\" | sudo tee /var/www/html/index.html",
      "echo \"<h2>${self.public_ip}</h2>\"  | sudo tee -a /var/www/html/index.html",
    ]
  }
}

// Create a new load balancer
resource "aws_elb" "web" {
  // This is the name of the ELB.
  name = "web"

  // This puts the ELB in the same subnet (and thus VPC) as the instances. This
  // is required so the ELB can forward traffic to the instances.
  subnets = ["${aws_subnet.terraform-tutorial.id}"]

  // This specifies the security groups the ELB is a part of.
  security_groups = ["${aws_security_group.terraform-tutorial.id}"]

  // This tells the ELB which port(s) to listen on. This block can be specified
  // multiple times to specify multiple ports. We are just using a simple web
  // server, so port 80 is fine.
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  // This sets a health check for the ELB. If instances in the ELB are reported
  // as "unhealthy", they will stop receiving traffic. This is a simple HTTP
  // check to each instance on port 80.
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  // This sets the list of EC2 instances that will be part of this load
  // balancer. Take careful note of the "*" parameter. This tells Terraform to
  // use all of the instances created via the increased count above.
  instances = ["${aws_instance.web.*.id}"]

  // This names the ELB.
  tags { Name = "terraform-tutorial" }
}

// This tells terrafrom to export (or output) the AWS load balancer's public
// DNS. It also outputs each instance's IP address for reference.
output "elb-address" { value = "${aws_elb.web.dns_name}" }
output "instance-ips" { value = "${join(", ", aws_instance.web.*.public_ip)}"}

// Run `terraform apply 04-load-balancer` and Terraform will create two new
// instances, a load balancer, and all the pieces to wire them together.

// Once the apply has finished, AWS will health check the instances and then add
// them to the load balancer if they pass. This process can take a few minutes
// the first time. For this reason, you can visit each of the IP addresses of
// the instances first. Once the load balancer is healthy with all three
// instances, go to the address in your browser. Keep refreshing the page and
// you should see different IP addresses cycle for the three instances.
