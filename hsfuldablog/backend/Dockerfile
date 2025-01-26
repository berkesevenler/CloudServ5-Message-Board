FROM python:3.9-slim

WORKDIR /app

# Install pip and dependencies
RUN apt-get update && apt-get install -y python3-pip && apt-get clean

COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python3", "app.py"]
