# Вэб сервис для скачивания и проверки Python библиотек на уязвимости
## Зачем нужен
Решает проблемы с загрузкой библиотек, когда в зависимостях есть библиотеки необходимые в билде (сурсы)
## Requirements
- Docker
- make для запуска makefile
## Usage
Настроить окружение
```bash
make setup
```
Запустить сервис
```bash
make start
```
Для остановки сервиса
```bash
make stop
```

TODO
1) Добавить поддержку других платформ
2) Реализовать восстановление подключения к процессу очереди после перезагрузки страницы