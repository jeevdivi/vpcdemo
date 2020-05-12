resource "ibm_is_ssh_key" "my-ssh-key" {
  name       = "my-ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcx9zaXwmhw5+ry2wuWKQEy8rciZ8hika0QiEXoQy3qulMhajs+e/q0Byz9Ahiv65tYoGbDPzQQwiSceVam4CZnLxXXtpyeJ97sRrbdYOxBXtMt69dlZg3cKHVbKN0iydRLMo7HQpvWx9p5AoTNt0u+lMg/joy9tpc8h791QJ3MbqYbx7JqtcOtwnRhdNe/Hi/BCobL/+lYCriMnTjD5ZPPHyWur7aAnl8YlQmYJLFBbXKbcMzbfJ2WuZ3dXQP/xOse5wJ94UZ9S1GcXj1BgH892EGnAyRhAHsKO2yeLmbOiIWu5MRJ1RPWrjB43OKnbRsIUjhFIS2QX4rjTlyzFEn jeevan@Jeevans-MBP.lan"
}

resource "ibm_is_vpc" "vpc1" {
  name = "${var.vpc_name}"
  address_prefix_management = "auto"
  classic_access = "true"
}

resource "ibm_is_vpc_address_prefix" "vpc-ap1" {
  name = "vpc-ap1"
  zone = "${var.zone1}"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  cidr = "${var.zone1_cidr}"
}

resource "ibm_is_vpc_address_prefix" "vpc-ap2" {
  name = "vpc-ap2"
  zone = "${var.zone2}"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  cidr = "${var.zone2_cidr}"
}

resource "ibm_is_subnet" "subnet1" {
  name            = "subnet1"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${var.zone1}"
  ipv4_cidr_block = "${var.zone1_cidr}"
  depends_on      = ["ibm_is_vpc_address_prefix.vpc-ap1"]
}

resource "ibm_is_subnet" "subnet2" {
  name            = "subnet2"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${var.zone2}"
  ipv4_cidr_block = "${var.zone2_cidr}"
  depends_on      = ["ibm_is_vpc_address_prefix.vpc-ap2"]
}

resource "ibm_is_instance" "instance1" {
  name    = "instance1"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface {
    subnet = "${ibm_is_subnet.subnet1.id}"
  }
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "${var.zone1}"
  keys = ["${data.ibm_is_ssh_key.sshkey1.id}"]
  user_data = "${data.template_cloudinit_config.cloud-init-apptier.rendered}"
}

resource "ibm_is_instance" "instance2" {
  name    = "instance2"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface {
    subnet = "${ibm_is_subnet.subnet2.id}"
  }
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "${var.zone2}"
  keys = ["${data.ibm_is_ssh_key.sshkey1.id}"]
  user_data = "${data.template_cloudinit_config.cloud-init-apptier.rendered}"
}

resource "ibm_is_floating_ip" "floatingip1" {
  name = "fip1"
  target = "${ibm_is_instance.instance1.primary_network_interface.0.id}"
}

resource "ibm_is_floating_ip" "floatingip2" {
  name = "fip2"
  target = "${ibm_is_instance.instance2.primary_network_interface.0.id}"
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule_22" {
  depends_on = ["ibm_is_floating_ip.floatingip1", "ibm_is_floating_ip.floatingip2"]
  group     = "${ibm_is_vpc.vpc1.default_security_group}"
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = "22"
    port_max = "22"
  }
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule_80" {
  depends_on = ["ibm_is_floating_ip.floatingip1", "ibm_is_floating_ip.floatingip2"]
  group     = "${ibm_is_vpc.vpc1.default_security_group}"
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = "80"
    port_max = "80"
  }
}
