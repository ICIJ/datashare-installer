@echo off
docker-compose up -d
start "" http://localhost:8080
pause