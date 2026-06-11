# Pick the FROM that matches your language choice above.
# Python:
FROM python:3.11-slim
# Node:
# FROM node:20-alpine

WORKDIR /app
COPY app.py .
# For Node, use: COPY app.js .
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*
ENV PORT=8000
EXPOSE 8000

# Python:
CMD ["python", "app.py"]
# Node:
# CMD ["node", "app.js"]
