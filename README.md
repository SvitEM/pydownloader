# Скрипт для скачивания Python библиотек 
## Зачем нужен
Решает проблемы с загрузкой библиотек, когда в зависимостях есть библиотеки необходимые в билде (сурсы)
## Requirements
- Локальная машина
- Docker
- make для запуска makefile
## Usage
Установить reqirements
```bash
pip install -r reqirements.txt
```
Запустить экземпляр Redis в docker
```bash
docker run -d -p 6379:6379 redis
```
Запустить таски в celery для: 

Скачивания библиотек и построения контейнеров:
```bash
celery -A tasks.celery_app worker --loglevel=info
```
Удаления старых архивов:
```bash
celery -A tasks.celery_app beat --loglevel=info
```
Запустить сервер:
```bash
uvicorn main:app
```

## Установка библиотек на сервер
Перенесите скаченные библиотеки через облачное хранилище и распакуйте в папке на сервере (например libs), активируйте ваше виртуальное окружение и выполните
```bash
pip3 install your_lib_name --no-index --find-links libs
```
## Другие команды
Для смены версии Python
```bash
make build
```
Для удаления существующих образов и контейнеров из системы
```bash
make uninstall
```

TODO
1) Добавить поддержку других платформ
2) Реализовать восстановление подключения к процессу очереди после перезагрузки