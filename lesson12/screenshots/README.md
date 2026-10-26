# Скриншоты к уроку 11

Складывать сюда, имена — по списку из `../README.md`.

| Файл | Что должно быть видно |
|---|---|
| `01-vagrant-status.png` | `vagrant status`: `dev` и `prod` в состоянии `running` |
| `02-ansible-version.png` | Вывод `ansible --version` (видно версию core) |
| `03-ping-dev.png` | `ansible all -m ping` для окружения dev: `pong` |
| `04-playbook-dev.png` | `PLAY RECAP` и строка `This host is in dev environment` |
| `05-playbook-prod.png` | `PLAY RECAP` и строка `This host is in prod environment` |
| `06-nginx-dev.png` | Браузер открывает `http://192.168.56.10` (Welcome to nginx) |
| `07-nginx-prod.png` | Браузер открывает `http://192.168.56.11` (Welcome to nginx) |

Скриншоты делаются с терминала и браузера на хосте. Главное — чтобы был виден
контекст: имя окружения, команда и результат.
