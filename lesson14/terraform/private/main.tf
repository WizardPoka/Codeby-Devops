data "yandex_vpc_network" "default" {
  name = var.network_name
}

# Эти объекты создаёт первая конфигурация (terraform/public).
data "yandex_vpc_subnet" "public" {
  name = var.public_subnet_name
}

data "yandex_compute_instance" "bastion" {
  name = var.bastion_name
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# NAT gateway нужен, чтобы ВМ в приватной подсети могла скачивать пакеты
# и устанавливать nginx, но при этом не имела публичного IP.
resource "yandex_vpc_gateway" "nat" {
  name = "codeby-lesson14-nat"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name       = "codeby-lesson14-private"
  network_id = data.yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "private" {
  name           = "codeby-lesson14-private"
  description    = "Private subnet for lesson 14"
  zone           = var.zone
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.private.id
}

resource "yandex_vpc_security_group" "private" {
  name        = "codeby-lesson14-private"
  description = "SSH and 8080 only from the public subnet"
  network_id  = data.yandex_vpc_network.default.id

  ingress {
    description    = "SSH from public subnet"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [data.yandex_vpc_subnet.public.v4_cidr_blocks[0]]
  }

  ingress {
    description    = "nginx 8080 from public subnet"
    protocol       = "TCP"
    port           = 8080
    v4_cidr_blocks = [data.yandex_vpc_subnet.public.v4_cidr_blocks[0]]
  }

  egress {
    description    = "Any outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "private" {
  name        = var.vm_name
  description = "Private VM with nginx on 8080, created by Terraform"
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
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.private.id]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${file(var.ssh_public_key_path)}"
  }

  # SSH идёт через публичную ВМ, потому что у приватной нет публичного IP.
  connection {
    type                = "ssh"
    user                = var.vm_user
    host                = self.network_interface[0].ip_address
    private_key         = file(var.ssh_private_key_path)
    bastion_host        = data.yandex_compute_instance.bastion.network_interface[0].nat_ip_address
    bastion_user        = var.vm_user
    bastion_private_key = file(var.ssh_private_key_path)
    timeout             = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx",
      "echo 'server { listen 8080 default_server; listen [::]:8080 default_server; root /var/www/html; index index.html; server_name _; location / { try_files $uri $uri/ =404; } }' | sudo tee /etc/nginx/sites-available/default >/dev/null",
      "sudo nginx -t",
      "sudo systemctl enable --now nginx",
      "sudo systemctl restart nginx",
      "echo \"private $(hostname)\" | sudo tee /var/www/html/index.html >/dev/null",
      "curl -fsS http://127.0.0.1:8080/ >/dev/null",
      "ss -lnt | grep ':8080'",
    ]
  }
}
