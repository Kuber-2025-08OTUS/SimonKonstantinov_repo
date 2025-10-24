FROM python:3.10-slim

WORKDIR /app

# Устанавливаем зависимости
RUN pip install kopf kubernetes

# Копируем оператор
COPY mysql-operator-custom.py /app/operator.py

# Запускаем оператор
CMD ["python", "/app/operator.py"]
