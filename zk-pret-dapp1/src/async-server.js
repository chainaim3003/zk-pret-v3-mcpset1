import dotenv from 'dotenv';
dotenv.config();
import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { logger } from './utils/logger.js';
import { zkPretClient } from './services/zkPretClient.js';

class AsyncJobManager {
  constructor(wss) {
    this.jobs = new Map();
    this.wss = wss;
    this.isAsyncEnabled = process.env.ENABLE_ASYNC_JOBS === 'true';
    logger.info(`Async job management ${this.isAsyncEnabled ? 'enabled' : 'disabled'}`);
  }

  async startJob(jobId, toolName, parameters) {
    const job = {
      id: jobId,
      toolName,
      parameters,
      status: 'pending',
      startTime: new Date()
    };

    this.jobs.set(jobId, job);
    this.broadcastJobUpdate(job);

    // Start processing in background
    this.processJob(job);

    return job;
  }

  async processJob(job) {
    try {
      job.status = 'running';
      this.broadcastJobUpdate(job);

      // Simulate progress updates
      const progressUpdates = [10, 25, 50, 75, 90];
      for (const progress of progressUpdates) {
        await new Promise(resolve => setTimeout(resolve, 2000));
        job.progress = progress;
        this.broadcastJobUpdate(job);
      }

      // Execute the actual tool
      const result = await zkPretClient.executeTool(job.toolName, job.parameters);
      
      job.status = 'completed';
      job.result = result;
      job.endTime = new Date();
      job.progress = 100;

    } catch (error) {
      job.status = 'failed';
      job.error = error instanceof Error ? error.message : 'Unknown error';
      job.endTime = new Date();
    }

    this.broadcastJobUpdate(job);
  }

  broadcastJobUpdate(job) {
    const message = JSON.stringify({
      type: 'job_update',
      jobId: job.id,
      status: job.status,
      progress: job.progress,
      result: job.result,
      error: job.error,
      timestamp: new Date().toISOString()
    });

    this.wss.clients.forEach(client => {
      if (client.readyState === 1) { // WebSocket.OPEN
        client.send(message);
      }
    });
  }

  getJob(jobId) {
    return this.jobs.get(jobId);
  }

  getAllJobs() {
    return Array.from(this.jobs.values());
  }

  getActiveJobs() {
    return Array.from(this.jobs.values()).filter(job => 
      job.status === 'pending' || job.status === 'running'
    );
  }

  clearCompletedJobs() {
    for (const [jobId, job] of this.jobs.entries()) {
      if (job.status === 'completed' || job.status === 'failed') {
        this.jobs.delete(jobId);
      }
    }
  }
}

const app = express();
const server = createServer(app);

// WebSocket server setup
const wss = new WebSocketServer({ server });
const jobManager = new AsyncJobManager(wss);

const ZK_PRET_WEB_APP_PORT = parseInt(process.env.ZK_PRET_WEB_APP_PORT || '3000', 10);
const ZK_PRET_WEB_APP_HOST = process.env.ZK_PRET_WEB_APP_HOST || 'localhost';

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// WebSocket connection handling
wss.on('connection', (ws) => {
  logger.info('New WebSocket connection established');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      logger.info('WebSocket message received:', data);
    } catch (error) {
      logger.error('Invalid WebSocket message:', error);
    }
  });

  ws.on('close', () => {
    logger.info('WebSocket connection closed');
  });

  // Send initial connection message
  ws.send(JSON.stringify({
    type: 'connection',
    status: 'connected',
    timestamp: new Date().toISOString()
  }));
});

// Health check endpoint
app.get('/api/v1/health', async (_req, res) => {
  const zkPretStatus = await zkPretClient.healthCheck();
  res.json({
    status: zkPretStatus.connected ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    services: { 
      zkPretServer: zkPretStatus.connected,
      asyncJobs: process.env.ENABLE_ASYNC_JOBS === 'true',
      websockets: wss.clients.size > 0
    },
    activeJobs: jobManager.getActiveJobs().length
  });
});

// Tools listing endpoint
app.get('/api/v1/tools', async (_req, res) => {
  try {
    const tools = await zkPretClient.listTools();
    res.json({ 
      tools, 
      timestamp: new Date().toISOString(),
      asyncEnabled: process.env.ENABLE_ASYNC_JOBS === 'true'
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to list tools' });
  }
});

// Traditional sync execution endpoint
app.post('/api/v1/tools/execute', async (req, res) => {
  try {
    const { toolName, parameters } = req.body;
    const result = await zkPretClient.executeTool(toolName, parameters);
    res.json({
      ...result,
      timestamp: new Date().toISOString(),
      mode: 'sync'
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Execution failed',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Async job management endpoints
app.post('/api/v1/jobs/start', async (req, res) => {
  if (process.env.ENABLE_ASYNC_JOBS !== 'true') {
    return res.status(400).json({ 
      error: 'Async jobs are disabled',
      message: 'Set ENABLE_ASYNC_JOBS=true to use async execution'
    });
  }

  try {
    const { jobId, toolName, parameters } = req.body;
    const actualJobId = jobId || uuidv4();
    
    const job = await jobManager.startJob(actualJobId, toolName, parameters);
    
    res.json({
      jobId: job.id,
      status: job.status,
      timestamp: job.startTime.toISOString(),
      message: 'Job started successfully'
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to start job',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

app.get('/api/v1/jobs/:jobId', (req, res) => {
  const job = jobManager.getJob(req.params.jobId);
  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }
  res.json(job);
});

app.get('/api/v1/jobs', (_req, res) => {
  const jobs = jobManager.getAllJobs();
  res.json({
    jobs,
    total: jobs.length,
    active: jobManager.getActiveJobs().length,
    timestamp: new Date().toISOString()
  });
});

app.delete('/api/v1/jobs/completed', (_req, res) => {
  jobManager.clearCompletedJobs();
  res.json({ 
    message: 'Completed jobs cleared',
    timestamp: new Date().toISOString()
  });
});

// Enhanced status endpoint with job information
app.get('/api/v1/status', (_req, res) => {
  res.json({
    server: 'ZK-PRET-WEB-APP',
    version: '1.0.0',
    mode: process.env.NODE_ENV || 'development',
    asyncEnabled: process.env.ENABLE_ASYNC_JOBS === 'true',
    websocketConnections: wss.clients.size,
    activeJobs: jobManager.getActiveJobs().length,
    totalJobs: jobManager.getAllJobs().length,
    features: {
      async_jobs: process.env.ENABLE_ASYNC_JOBS === 'true',
      websockets: process.env.ENABLE_WEBSOCKETS === 'true',
      job_persistence: process.env.ENABLE_JOB_PERSISTENCE === 'true',
      browser_notifications: process.env.ENABLE_BROWSER_NOTIFICATIONS === 'true',
      job_recovery: process.env.ENABLE_JOB_RECOVERY === 'true',
      enhanced_ui: process.env.ENABLE_ENHANCED_UI === 'true',
      polling_fallback: process.env.ENABLE_POLLING_FALLBACK === 'true'
    },
    timestamp: new Date().toISOString()
  });
});

const startServer = async () => {
  await zkPretClient.initialize();
  
  server.listen(ZK_PRET_WEB_APP_PORT, ZK_PRET_WEB_APP_HOST, () => {
    logger.info(`🚀 ZK-PRET-WEB-APP (ASYNC) started on http://${ZK_PRET_WEB_APP_HOST}:${ZK_PRET_WEB_APP_PORT}`);
    logger.info(`🔗 WebSocket server running on ws://${ZK_PRET_WEB_APP_HOST}:${ZK_PRET_WEB_APP_PORT}`);
    logger.info(`⚡ Async features: ${process.env.ENABLE_ASYNC_JOBS === 'true' ? 'ENABLED' : 'DISABLED'}`);
    logger.info(`🎯 Job queue ready for background processing`);
  });
};

startServer();
