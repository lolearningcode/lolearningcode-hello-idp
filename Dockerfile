# Simple Node.js application Dockerfile for demonstration
# This is a basic example to test the deployment pipeline

FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Create a simple package.json for demo app
COPY package.json* ./

# If no package.json exists, create a basic one
RUN if [ ! -f package.json ]; then \
    echo '{"name": "demo-app", "version": "1.0.0", "scripts": {"start": "node index.js"}, "dependencies": {"express": "^4.18.0"}}' > package.json; \
    fi

# Install dependencies
RUN npm install

# Create a simple Express server if index.js doesn't exist
RUN if [ ! -f index.js ]; then \
    echo 'const express = require("express"); const app = express(); const port = process.env.PORT || 3000; app.get("/", (req, res) => res.json({message: "Hello from Backstage Demo!", timestamp: new Date().toISOString()})); app.get("/health", (req, res) => res.json({status: "healthy"})); app.listen(port, "0.0.0.0", () => console.log(`Server running on port ${port}`));' > index.js; \
    fi

# Copy application files (if any exist)
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["npm", "start"]