variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
variable "publickey" {}
variable "ssh_cidr" {}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "alicloud_security_group" "sg" {
  name   = "terraform-sg"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "${var.ssh_cidr}"
}

resource "alicloud_vpc" "vpc" {
  name = "terraform-vpc"
  cidr_block = "192.168.1.0/24"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "192.168.1.0/28"
  availability_zone = "${var.zone}"
}

resource "alicloud_instance" "web" {
  count = 3
  instance_name = "terraform-ecs"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  internet_max_bandwidth_out = 10
}

resource "alicloud_key_pair" "key" {
  key_name = "my_public_key"
  public_key = "${var.publickey}"
}

resource "alicloud_key_pair_attachment" "attach" {
  key_name = "${alicloud_key_pair.key.id}"
  instance_ids = ["${alicloud_instance.web.*.id}"]
}
