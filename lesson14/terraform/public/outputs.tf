output "public_instance_name" {
  description = "Имя публичной ВМ."
  value       = yandex_compute_instance.public.name
}

output "public_ip" {
  description = "Публичный IP публичной ВМ."
  value       = yandex_compute_instance.public.network_interface[0].nat_ip_address
}

output "public_internal_ip" {
  description = "Внутренний IP публичной ВМ."
  value       = yandex_compute_instance.public.network_interface[0].ip_address
}

output "public_subnet_id" {
  description = "ID публичной подсети."
  value       = yandex_vpc_subnet.public.id
}

output "public_security_group_id" {
  description = "ID security group публичной ВМ."
  value       = yandex_vpc_security_group.public.id
}

output "public_ssh_command" {
  description = "Команда SSH-подключения к публичной ВМ."
  value       = "ssh ${var.vm_user}@${yandex_compute_instance.public.network_interface[0].nat_ip_address}"
}

output "public_http_url" {
  description = "URL nginx на публичной ВМ."
  value       = "http://${yandex_compute_instance.public.network_interface[0].nat_ip_address}/"
}
