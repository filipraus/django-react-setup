#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# Prompt the user for the project directory and name 
read -p "Enter the project directory: " project_directory
read -p "Enter the project name: " project_name


# Change into the Development directory
mkdir -p ~/$project_directory
mkdir -p ~/$project_directory/$project_name
cd ~/$project_directory/$project_name


# Install docker and docker-compose
echo "Follow the official instruction at https://docs.docker.com/engine/install/fedora/"


# Create virtual environment
pipenv --python 3.11


# Install Django and the dependencies for the React app in the pipenv environment
pipenv install django djangorestframework django-cors-headers django-webpack-loader node npm

  
# Create the Django project and app
pipenv run django-admin startproject config
mv config source
cd source
pipenv run python manage.py startapp core


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

# Include the following in the settings.py
# WEBPACK_LOADER = {
#     'DEFAULT': {
#         'CACHE': not DEBUG,
#         'BUNDLE_DIR_NAME': './js/bundles/',
#         'STATS_FILE': os.path.join(BASE_DIR, 'webpack-stats.json'),
#         'POLL_INTERVAL': 0.1,
#         'TIMEOUT': None,
#         'IGNORE': ['.+\.hot-update.js', '.+\.map']
#     }
# }


# Install and configure Babel - hybrid
pipenv run npm install --save-dev @babel/core babel-loader @babel/preset-env @babel/preset-react svg-inline-loader axios
sed -i '/"scripts":/a \ \ \  "start-development": "webpack --mode development --watch",' ./source/frontend/package.json
sed -i '/start-development/a \ \ \  "build-production": "react-scripts build && webpack --config webpack.config.js --mode production",' ./source/frontend/package.json
cp $SCRIPT_DIR/project/frontend/.babelrc.js ./source/frontend/


# Configure proxy
cp ./source/frontend/package.json package.json
rm ./source/frontend/package.json
jq '. += { "proxy": "http://localhost:8000" }' package.json > ./source/frontend/package.json
# rm package.json


# Change to the source directory
cd ../..


# Configure docker
cp $SCRIPT_DIR/project/Dockerfile ./source
cp $SCRIPT_DIR/project/frontend/Dockerfile ./source/core
cp $SCRIPT_DIR/project/docker-compose.yml ./source 


# Configure template folders
mkdir templates; mkdir ./core/templates


# Configure settings.py
sed -i "/'django.contrib.staticfiles',/a\ \ \ \ 'rest_framework'," ./source/config/settings.py
sed -i "/'rest_framework',/a\ \ \ \ 'corsheaders'," ./source/config/settings.py
sed -i "/'corsheaders',/a\ \ \ \ 'core'," ./source/config/settings.py
sed -i "/'django.middleware.clickjacking.XFrameOptionsMiddleware',/a\ \ \ \ 'corsheaders.middleware.CorsMiddleware'," ./source/config/settings.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\ \n \ \ \ 'http:\/\/localhost:3000\',\n\]/g" ./source/config/settings.py
sed -i '/STATIC_URL = '\''static\/'\''/a STATICFILES_DIRS = [ \n    "'core\/static'",\n    BASE_DIR + "'frontend\/static\/js'"\n]' ./source/config/settings.py


# Configure config/urls.py
sed -i -e "s/from django.urls import path/from django.urls import path, include/" ./source/config/urls.py
sed '/urlpatterns = \[/a \ \ \ \ ('', include("core.urls")),' -i ./source/config/urls.py


# Configure core/urls.py
touch ./source/core/urls.py
echo -e "from django.urls import path \n \n \nurlpatterns = [\n\n]" >> ./source/core/urls.py


# Configure CORS origin list
# CORS_ORIGIN_WHITELIST = [
#     'http://localhost:3000'
# ]


# Initialize a git repository, create .gitignore
git init

# Iterate through each line in the ./source/frontend/.gitignore
while read line; do
    # Check if the line starts with a dot
    if [[ ${line:0:1} == "." ]]; then
        # Remove the dot and append "./source/frontend/" in front
        echo -e "./source/frontend/${line:1}\n" >> .gitignore
	elif [[ ${line:0:1} == "." ]]; then
		echo -e "$line\n" >> .gitignore
	elif [[ ${line:0:1} == "" ]]; then
		echo -e "\n" >> .gitignore
    else
        # Append "./source/frontend/" in front
        echo -e "./source/frontend/$line\n" >> .gitignore
    fi
done < ./source/frontend/.gitignore

# rm ./source/frontend/.gitignore

echo "./source/frontend/node_modules" >> .gitignore  
echo "./source/db.sqlite3" >> .gitignore


# Make the initial commit
git add .
git commit -m "Initial commit with Django REST and React setup."

  
# Activate the environment
# cd ~/$project_directory/$project_name
pipenv shell