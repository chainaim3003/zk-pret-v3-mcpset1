import dotenv from 'dotenv';
dotenv.config(); // This line should be very early
import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { logger } from './utils/logger.js';
import { zkPretClient } from './services/zkPretClient.js';

dotenv.config();

const app = express();
const server = createServer(app);

const ZK_PRET_WEB_APP_PORT = parseInt(process.env.ZK_PRET_WEB_APP_PORT || '3000', 10);
const ZK_PRET_WEB_APP_HOST = process.env.ZK_PRET_WEB_APP_HOST || 'localhost';

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

app.get('/api/v1/health', async (_req, res) => {
  const zkPretStatus = await zkPretClient.healthCheck();
  res.json({
    status: zkPretStatus.connected ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    services: { zkPretServer: zkPretStatus.connected }
  });
});

app.get('/api/v1/tools', async (_req, res) => {
  try {
    const tools = await zkPretClient.listTools();
    res.json({ tools, timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ error: 'Failed to list tools' });
  }
});

app.post('/api/v1/tools/execute', async (req, res) => {
  try {
    const { toolName, parameters } = req.body;
    const result = await zkPretClient.executeTool(toolName, parameters);
    res.json({
      ...result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: 'Execution failed' });
  }
});

const startServer = async () => {
  await zkPretClient.initialize();
  server.listen(ZK_PRET_WEB_APP_PORT, ZK_PRET_WEB_APP_HOST, () => {
    logger.info(`ZK-PRET-WEB-APP started on http://${ZK_PRET_WEB_APP_HOST}:${ZK_PRET_WEB_APP_PORT}`);
  });
};

startServer();
