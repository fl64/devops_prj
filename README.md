# devops_prj

## Intro

Проектная работа по курсу "Практики и инструменты DevOps".
В качестве приложения для автоматизации используется поисковый бот для сбора текстовой информации с веб-страниц и ссылок.

Приложение состоит из двух компоент:
- Бот - Search Engine Crawler (https://github.com/express42/search_engine_crawler)
- Интерфейс для поиска - Search Engine UI (https://github.com/express42/search_engine_ui)

Для реализации проекта используются следуюшие приложения и инструменты:
Инфраструктура:
- GCP
- terraform
- ansible
CI\CD:
- gitlab ci
Мониторинг:
- prometheus
- alertmanager
	- настроеное оповещение в Slack
- nodeexporter
- mongodb exporter
- grafana
Логирование:
- EFK

Параметры запуска проекта:
- Название проекта: devops-prj
- Зона: europe-west4-a

![](https://imgur.com/ytFUq7k)

## Установка окружения

### Требования

- Наличие учетной записи и денежных средств в GCP.
- Рабочая станция под управлением Linux (проверялось на Fedora 28)
- Установленное ПО:
	- Git 2.17.1
	- Google Cloud SDK 208.0.1
	- Ansible 2.5.0
	- Terraform 0.11.7
- Созданный проект в GCP (например "devops-prj")

### Установка инфраструктуры
- настроить аккаунт и проект в GCP:
	- `gcloud init`
	- `gcloud auth application-default login`
- клонировать данный репозиторий `git clone https://github.com/fl64/devops_prj`
- сгенерировать ssh-ключи для доступа к виртуальным серверам `ssh-keygen -t rsa -f dockerhost -C 'dockerhost' -q -N ''`
- создать сервисную учетную запись в GCP
	- `gcloud iam service-accounts create devops-prj-sa --display-name "DevOps Prj Service Account"`
	- Проверить: `gcloud iam service-accounts list`
	- Вывести список ролей `gcloud iam roles list`
	- Добавить роль для сервисоного аккаунта: `gcloud projects add-iam-policy-binding devops-prj --member serviceAccount:devops-prj-sa@devops-prj.iam.gserviceaccount.com --role roles/owner`
	-- создать файл ключ для сервисного аккаунта (пригодится при настройки gitlab): `gcloud iam service-accounts keys create key.json --iam-account SA-NAME@PROJECT-ID.iam.gserviceaccount.com` пример: `gcloud iam service-accounts keys create key.json --iam-account devops-prj-sa@devops-prj.iam.gserviceaccount.com` **todo: уточнить требуемую роль**

С использованием terrform установить 2 вртуальных сервера в GCP (Gitlab CI и Prod-сервер)
- в каталоге infra/terraform
	- задать значения переменнных в файле .terraform.tfvars (пример настроек приведен в .terraform.tfvars.example)
	- `terraform plan`
	- `terraform apply`
Зафиксировать публичные адреса созданных виртуальных серверов (`terraform output`).

Установить docker/docker-compose на серверах и Gitlab на сервере Gitlab.
- в каталоге infra/asnible
	- выполнить `ansible playbooks/start.yml`

### Подготовка оповещений в Slack
- в конфигурационный файл alertmanager (config.yml) добавиь хук для подключения к slack и канал для отправки оповещений
- собрать контейнер и выполнит пуш на hub.docker.com (docker/alertmanager/build.sh)

### Настройка Gitlab CI
- Перейти по адресу http://gitlib-ci-ip/
- На стартовой странице задать пароль пользователя root и выполнить вход
- перейти по ссылке http://gitlib-ci-ip/admin, Settings --> Sign-up restrictions, убрать маркер Sign-up enabled
- перейти по ссылке http://gitlib-ci-ip/dashboard/groups --> New group --> Group name: devops-prj
- перейти по ссылке http://gitlib-ci-ip/projects/new --> Project-name: app
- в настройках группы devops-prj (devops-prj --> app --> CI / CD Settings --> Variables) задать значения переменных:
	- DOCKERHUB_USERNAME - логин на docker hub
	- DOCKERHUB_PASSWORD - пароль на docker hub
	- PROD_PRIV_KEY - закрытый ключ для доступа к серверу (`cat ~/.ssh/dockerhost`)
	- PROD_IP - ip-адрес prod-сервера (`terraform output prod_external_ip`)
	- GCP_PRJ - название проекта в GCP (devops-prj)
	- GCP_CRED - в переменную вставить содержимое файла ключа (key.json) созданного ранее сервисного акканута GCP
	- GCP_ZONE - зона в GCP для создания тестовых сред
- в настройках CI/CD группы скопировать токен раннеров (devops-prj --> app --> CI / CD Settings -->  Runners settings )
- на сервере gitlab выполнить:
(в команде указать занчения для /<gitlab-ci-ip/>, /<token/>)
``` bash
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

docker exec -i gitlab-runner /usr/bin/gitlab-runner register \
--non-interactive --url=http://<gitlab-ci-ip> \
--executor=docker --docker-privileged=true \
--docker-image=python:3.6-alpine --registration-token=<token> \
--description=docker-runner --tag-list=docker --run-untagged=true \
--locked=false tags: gitlab-ci, gitlab-runner
```

- или выполнить `ansible playbooks/runners.yml --extra-vars "gitlabci_token=<token> runners_count=<count>"` для автоматической установки раннеров
Пример: `ansible-playbook playbooks/runners.yaml --extra-vars "gitlabci_token=1dQ1CZv22StsSHxmYpMy runners_count=3"`

### Настройка Git для gitlab
Выполнить настройку для GIT в gitlab CI и запушить все даныне
```
git remote add gitlab http://<gitlab-ci-ip>/devops_prj/app.git
#git add .
#git commit -m "Initial commit"

git push gitlab --all
```
### Смена адреса на Gitlab
После остановки VM gitlab может измениться внешний ip-адрес, поэтому:
на хосте gitlab:
- Убить все контейнеры:
	- `ssh dockerhost@gitlab-ip "sudo docker kill $(sudo docker ps -a -q)"`
	- `ssh dockerhost@gitlab-ip "sudo docker rm $(sudo docker ps -a -q)"`
- повторить установку gitlab ci + раннеров с использрванием ansible.
- повторить процедуру добавления репозитория.

!!! При слишком частом запуске деплоя на прод, адрес GitlabCI может быть забанен ssh guard. Для избежания этого на VM Prod, адрес Gitlab CI необходимо внести в witelist (/etc/sshguard/whitelist).