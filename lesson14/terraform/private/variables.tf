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

variable "public_subnet_name" {
  description = "Имя публичной подсети из первой конфигурации."
  type        = string
  default     = "codeby-lesson14-public"
}

variable "bastion_name" {
  description = "Имя публичной ВМ из первой конфигурации."
  type        = string
  default     = "codeby-lesson14-public"
}

variable "private_subnet_cidr" {
  description = "CIDR приватной подсети."
  type        = string
  default     = "192.168.20.0/24"
}

variable "vm_name" {
  description = "Имя приватной ВМ."
  type        = string
  default     = "codeby-lesson14-private"
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

variable "manage_imported_vm" {
  description = "Включает управление вручную созданной ВМ после terraform import."
  type        = bool
  default     = false
}

variable "imported_vm_name" {
  description = "Имя вручную созданной ВМ для импорта."
  type        = string
  default     = "codeby-lesson14-manual"
}
