FROM python:3.9-alpine3.17


WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
RUN apk add curl

COPY . .

CMD [ "python3", "app.py"]
