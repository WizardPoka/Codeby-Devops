variable "cloud_id" {
  description = "ID облака Yandex Cloud. Можно не задавать, если задан YC_CLOUD_ID."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "ID каталога Yandex Cloud. Можно не задавать, если задан YC_FOLDER_ID."
  type        = string
  default     = null
}

variable "zone" {
  description = "Зона доступности Yandex Cloud."
  type        = string
  default     = "ru-central1-a"
}

variable "network_name" {
  description = "Имя VPC по умолчанию."
  type        = string
  default     = "default"
}

variable "public_subnet_cidr" {
  description = "CIDR публичной подсети."
  type        = string
  default     = "192.168.10.0/24"
}

variable "ssh_source_cidr" {
  description = "Откуда разрешён SSH. Для учебного стенда по умолчанию отовсюду."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_name" {
  description = "Имя публичной ВМ (она же bastion для приватной конфигурации)."
  type        = string
  default     = "codeby-lesson14-public"
}

variable "vm_user" {
  description = "Пользователь Ubuntu в облачном образе."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу, который добавится в metadata ВМ."
  type        = string
  default     = "~/.ssh/codeby_lesson14.pub"
}

variable "ssh_private_key_path" {
  description = "Путь к приватному SSH-ключу для provisioner."
  type        = string
  default     = "~/.ssh/codeby_lesson14"
}
