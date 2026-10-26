data "yandex_vpc_network" "default" {
  name = var.network_name
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_subnet" "public" {
  name           = "codeby-lesson14-public"
  description    = "Public subnet for lesson 14"
  zone           = var.zone
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

resource "yandex_vpc_security_group" "public" {
  name        = "codeby-lesson14-public"
  description = "SSH, HTTP and HTTPS for the public VM"
  network_id  = data.yandex_vpc_network.default.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.ssh_source_cidr]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Any outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "public" {
  name        = var.vm_name
  description = "Public VM with nginx, created by Terraform"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.public.id]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${file(var.ssh_public_key_path)}"
  }

  connection {
    type        = "ssh"
    user        = var.vm_user
    host        = self.network_interface[0].nat_ip_address
    private_key = file(var.ssh_private_key_path)
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx",
      "sudo systemctl enable --now nginx",
      "echo \"public $(hostname)\" | sudo tee /var/www/html/index.html >/dev/null",
      "curl -fsS http://127.0.0.1/ >/dev/null",
      "systemctl is-active nginx",
    ]
  }
}
