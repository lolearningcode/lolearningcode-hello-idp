const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.get('/', (req, res) => {
    res.json({
        message: 'Hello from Backstage Demo Service!',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        version: '1.0.0'
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/api/info', (req, res) => {
    res.json({
        service: 'backstage-demo',
        description: 'Demonstration service for Backstage platform engineering',
        features: [
            'ECS Fargate deployment',
            'Application Load Balancer',
            'CloudWatch logging',
            'Terraform infrastructure',
            'GitHub Actions CI/CD'
        ]
    });
});

// Start server
app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 Demo service running on port ${port}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});