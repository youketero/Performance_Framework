FROM python:3.12-alpine

WORKDIR /app

COPY requirements.txt .
RUN python -m venv venv
RUN . venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt

COPY app app

EXPOSE 8000

CMD ["/app/venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
