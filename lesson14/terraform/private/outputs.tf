output "private_instance_name" {
  description = "Имя приватной ВМ."
  value       = yandex_compute_instance.private.name
}

output "private_ip" {
  description = "Внутренний IP приватной ВМ."
  value       = yandex_compute_instance.private.network_interface[0].ip_address
}

output "private_subnet_id" {
  description = "ID приватной подсети."
  value       = yandex_vpc_subnet.private.id
}

output "private_security_group_id" {
  description = "ID security group приватной ВМ."
  value       = yandex_vpc_security_group.private.id
}

output "nat_gateway_id" {
  description = "ID NAT gateway."
  value       = yandex_vpc_gateway.nat.id
}

output "private_ssh_command" {
  description = "SSH к приватной ВМ через публичную (ProxyJump)."
  value       = "ssh -J ${var.vm_user}@${data.yandex_compute_instance.bastion.network_interface[0].nat_ip_address} ${var.vm_user}@${yandex_compute_instance.private.network_interface[0].ip_address}"
}

output "private_nginx_url" {
  description = "URL nginx на приватной ВМ (доступен из публичной подсети)."
  value       = "http://${yandex_compute_instance.private.network_interface[0].ip_address}:8080/"
}

output "private_curl_from_bastion" {
  description = "Команда проверки nginx на приватной ВМ с публичной ВМ."
  value       = "ssh ${var.vm_user}@${data.yandex_compute_instance.bastion.network_interface[0].nat_ip_address} 'curl -fsS http://${yandex_compute_instance.private.network_interface[0].ip_address}:8080/'"
}

output "imported_instance_id" {
  description = "ID импортированной вручную созданной ВМ."
  value       = var.manage_imported_vm ? yandex_compute_instance.imported[0].id : null
}
