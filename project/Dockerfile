# Use an official Python runtime as the base image
FROM python:3.11

ENV PYTHONUNBUFFERED=1

# Copy the Pipfile and Pipfile.lock
COPY Pipfile* ./

# Install dependencies
RUN pip install pipenv && pipenv install --system

# Set the working directory
WORKDIR .

# Copy the rest of the application code
COPY . .

# Expose the port
EXPOSE 8000

# Run the command to start the server
CMD ["python", "manage.py", "runserver"]