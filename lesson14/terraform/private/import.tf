# Ресурс для ручной ВМ, которая импортируется в эту конфигурацию.
#
# Пока manage_imported_vm = false, ресурс не создаётся и не управляется.
# После ручного создания ВМ:
#
#   terraform import \
#     -var manage_imported_vm=true \
#     'yandex_compute_instance.imported[0]' <instance-id>
#
# Затем:
#
#   terraform plan -var manage_imported_vm=true
#
# Имя, зона, образ, размеры и подсеть должны совпадать с ручной ВМ,
# иначе Terraform после импорта предложит изменения.

resource "yandex_compute_instance" "imported" {
  count = var.manage_imported_vm ? 1 : 0

  name        = var.imported_vm_name
  description = "Manually created VM imported into Terraform"
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

  lifecycle {
    # metadata и назначенный облаком IP не должны вызывать ложный diff.
    ignore_changes = [metadata]
  }
}
