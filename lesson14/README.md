# Урок 13. Terraform в Yandex Cloud

Домашнее задание: две конфигурации Terraform, публичная и приватная подсети
в VPC по умолчанию, ВМ в каждой подсети, nginx через Terraform provisioner
и импорт вручную созданной ВМ.

> Ветка репозитория: `lesson14` (по заданию), папка: `lesson14/`.
> Облако нужно для уроков 13, 14 и финального проекта.

## Архитектура

```text
Yandex Cloud, VPC default, зона ru-central1-a
│
├── public subnet 192.168.10.0/24
│   ├── security group: 22, 80, 443 снаружи
│   └── ВМ codeby-lesson14-public
│       ├── публичный IP
│       ├── nginx на 80
│       └── bastion для приватной ВМ
│
└── private subnet 192.168.20.0/24
    ├── route table -> NAT gateway (исходящий интернет)
    ├── security group: 22 и 8080 только из public subnet
    ├── ВМ codeby-lesson14-private
    │   ├── без публичного IP
    │   ├── nginx на 8080
    │   └── provisioner через bastion
    └── ВМ codeby-lesson14-manual
        └── создана вручную и импортирована в private-конфигурацию
```

Две независимые конфигурации:

- `terraform/public` — публичная подсеть, SG, ВМ, nginx;
- `terraform/private` — приватная подсеть, NAT, SG, ВМ, nginx на 8080,
  а также ресурс для импорта ручной ВМ.

## Инструменты

- Terraform `1.9.8` — установлен из зеркала Yandex Cloud:
  `https://hashicorp-releases.yandexcloud.net/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip`.
- Yandex Cloud CLI `1.41.0` — официальный установщик:
  `https://storage.yandexcloud.net/yandexcloud-yc/install.sh`.
- Провайдер `yandex-cloud/yandex` — из зеркала
  `https://terraform-mirror.yandexcloud.net/`, потому что
  `registry.terraform.io` недоступен из этой сети.
  Настройка зеркала лежит в `terraform/terraform.rc`.

Если `terraform` и `yc` не в `PATH`:

```bash
export PATH="$HOME/.local/bin:$HOME/.local/yandex-cloud/bin:$PATH"
```

## Быстрый старт

### 1. Подготовить Yandex Cloud

```bash
cd lesson14
./scripts/setup-yc.sh
```

Скрипт:

- запустит `yc init`, если профиля ещё нет (нужен браузер и аккаунт Yandex Cloud);
- создаст SSH-ключ `~/.ssh/codeby_lesson14`;
- создаст service account `codeby-terraform` с ролью `editor` на каталог;
- создаст IAM-ключ `~/.config/yandex-cloud/codeby-terraform-key.json`;
- запишет env-файл `~/.config/yandex-cloud/codeby-terraform.env`;
- создаст `terraform.tfvars` в обеих конфигурациях.

Секреты в репозиторий не попадают: `terraform.tfvars` и ключи исключены
через `lesson14/.gitignore`.

### 2. Подключить окружение

```bash
source ~/.config/yandex-cloud/codeby-terraform.env
```

### 3. Публичная конфигурация

```bash
cd terraform/public
terraform init
terraform apply
```

Terraform создаст публичную подсеть, security group и ВМ. Provisioner
установит nginx и проверит `http://127.0.0.1/`.

Полезные выводы:

```bash
terraform output
terraform output -raw public_ip
```

### 4. Приватная конфигурация

```bash
cd ../private
terraform init
terraform apply
```

Она читает публичную подсеть и публичную ВМ как bastion. Provisioner
подключается к приватной ВМ через bastion и ставит nginx на 8080.

### 5. Проверка

```bash
cd ../..
./scripts/verify.sh
```

Либо вручную:

```bash
cd terraform/public
PUBLIC_IP=$(terraform output -raw public_ip)
curl -I "http://$PUBLIC_IP/"

cd ../private
PRIVATE_IP=$(terraform output -raw private_ip)
ssh -i ~/.ssh/codeby_lesson14 -J "ubuntu@$PUBLIC_IP" "ubuntu@$PRIVATE_IP" \
  'curl -I http://127.0.0.1:8080/ && systemctl is-active nginx'
```

## Задание с импортом

Импорт выполняется во вторую (приватную) конфигурацию.

### 1. Создать ВМ вручную

```bash
cd lesson14
source ~/.config/yandex-cloud/codeby-terraform.env
./scripts/create-manual-vm.sh
```

Скрипт создаёт `codeby-lesson14-manual` в приватной подсети через `yc`
и кладёт ID в `logs/manual-instance-id.txt`.

### 2. Импортировать

```bash
./scripts/import-manual-vm.sh
```

Скрипт выполняет:

```bash
cd terraform/private
terraform import \
  -var manage_imported_vm=true \
  'yandex_compute_instance.imported[0]' <instance-id>
terraform plan -var manage_imported_vm=true
```

Проверка:

```bash
cd terraform/private
terraform state list | grep imported
terraform state show 'yandex_compute_instance.imported[0]'
```

## Скриншоты для отчёта

Складывать в `lesson14/screenshots/`:

- [ ] `01-terraform-yc-version.png` — `terraform version`, `yc version`;
- [ ] `02-public-apply.png` — успешный `terraform apply` публичной конфигурации
  и `terraform output`;
- [ ] `03-public-nginx.png` — браузер `http://<public_ip>/`, страница nginx;
- [ ] `04-private-apply.png` — успешный `terraform apply` приватной конфигурации
  и `terraform output`;
- [ ] `05-private-nginx.png` — терминал: `curl -I http://<private_ip>:8080/`
  с публичной ВМ или через `ssh -J`, ответ `200 OK`;
- [ ] `06-vpc-subnets.png` — консоль Yandex Cloud: две подсети
  `codeby-lesson14-public` и `codeby-lesson14-private` в сети `default`;
- [ ] `07-security-groups.png` — консоль: правила SG public (22/80/443)
  и private (22/8080);
- [ ] `08-manual-vm.png` — консоль: ВМ `codeby-lesson14-manual`
  в приватной подсети;
- [ ] `09-terraform-import.png` — терминал: `Import successful!`,
  `terraform state list` с `yandex_compute_instance.imported[0]`;
- [ ] `10-terraform-state.png` — `terraform state list` обеих конфигураций.

Достаточно и объединённых скриншотов, главное — чтобы были видны команда,
IP/имя ресурса и результат.

## Логи

`scripts/verify.sh` и `scripts/import-manual-vm.sh` складывают доказательства
в `lesson14/logs/`:

- `public-outputs.json`, `private-outputs.json`;
- `addresses.txt`;
- `nginx-checks.txt`;
- `terraform-state.txt`;
- `manual-instance-create.json`, `manual-instance-id.txt`;
- `terraform-import.txt`.

Дополнительно можно сохранить:

```bash
terraform -chdir=terraform/public output > logs/public-output.txt
terraform -chdir=terraform/private output > logs/private-output.txt
yc vpc subnet list > logs/yc-subnets.txt
yc compute instance list > logs/yc-instances.txt
yc vpc security-group list > logs/yc-security-groups.txt
```

## Стоимость

Для задания создаются платные ресурсы:

- две ВМ `standard-v3`, 2 vCPU / 2 ГБ, core fraction 20%;
- публичный IP;
- NAT gateway;
- диски по 10 ГБ.

Это учебный стенд, а не production. После снятия скриншотов удалите ресурсы:

```bash
cd terraform/private
terraform destroy

cd ../public
terraform destroy
```

Если ВМ создана вручную и ещё не импортирована:

```bash
yc compute instance delete --name codeby-lesson14-manual
```

## Ограничения

- Провайдер скачивается только через зеркало Yandex Cloud, потому что
  публичный Terraform Registry недоступен.
- Приватная ВМ не имеет публичного IP. SSH и проверка nginx идут через
  публичную ВМ (bastion / `ssh -J`).
- В `private` используются `data`-источники публичной конфигурации,
  поэтому порядок применения строгий: сначала `public`, потом `private`.
- Импортированная ВМ включается переменной `manage_imported_vm`, чтобы
  обычный `terraform apply` не создавал её автоматически.
