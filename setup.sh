#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# Prompt the user for the project directory and name 
read -p "Enter the project directory: " work_directory
read -p "Enter the project name: " project_name


# Change into the Development directory
mkdir -p ~/$work_directory
mkdir -p ~/$work_directory/$project_name
cd ~/$work_directory/$project_name


# Create virtual environment
pipenv --python 3.11


# Install Django and the dependencies for the React app in the pipenv environment
pipenv install django djangorestframework django-cors-headers django-webpack-loader libsass django-compressor django-sass-processor pytest-watch node npm


# Install django-webpack-loader
# pip install django-webpack-loader
# pip freeze > requirements.txt

  
# Create the Django project and app
pipenv run django-admin startproject config
mv -v ./config/* .
mv -v ./config/config/* ./config
rm ./config/config
pipenv run python manage.py startapp core


# Build templates, static and tests folder structure
cp -r $SCRIPT_DIR/project/templates ./
cp -r $SCRIPT_DIR/project/core/templates ./core
rm ./core/tests.py


# Make and run initial migrations
pipenv run python manage.py makemigrations
pipenv run python manage.py migrate


# Install create-react-app globally
OUTPUT=$( npm list -g create-react-app ) 

if [[ $OUTPUT != *"create-react-app"* ]]; then 
	npm install -g create-react-app
fi 

  
# Create React app and install initial dependencies
pipenv run npx create-react-app frontend
cd frontend
pipenv run npm install


# Configure Webpack - hybrid
pipenv run npm install --save-dev webpack-cli webpack-bundle-tracker
cp $SCRIPT_DIR/project/frontend/webpack.config.js .
echo -e "\n\nWEBPACK_LOADER = {\n    'DEFAULT': {\n    'CACHE': not DEBUG,\n    'BUNDLE_DIR_NAME': 'js/bundles/',\n    'STATS_FILE': os.path.join(BASE_DIR, 'frontend/webpack-stats.json'),\n    'POLL_INTERVAL': 0.1,\n    'IGNORE': [r'.+\.hot-update.js', r'.+\.map'],\n  }\n}" >> ./config/settings.py


# Install and configure Babel - hybrid
pipenv run npm install --save-dev @babel/core babel-loader @babel/preset-env @babel/preset-react svg-inline-loader axios
sed -i '/"scripts":/a \ \ \  "start-development": "webpack --mode development --watch",' ./package.json
sed -i '/start-development/a \ \ \  "build-production": "react-scripts build && webpack --config webpack.config.js --mode production",' ./package.json
cp $SCRIPT_DIR/project/frontend/.babelrc.js .


# Configure Sass Stylesheet
pipenv run npm install --save-dev sass
# mv ./src/App.css ./src/App.scss


# Configure proxy
cp ./frontend/package.json package.json
rm ./frontend/package.json
jq '. += { "proxy": "http://localhost:8000" }' package.json > ./frontend/package.json
# rm package.json


# Change to the project directory
cd ~/$work_directory/$project_name


# Configure docker
cp $SCRIPT_DIR/project/Dockerfile .
cp $SCRIPT_DIR/project/frontend/Dockerfile ./frontend
cp $SCRIPT_DIR/project/docker-compose.yml . 


# Configure settings.py
sed -i "/from pathlib import Path/a import os" ./config/settings.py
sed -i "/'django.contrib.staticfiles',/a\ \ \ \ 'rest_framework'," ./config/settings.py
sed -i "/'rest_framework',/a\ \ \ \ 'corsheaders'," ./config/settings.py
sed -i "/'corsheaders',/a\ \ \ \ 'webpack_loader'," ./config/settings.py
sed -i "/'webpack_loader',/a\ \ \ \ 'sass_processor'," ./config/settings.py
sed -i "/'sass_processor',/a\ \ \ \ 'core'," ./config/settings.py
sed -i "/'django.middleware.clickjacking.XFrameOptionsMiddleware',/a\ \ \ \ 'corsheaders.middleware.CorsMiddleware'," ./config/settings.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\ \n \ \ \ 'localhost\',\n    '127.0.0.1',\n    '0.0.0.0'\n\]/g" ./config/settings.py
sed -i '/STATIC_URL = '\''static\/'\''/a STATICFILES_DIRS = [ \n    os.path.join(BASE_DIR, "'static'"),\n    os.path.join(BASE_DIR, "'core\/static'"),\n    os.path.join(BASE_DIR, "'frontend\/build\/static'")\n]' ./config/settings.py
sed -i '/STATIC_URL = '\''static\/'\''/a STATICFILES_FINDERS = [ \n    "'django.contrib.staticfiles.finders.FileSystemFinder'",\n    "'django.contrib.staticfiles.finders.AppDirectoriesFinder'",\n    "'sass_processor.finders.CssFinder'"\n]' ./config/settings.py
sed -i '/DEBUG = True/a\ \nCORS_ORIGIN_WHITELIST = [\n    "'http://localhost:8000'",\n    "'http://localhost:3000'"\n]' ./config/settings.py


# Configure config/urls.py
sed -i -e "s/from django.urls import path/from django.urls import path, include/" ./config/urls.py
sed '/urlpatterns = \[/a \ \ \ \ ("", include("core.urls")),' -i ./config/urls.py


# Configure core/urls.py
touch ./core/urls.py
echo -e "from django.urls import path \n \n \nurlpatterns = [\n\n]" >> ./core/urls.py


# Initialize a git repository, create .gitignore
git init
touch .gitignore


# Iterate through each line in the ./frontend/.gitignore
while read line; do
    # Check if the line starts with a dot
    if [[ ${line:0:1} == "." ]]; then
        # Remove the dot and append "./frontend/" in front
        echo -e "./frontend/.${line:1}" >> .gitignore
	elif [[ ${line:0:1} == "/" ]]; then
		echo -e "./frontend/${line:1}" >> .gitignore
	elif [[ ${line:0:1} == "#" ]]; then
		echo -e "\n# ${line:1}" >> .gitignore
    fi
done < ./frontend/.gitignore

rm ./frontend/.gitignore


# Add other files to be ignored
echo "./db.sqlite3" >> .gitignore
echo ".pytest_cache"
echo "./core/migrations"


# Copy the start-developing.sh
cp $SCRIPT_DIR/start-developing.sh .


# Make the initial commit
git add .
git commit -m "Initial commit with Django REST and React setup."