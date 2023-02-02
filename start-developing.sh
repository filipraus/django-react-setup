#!/bin/bash

# Backend
gnome-terminal -- bash -c "pipenv run python manage.py runserver; read -p \"Press [Enter] key to close terminal...\""
gnome-terminal -- bash -c "pipenv run ptw; read -p \"Press [Enter] key to close terminal...\""

# Frontend
gnome-terminal -- bash -c "cd frontend; pipenv run npm run start-development; read -p \"Press [Enter] key to close terminal...\""
gnome-terminal -- bash -c "cd frontend; pipenv run npm run test; read -p \"Press [Enter] key to close terminal...\""