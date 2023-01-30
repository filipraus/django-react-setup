# Use an official Node.js runtime as the base image
FROM node:14

# Set the working directory
WORKDIR /frontend

# Copy the package.json and package-lock.json
COPY package*.json ./

# Install the dependencies
RUN npm install

# Copy the rest of the files
COPY . .

# Expose the port
EXPOSE 3000

# Run the command to start the server
CMD ["npm", "start"]