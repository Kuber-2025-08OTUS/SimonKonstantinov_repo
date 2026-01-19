# Установка Yandex Cloud CLI

## Быстрая установка (автоматическая)

Скопируйте и выполните на ВМ:

```bash
# Скачивание и выполнение скрипта установки
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

# Добавление в PATH
export PATH=$PATH:$HOME/.yandex-cloud/bin
echo 'export PATH=$PATH:$HOME/.yandex-cloud/bin' >> ~/.bashrc

# Проверка установки
yc version
```

## Или используйте скрипт из репозитория

```bash
# Скопируйте скрипт на ВМ и выполните
sudo bash install-yc-cli.sh
```

## Ручная установка

```bash
# Создание директории
mkdir -p ~/.yandex-cloud/bin

# Скачивание YC CLI
wget -q https://storage.yandexcloud.net/yandexcloud-yc/install.sh -O - | bash

# Или для конкретной версии
VERSION=$(curl -s https://api.github.com/repos/yandex-cloud/yandex-cloud-cli/releases/latest | grep tag_name | cut -d '"' -f 4)
wget -q https://storage.yandexcloud.net/yandexcloud-yc/release/${VERSION}/linux/amd64/yc -O ~/.yandex-cloud/bin/yc
chmod +x ~/.yandex-cloud/bin/yc

# Добавление в PATH
export PATH=$PATH:$HOME/.yandex-cloud/bin
echo 'export PATH=$PATH:$HOME/.yandex-cloud/bin' >> ~/.bashrc

# Проверка
yc version
```

## Инициализация YC CLI

После установки выполните инициализацию:

```bash
yc init
```

Вам будет предложено:
1. Войти в аккаунт (через браузер)
2. Выбрать облако
3. Выбрать каталог (folder)

## Проверка настройки

```bash
# Проверка конфигурации
yc config list

# Проверка доступности
yc compute instance list
```
