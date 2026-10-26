# Урок 11. Ansible: окружения dev и prod

Домашнее задание: установить Ansible, поднять в Vagrant две ВМ (`dev` и `prod`),
создать inventory для каждого окружения и playbook, который устанавливает
`wget`, `htop`, `nginx`, запускает nginx и выводит название окружения.

## Структура

```text
lesson12/
├── Vagrantfile                 # две ВМ: dev (192.168.56.10) и prod (192.168.56.11)
├── scripts/
│   └── bootstrap.sh            # только python3 для Ansible + ожидание cloud-init
├── ansible/
│   ├── ansible.cfg             # окружение по умолчанию — dev
│   ├── env/
│   │   ├── dev/inventory
│   │   └── prod/inventory
│   └── playbooks/
│       └── site.yml            # пакеты, nginx, проверка HTTP, debug окружения
├── logs/                       # текстовые логи выполнения
├── screenshots/                # скриншоты для отчёта
└── README.md
```

## Требования

- Vagrant 2.4+
- VirtualBox 7+
- Ansible (`ansible-core` 2.16+)
- Стандартный Vagrant insecure key: `~/.vagrant.d/insecure_private_key`

Ansible установлен в `~/.local/bin`. Если этой директории нет в `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Приватный ключ в репозиторий не добавляется: Vagrant создаёт его сам,
а `config.ssh.insert_key = false` оставляет стандартный ключ Vagrant,
который есть в любой установке. Это учебный стенд, не production.

По умолчанию используется публичный box `bento/ubuntu-24.04`. Если Vagrant
Cloud недоступен, box можно переопределить через переменную окружения:

```bash
VAGRANT_BOX=codeby/noble64 vagrant up
```

## Запуск

```bash
# 1. Поднять обе ВМ
cd lesson12
vagrant up

# 2. Проверить статус
vagrant status

# 3. Перейти в каталог Ansible (там лежит ansible.cfg)
cd ansible

# 4. Проверить инвентарь и SSH-подключение
ansible-inventory --graph
ansible all -m ping

# 5. Выполнить playbook для dev (окружение по умолчанию из ansible.cfg)
ansible-playbook playbooks/site.yml

# 6. Выполнить playbook для prod
ansible-playbook -i env/prod/inventory playbooks/site.yml
```

Ожидаемый фрагмент вывода:

```text
TASK [Show which environment is being configured] *****************************
ok: [dev-vm] => {
    "msg": "This host is in dev environment"
}
```

Для prod — соответственно `This host is in prod environment`.

## Результат выполнения

Проверено 26.10.2026 на Ubuntu 24.04, VirtualBox 7.0.16, Ansible core 2.21.5:

- `dev` — `192.168.56.10`, `running`
- `prod` — `192.168.56.11`, `running`
- `ansible all -m ping` — `pong` для обоих окружений
- playbook для dev: `changed=1`, для prod: `changed=1`
- повторный запуск: `changed=0` для обоих (идемпотентность)
- `nginx` — `active` и `enabled` на обеих ВМ
- `curl -I http://192.168.56.10` и `http://192.168.56.11` — `HTTP/1.1 200 OK`, `nginx/1.24.0`
- установлены `wget`, `htop`, `nginx`

Логи: `logs/`.

### Про box

В этом окружении Vagrant Cloud был недоступен, поэтому локально использовался
box `codeby/noble64`, собранный из официального cloud-образа Ubuntu 24.04.
В репозитории по умолчанию остаётся публичный `bento/ubuntu-24.04`; при
необходимости он переопределяется через `VAGRANT_BOX`.

## Проверка результата

```bash
# nginx отвечает на обеих ВМ
curl -I http://192.168.56.10
curl -I http://192.168.56.11

# пакеты установлены, сервис активен
vagrant ssh dev -c "systemctl is-active nginx && dpkg -l wget htop nginx | tail -n +6"
vagrant ssh prod -c "systemctl is-active nginx && dpkg -l wget htop nginx | tail -n +6"
```

## Что приложить к отчёту

Скриншоты (лежат в `screenshots/`):

- [x] `status_vagrant_ansible.png` — `vagrant status`, `ansible --version`, `ansible all -m ping`
- [x] `playbook_dev_prod.png` — playbook для dev и prod, строки `This host is in ... environment`
- [x] `nginx-dev.png` — браузер: `http://192.168.56.10`
- [x] `nginx-prod.png` — браузер: `http://192.168.56.11`

Обе ВМ отдают стандартную страницу `Welcome to nginx!` — это ожидаемо, задание
не требует разного контента. Различие окружений видно по IP-адресу в браузере
и по выводу playbook.

Текстовые логи (уже в `logs/`):

- [x] `ansible-version.txt`
- [x] `vagrant-status.txt`
- [x] `inventory-dev.txt`, `inventory-prod.txt`
- [x] `syntax-check.txt`
- [x] `ping-dev.txt`, `ping-prod.txt`
- [x] `playbook-dev.txt`, `playbook-prod.txt`
- [x] `idempotency-dev.txt`, `idempotency-prod.txt`
- [x] `vm-check-dev.txt`, `vm-check-prod.txt`
- [x] `curl-both.txt`

## Статус

- [x] Ansible установлен
- [x] Vagrant: `dev` + `prod`
- [x] inventory для двух окружений
- [x] playbook: пакеты, nginx, debug окружения
- [x] SSH-подключение по ключу
- [x] Логи выполнения
- [x] Скриншоты
- [x] Commit / push ветки `lesson12`
- [ ] PR `lesson12 -> main`

## Остановка и удаление

```bash
cd lesson12
vagrant halt          # остановить
vagrant destroy -f    # удалить обе ВМ
```
