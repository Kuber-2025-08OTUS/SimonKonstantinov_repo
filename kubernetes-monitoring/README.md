# ДЗ по Мониторингу: Nginx + Prometheus

## Шаг 1: Кастомный образ nginx с метриками

### Структура
```
├── Dockerfile          # Образ nginx с метриками
├── nginx.conf          # Конфиг с endpoint /basic_status
└── README.md           # Этот файл
```

### Сборка образа

```
docker build -t custom-nginx-metrics:latest .
```

### Тестирование локально

```
# Запуск контейнера
docker run -d -p 8080:80 --name nginx-test custom-nginx-metrics:latest

# Проверка главной страницы
curl http://localhost:8080/

# Проверка метрик
curl http://localhost:8080/basic_status
```

Метрики должны выглядеть так:
```
Active connections: 1 
server accepts handled requests
 7 7 7 
Reading: 0 Writing: 1 Waiting: 0
```

### Остановка тестового контейнера

```
docker stop nginx-test
docker rm nginx-test
```

## Описание метрик

- **Active connections**: текущее число активных соединений
- **accepts**: суммарное число принятых соединений
- **handled**: суммарное число обработанных соединений
- **requests**: суммарное число клиентских запросов
- **Reading**: соединения, в которых nginx читает заголовок запроса
- **Writing**: соединения, в которых nginx отвечает клиенту
- **Waiting**: бездействующие соединения в ожидании запроса
