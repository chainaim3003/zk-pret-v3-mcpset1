#!/bin/bash

# ZK-PRET-WEB-APP Complete Setup Script
echo "🚀 Setting up ZK-PRET-WEB-APP..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Node.js is installed
check_node() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js $NODE_VERSION is installed"
        
        # Check if version is >= 18
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | cut -d'v' -f2)
        if [ "$NODE_MAJOR" -lt 18 ]; then
            print_error "Node.js version 18 or higher is required. Current version: $NODE_VERSION"
            exit 1
        fi
    else
        print_error "Node.js is not installed. Please install Node.js 18 or higher."
        exit 1
    fi
}

# Check if npm is installed
check_npm() {
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "npm $NPM_VERSION is installed"
    else
        print_error "npm is not installed. Please install npm."
        exit 1
    fi
}

# Create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    mkdir -p src/{services,utils,types}
    mkdir -p public/{css,js/{components,utils}}
    mkdir -p dist
    mkdir -p logs
    
    print_success "Directory structure created"
}

# Create package.json file
create_package_json() {
    print_status "Creating package.json..."
    
    cat > package.json << 'EOF'
{
  "name": "zk-pret-web-app",
  "version": "1.0.0",
  "description": "Web application interface for ZK-PRET-SERVER (Zero-Knowledge Proofs for Regulatory and Enterprise Technology)",
  "main": "dist/server.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "tsx watch src/server.ts",
    "setup": "chmod +x setup.sh && ./setup.sh",
    "clean": "rm -rf dist",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "zero-knowledge",
    "blockchain",
    "proofs",
    "regulatory",
    "enterprise",
    "verification"
  ],
  "author": "ZK-PRET Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "ws": "^8.14.2",
    "axios": "^1.6.2",
    "dotenv": "^16.3.1",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/cors": "^2.8.17",
    "@types/ws": "^8.5.10",
    "@types/node": "^20.10.4",
    "typescript": "^5.3.3",
    "tsx": "^4.6.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
    
    print_success "package.json created"
}

# Create .env file
create_env_file() {
    print_status "Creating .env file..."
    
    cat > .env << 'EOF'
# ZK-PRET-WEB-APP Configuration

# ZK-PRET-WEB-APP Server Settings
ZK_PRET_WEB_APP_PORT=3000
ZK_PRET_WEB_APP_HOST=localhost
NODE_ENV=development

# ZK-PRET-SERVER Connection
# Option 1: HTTP Server Mode (traditional API server)
ZK_PRET_SERVER_URL=http://localhost:3001
# Option 2: STDIO Mode (direct script execution)
# ZK_PRET_SERVER_URL=stdio://local
# Option 3: Deployed server
# ZK_PRET_SERVER_URL=https://your-zk-pret-server.vercel.app

# ZK-PRET-SERVER Configuration
ZK_PRET_SERVER_TYPE=http
# Options: http, stdio, vercel, custom
ZK_PRET_SERVER_TIMEOUT=120000
# Timeout in milliseconds (2 minutes)

# STDIO Mode Configuration (when ZK_PRET_SERVER_TYPE=stdio)
ZK_PRET_STDIO_PATH=../ZK-PRET-TEST-V3
# Path to ZK-PRET installation directory
ZK_PRET_STDIO_BUILD_PATH=./build/tests/with-sign
# Relative path to build directory with test files

# ACTUS Server URL (for risk/liquidity verification)
ACTUS_SERVER_URL=http://98.84.165.146:8083/eventsBatch

# Security Settings
RATE_LIMIT_WINDOW_MS=900000
# 15 minutes
RATE_LIMIT_MAX=100
# Max requests per window

# CORS Settings
CORS_ORIGIN=http://localhost:3000
# Add your production domain here

# Logging
LOG_LEVEL=info
# Options: error, warn, info, debug

# WebSocket Settings
WS_HEARTBEAT_INTERVAL=30000
# 30 seconds

# API Settings
API_PREFIX=/api/v1
MAX_REQUEST_SIZE=10mb

# Development Settings (only for development)
DEV_AUTO_RELOAD=true
DEV_SHOW_STACK_TRACES=true
EOF
    
    print_success ".env file created"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if npm install; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Create TypeScript configuration
create_tsconfig() {
    if [ ! -f "tsconfig.json" ]; then
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "public"
  ]
}
EOF
        print_success "TypeScript configuration created"
    else
        print_warning "tsconfig.json already exists"
    fi
}

# Create server-side files
create_server_files() {
    # Create types file
    cat > src/types/index.ts << 'EOF'
// ZK-PRET-WEB-APP Type Definitions

export interface ToolExecutionRequest {
  toolName: string;
  parameters?: any;
}

export interface ToolExecutionResponse {
  success: boolean;
  toolName: string;
  parameters?: any;
  result: ToolResult;
  executionTime: string;
  timestamp: string;
  meta?: {
    webAppVersion: string;
    zkPretServerUrl: string;
    executedAt: string;
  };
}

export interface ToolResult {
  status: 'completed' | 'failed' | 'pending';
  zkProofGenerated: boolean;
  timestamp: string;
  output?: string;
  stderr?: string;
  exitCode?: number;
  error?: string;
  details?: any;
}

export interface ToolExecutionResult {
  success: boolean;
  result: ToolResult;
  executionTime: string;
  serverResponse?: any;
}

export interface ZKPretServerResponse {
  success: boolean;
  toolName: string;
  parameters?: any;
  result?: ToolResult;
  executionTime?: string;
  timestamp?: string;
  meta?: any;
  message?: string;
  error?: string;
}

export interface ServerStatus {
  connected: boolean;
  status: string;
  timestamp: string;
  version?: string;
  services?: Record<string, boolean>;
  serverUrl: string;
  serverType: string;
  error?: string;
}

export interface ZKPretClientConfig {
  serverUrl: string;
  timeout: number;
  retries: number;
  serverType: 'http' | 'stdio' | 'vercel' | 'custom';
  stdioPath?: string;
  stdioBuildPath?: string;
}
EOF

    # Create logger utility
    cat > src/utils/logger.ts << 'EOF'
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.colorize(),
    winston.format.simple()
  ),
  transports: [
    new winston.transports.Console(),
  ],
});

export { logger };
EOF

    # Create ZK-PRET client with STDIO support
    cat > src/services/zkPretClient.ts << 'EOF'
import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { spawn } from 'child_process';
import path from 'path';
import { logger } from '../utils/logger.js';
import type { ZKPretServerResponse, ToolExecutionResult, ServerStatus, ZKPretClientConfig } from '../types/index.js';

class ZKPretClient {
  private client?: AxiosInstance;
  private config: ZKPretClientConfig;
  private initialized: boolean = false;

  constructor() {
    this.config = {
      serverUrl: process.env.ZK_PRET_SERVER_URL || 'http://localhost:3001',
      timeout: parseInt(process.env.ZK_PRET_SERVER_TIMEOUT || '120000'),
      retries: 3,
      serverType: (process.env.ZK_PRET_SERVER_TYPE as any) || 'http',
      stdioPath: process.env.ZK_PRET_STDIO_PATH || '../ZK-PRET-TEST-V3',
      stdioBuildPath: process.env.ZK_PRET_STDIO_BUILD_PATH || './build/tests/with-sign'
    };

    if (this.config.serverType !== 'stdio') {
      this.client = axios.create({
        baseURL: this.config.serverUrl,
        timeout: this.config.timeout,
        headers: { 'Content-Type': 'application/json', 'User-Agent': 'ZK-PRET-WEB-APP/1.0.0' }
      });
    }
  }

  async initialize(): Promise<void> {
    try {
      await this.healthCheck();
      this.initialized = true;
      logger.info(`ZK-PRET-SERVER client initialized (${this.config.serverType} mode)`);
    } catch (error) {
      logger.warn('ZK-PRET-SERVER client initialization failed');
    }
  }

  async healthCheck(): Promise<{ connected: boolean; status?: any }> {
    try {
      if (this.config.serverType === 'stdio') {
        return await this.stdioHealthCheck();
      }
      
      const response = await this.client!.get('/api/health');
      return { connected: true, status: response.data };
    } catch (error) {
      return { connected: false };
    }
  }

  async stdioHealthCheck(): Promise<{ connected: boolean; status?: any }> {
    try {
      const fs = await import('fs/promises');
      await fs.access(this.config.stdioPath!);
      const buildPath = path.join(this.config.stdioPath!, this.config.stdioBuildPath!);
      await fs.access(buildPath);
      
      return {
        connected: true,
        status: { mode: 'stdio', path: this.config.stdioPath, buildPath }
      };
    } catch (error) {
      return { connected: false };
    }
  }

  async listTools(): Promise<string[]> {
    try {
      if (this.config.serverType === 'stdio') {
        return this.getStdioTools();
      }
      
      const response = await this.client!.get('/api/tools');
      return response.data.tools || [];
    } catch (error) {
      return this.getStdioTools();
    }
  }

  getStdioTools(): string[] {
    return [
      'get-GLEIF-verification-with-sign',
      'get-Corporate-Registration-verification-with-sign',
      'get-EXIM-verification-with-sign',
      'get-BSDI-compliance-verification',
      'get-BPI-compliance-verification',
      'get-RiskLiquidityACTUS-Verifier-Test_adv_zk',
      'get-RiskLiquidityACTUS-Verifier-Test_Basel3_Withsign'
    ];
  }

  async executeTool(toolName: string, parameters: any = {}): Promise<ToolExecutionResult> {
    const startTime = Date.now();
    
    try {
      let result;
      
      if (this.config.serverType === 'stdio') {
        result = await this.executeStdioTool(toolName, parameters);
      } else {
        const response = await this.client!.post('/api/tools/execute', { toolName, parameters });
        result = response.data;
      }

      const executionTime = Date.now() - startTime;
      
      return {
        success: result.success,
        result: result.result || {
          status: result.success ? 'completed' : 'failed',
          zkProofGenerated: result.success,
          timestamp: new Date().toISOString(),
          output: result.output || ''
        },
        executionTime: `${executionTime}ms`
      };
    } catch (error) {
      const executionTime = Date.now() - startTime;
      return {
        success: false,
        result: {
          status: 'failed',
          zkProofGenerated: false,
          timestamp: new Date().toISOString(),
          error: error instanceof Error ? error.message : 'Unknown error'
        },
        executionTime: `${executionTime}ms`
      };
    }
  }

  async executeStdioTool(toolName: string, parameters: any = {}): Promise<any> {
    const toolScriptMap: Record<string, string> = {
      'get-GLEIF-verification-with-sign': 'GLEIFVerificationTestWithSign.js',
      'get-Corporate-Registration-verification-with-sign': 'CorporateRegistrationVerificationTestWithSign.js',
      'get-EXIM-verification-with-sign': 'EXIMVerificationTestWithSign.js',
      'get-BSDI-compliance-verification': 'BusinessStandardDataIntegrityVerificationTest.js',
      'get-BPI-compliance-verification': 'BusinessProcessIntegrityVerificationFileTestWithSign.js',
      'get-RiskLiquidityACTUS-Verifier-Test_adv_zk': 'RiskLiquidityACTUSVerifierTest_adv_zk_WithSign.js',
      'get-RiskLiquidityACTUS-Verifier-Test_Basel3_Withsign': 'RiskLiquidityACTUSVerifierTest_basel3_Withsign.js'
    };

    const scriptFile = toolScriptMap[toolName];
    if (!scriptFile) {
      throw new Error(`Unknown tool: ${toolName}`);
    }

    const scriptPath = path.join(this.config.stdioPath!, this.config.stdioBuildPath!, scriptFile);
    return await this.executeNodeScript(scriptPath, parameters);
  }

  async executeNodeScript(scriptPath: string, parameters: any = {}): Promise<any> {
    return new Promise((resolve, reject) => {
      const args = this.prepareScriptArgs(parameters);
      const childProcess = spawn('node', [scriptPath, ...args], {
        cwd: this.config.stdioPath,
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { ...process.env }
      });

      let stdout = '';
      let stderr = '';
      let isResolved = false;

      const timeoutId = setTimeout(() => {
        if (!isResolved) {
          isResolved = true;
          childProcess.kill('SIGTERM');
          reject(new Error(`Script execution timeout after ${this.config.timeout}ms`));
        }
      }, this.config.timeout);

      childProcess.stdout.on('data', (data: Buffer) => {
        stdout += data.toString();
      });

      childProcess.stderr.on('data', (data: Buffer) => {
        stderr += data.toString();
      });

      childProcess.on('close', (code: number | null) => {
        if (!isResolved) {
          isResolved = true;
          clearTimeout(timeoutId);
          
          if (code === 0) {
            resolve({
              success: true,
              result: {
                status: 'completed',
                zkProofGenerated: true,
                timestamp: new Date().toISOString(),
                output: stdout,
                stderr: stderr
              }
            });
          } else {
            reject(new Error(`Script failed with exit code ${code}: ${stderr || stdout}`));
          }
        }
      });

      childProcess.on('error', (error: Error) => {
        if (!isResolved) {
          isResolved = true;
          clearTimeout(timeoutId);
          reject(error);
        }
      });
    });
  }

  prepareScriptArgs(parameters: any): string[] {
    const args: string[] = [];
    Object.keys(parameters).forEach(key => {
      const value = parameters[key];
      if (value !== null && value !== undefined && value !== '') {
        args.push(`--${key}`, String(value));
      }
    });
    return args;
  }

  getServerUrl(): string {
    return this.config.serverType === 'stdio' ? `stdio://${this.config.stdioPath}` : this.config.serverUrl;
  }

  async getServerStatus(): Promise<ServerStatus> {
    try {
      if (this.config.serverType === 'stdio') {
        const healthCheck = await this.stdioHealthCheck();
        return {
          connected: healthCheck.connected,
          status: healthCheck.connected ? 'healthy' : 'disconnected',
          timestamp: new Date().toISOString(),
          serverUrl: this.getServerUrl(),
          serverType: 'stdio'
        };
      }
      
      const response = await this.client!.get('/api/health');
      return {
        connected: true,
        status: response.data.status || 'unknown',
        timestamp: response.data.timestamp,
        serverUrl: this.config.serverUrl,
        serverType: this.config.serverType
      };
    } catch (error) {
      return {
        connected: false,
        status: 'disconnected',
        timestamp: new Date().toISOString(),
        serverUrl: this.getServerUrl(),
        serverType: this.config.serverType,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}

export const zkPretClient = new ZKPretClient();
EOF

    # Create main server file
    cat > src/server.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import dotenv from 'dotenv';
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
EOF
}

# Create frontend files
create_frontend_files() {
    # Create main HTML file
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZK-PRET-WEB-APP</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/styles.css">
</head>
<body class="bg-gray-50 min-h-screen">
    <header class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 py-4">
            <div class="flex justify-between items-center">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                        <i class="fas fa-shield-alt text-white text-xl"></i>
                    </div>
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900">ZK-PRET-WEB-APP</h1>
                        <p class="text-sm text-gray-500">Zero-Knowledge Proofs for Regulatory Technology</p>
                    </div>
                </div>
                <div class="flex items-center space-x-4">
                    <div id="connection-status" class="flex items-center space-x-2">
                        <div class="w-3 h-3 bg-gray-400 rounded-full animate-pulse"></div>
                        <span class="text-sm text-gray-600">Connecting...</span>
                    </div>
                    <button id="settings-btn" class="p-2 rounded-lg hover:bg-gray-100">
                        <i class="fas fa-cog text-gray-600"></i>
                    </button>
                </div>
            </div>
        </div>
    </header>

    <main class="max-w-7xl mx-auto px-4 py-8">
        <div id="notifications" class="fixed top-4 right-4 z-50"></div>
        
        <div class="mb-8">
            <nav class="flex space-x-1 bg-white rounded-lg p-1 shadow-sm">
                <button class="tab-btn active flex-1 px-6 py-3 text-sm font-medium rounded-md" data-tab="gleif">
                    <i class="fas fa-building mr-2"></i>GLEIF Verification
                </button>
                <button class="tab-btn flex-1 px-6 py-3 text-sm font-medium rounded-md" data-tab="corporate">
                    <i class="fas fa-certificate mr-2"></i>Corporate Registration
                </button>
                <button class="tab-btn flex-1 px-6 py-3 text-sm font-medium rounded-md" data-tab="exim">
                    <i class="fas fa-ship mr-2"></i>EXIM Verification
                </button>
                <button class="tab-btn flex-1 px-6 py-3 text-sm font-medium rounded-md" data-tab="compliance">
                    <i class="fas fa-check-circle mr-2"></i>Business Compliance
                </button>
                <button class="tab-btn flex-1 px-6 py-3 text-sm font-medium rounded-md" data-tab="risk">
                    <i class="fas fa-chart-line mr-2"></i>Risk & Liquidity
                </button>
            </nav>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div class="lg:col-span-2">
                <div class="bg-white rounded-lg shadow-sm border">
                    <div id="gleif-tab" class="tab-content active p-6">
                        <h3 class="text-lg font-semibold mb-4 flex items-center">
                            <i class="fas fa-building mr-2 text-blue-600"></i>
                            GLEIF Entity Verification
                        </h3>
                        <div id="gleif-content">Loading...</div>
                    </div>
                    
                    <div id="corporate-tab" class="tab-content hidden p-6">
                        <h3 class="text-lg font-semibold mb-4 flex items-center">
                            <i class="fas fa-certificate mr-2 text-blue-600"></i>
                            Corporate Registration Verification
                        </h3>
                        <div id="corporate-content">Loading...</div>
                    </div>

                    <div id="exim-tab" class="tab-content hidden p-6">
                        <h3 class="text-lg font-semibold mb-4 flex items-center">
                            <i class="fas fa-ship mr-2 text-blue-600"></i>
                            Export/Import Verification
                        </h3>
                        <div id="exim-content">Loading...</div>
                    </div>

                    <div id="compliance-tab" class="tab-content hidden p-6">
                        <h3 class="text-lg font-semibold mb-4 flex items-center">
                            <i class="fas fa-check-circle mr-2 text-blue-600"></i>
                            Business Compliance Verification
                        </h3>
                        <div id="compliance-content">Loading...</div>
                    </div>

                    <div id="risk-tab" class="tab-content hidden p-6">
                        <h3 class="text-lg font-semibold mb-4 flex items-center">
                            <i class="fas fa-chart-line mr-2 text-blue-600"></i>
                            Risk & Liquidity Assessment
                        </h3>
                        <div id="risk-content">Loading...</div>
                    </div>
                </div>
            </div>

            <div class="lg:col-span-1">
                <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
                    <h3 class="text-lg font-semibold mb-4 flex items-center">
                        <i class="fas fa-server mr-2 text-green-600"></i>
                        Server Status
                    </h3>
                    <div id="server-status">Loading...</div>
                </div>

                <div class="bg-white rounded-lg shadow-sm border p-6 mb-6">
                    <h3 class="text-lg font-semibold mb-4 flex items-center">
                        <i class="fas fa-clipboard-list mr-2 text-purple-600"></i>
                        Execution Results
                    </h3>
                    <div id="execution-results">
                        <div class="text-center py-8 text-gray-500">
                            <i class="fas fa-play-circle text-4xl mb-4 opacity-50"></i>
                            <p>No executions yet</p>
                            <p class="text-sm">Select a verification tool and click execute</p>
                        </div>
                    </div>
                </div>

                <div class="bg-white rounded-lg shadow-sm border p-6">
                    <h3 class="text-lg font-semibold mb-4 flex items-center">
                        <i class="fas fa-history mr-2 text-orange-600"></i>
                        Recent History
                    </h3>
                    <div id="execution-history">
                        <div class="text-center py-4 text-gray-500">
                            <p class="text-sm">No history available</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <!-- Settings modal -->
    <div id="settings-modal" class="fixed inset-0 bg-black bg-opacity-50 hidden z-50">
        <div class="flex items-center justify-center min-h-screen p-4">
            <div class="bg-white rounded-lg shadow-lg max-w-md w-full">
                <div class="p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="text-lg font-semibold text-gray-900">Settings</h3>
                        <button id="close-settings" class="text-gray-400 hover:text-gray-600">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div class="space-y-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">ZK-PRET-SERVER URL</label>
                            <input type="text" id="server-url" class="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="http://localhost:3001">
                        </div>
                        
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">Server Type</label>
                            <select id="server-type" class="w-full px-3 py-2 border border-gray-300 rounded-md">
                                <option value="http">HTTP Server (API Mode)</option>
                                <option value="stdio">STDIO Mode (Direct Script Execution)</option>
                                <option value="vercel">Vercel Deployed ZK-PRET-SERVER</option>
                                <option value="custom">Custom ZK-PRET-SERVER Endpoint</option>
                            </select>
                        </div>
                        
                        <div id="stdio-config" class="hidden">
                            <label class="block text-sm font-medium text-gray-700 mb-2">ZK-PRET Installation Path</label>
                            <input type="text" id="stdio-path" class="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="../ZK-PRET-TEST-V3">
                            <div class="text-xs text-gray-500 mt-1">Path to your local ZK-PRET installation directory</div>
                        </div>
                        
                        <div>
                            <label class="flex items-center">
                                <input type="checkbox" id="enable-realtime" class="rounded border-gray-300">
                                <span class="ml-2 text-sm text-gray-700">Enable real-time updates</span>
                            </label>
                        </div>
                    </div>
                    
                    <div class="mt-6 flex justify-end space-x-3">
                        <button id="cancel-settings" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200">
                            Cancel
                        </button>
                        <button id="save-settings" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
                            Save Settings
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="js/utils/api.js"></script>
    <script src="js/components/gleif.js"></script>
    <script src="js/components/corporate.js"></script>
    <script src="js/components/exim.js"></script>
    <script src="js/components/compliance.js"></script>
    <script src="js/components/risk.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
EOF

    # Create CSS
    cat > public/css/styles.css << 'EOF'
/* ZK-PRET-WEB-APP Styles */
:root {
  --primary-color: #3b82f6;
  --secondary-color: #06b6d4;
  --success-color: #22c55e;
  --warning-color: #f59e0b;
  --error-color: #ef4444;
}

.tab-btn {
    background: transparent;
    color: #6b7280;
    transition: all 0.2s;
    border: none;
    outline: none;
}

.tab-btn.active {
    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
    color: white;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.tab-btn:not(.active):hover {
    background: #f3f4f6;
    color: var(--primary-color);
}

.tab-content.hidden {
    display: none;
}

.notification {
    padding: 1rem;
    border-radius: 0.5rem;
    margin-bottom: 0.5rem;
    max-width: 400px;
    animation: slideInRight 0.3s ease-out;
}

.notification-success {
    background: #f0fdf4;
    border-left: 4px solid var(--success-color);
    color: #166534;
}

.notification-error {
    background: #fef2f2;
    border-left: 4px solid var(--error-color);
    color: #991b1b;
}

.notification-warning {
    background: #fffbeb;
    border-left: 4px solid var(--warning-color);
    color: #92400e;
}

.notification-info {
    background: #eff6ff;
    border-left: 4px solid var(--primary-color);
    color: #1e40af;
}

@keyframes slideInRight {
    0% { transform: translateX(100%); opacity: 0; }
    100% { transform: translateX(0); opacity: 1; }
}

.form-input, .form-select {
    width: 100%;
    padding: 0.75rem 1rem;
    border: 2px solid #e5e7eb;
    border-radius: 0.5rem;
    transition: all 0.2s;
}

.form-input:focus, .form-select:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.75rem 1.5rem;
    font-size: 0.875rem;
    font-weight: 600;
    border-radius: 0.5rem;
    transition: all 0.2s;
    cursor: pointer;
    border: none;
    outline: none;
}

.btn-primary {
    background: linear-gradient(135deg, var(--primary-color), #1d4ed8);
    color: white;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.btn-primary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(59, 130, 246, 0.4);
}

.btn:disabled {
    cursor: not-allowed;
    opacity: 0.6;
}

.tool-card {
    transition: all 0.2s;
    cursor: pointer;
}

.tool-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.status-indicator {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
}

.status-connected {
    background: #dcfce7;
    color: #166534;
}

.status-disconnected {
    background: #fef2f2;
    color: #991b1b;
}

.status-degraded {
    background: #fef3c7;
    color: #92400e;
}

.result-card {
    border: 2px solid #e5e7eb;
    border-radius: 0.75rem;
    padding: 1.5rem;
    margin-bottom: 1rem;
    transition: all 0.3s;
}

.result-card.success {
    border-color: var(--success-color);
    background: linear-gradient(135deg, #f0fdf4, #ffffff);
}

.result-card.error {
    border-color: var(--error-color);
    background: linear-gradient(135deg, #fef2f2, #ffffff);
}

.code-output {
    background: #1f2937;
    color: #f9fafb;
    padding: 1rem;
    border-radius: 0.5rem;
    font-family: Monaco, monospace;
    font-size: 0.75rem;
    line-height: 1.5;
    white-space: pre-wrap;
    word-break: break-all;
    max-height: 300px;
    overflow-y: auto;
}

@media (max-width: 768px) {
    .tab-btn {
        padding: 0.75rem 0.5rem;
        font-size: 0.75rem;
    }
    
    .tab-btn i {
        display: none;
    }
}
EOF

    # Create API utilities
    cat > public/js/utils/api.js << 'EOF'
class ZKPretAPI {
    constructor() {
        this.baseURL = '/api/v1';
    }

    async request(endpoint, options = {}) {
        const config = {
            method: options.method || 'GET',
            headers: { 'Content-Type': 'application/json' }
        };

        if (options.body) {
            config.body = JSON.stringify(options.body);
        }

        const response = await fetch(`${this.baseURL}${endpoint}`, config);
        return await response.json();
    }

    async healthCheck() {
        return await this.request('/health');
    }

    async listTools() {
        return await this.request('/tools');
    }

    async executeTool(toolName, parameters = {}) {
        return await this.request('/tools/execute', {
            method: 'POST',
            body: { toolName, parameters }
        });
    }
}

class NotificationManager {
    constructor() {
        this.container = document.getElementById('notifications');
    }

    show(type, title, message) {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="flex justify-between items-start">
                <div>
                    <h4 class="font-semibold">${title}</h4>
                    <p class="text-sm mt-1">${message}</p>
                </div>
                <button onclick="this.parentElement.parentElement.remove()" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;

        this.container.appendChild(notification);
        setTimeout(() => notification.remove(), 5000);
    }

    success(title, message) { this.show('success', title, message); }
    error(title, message) { this.show('error', title, message); }
    warning(title, message) { this.show('warning', title, message); }
    info(title, message) { this.show('info', title, message); }
}

window.zkpretAPI = new ZKPretAPI();
window.notifications = new NotificationManager();
EOF

    # Create component files
    create_component_files
}

create_component_files() {
    # GLEIF Component
    cat > public/js/components/gleif.js << 'EOF'
class GLEIFComponent {
    constructor() {
        this.render();
        this.setupEventListeners();
    }

    render() {
        const container = document.getElementById('gleif-content');
        container.innerHTML = `
            <form id="gleif-form" class="space-y-4">
                <div>
                    <label class="block text-sm font-medium mb-2">Legal Entity Identifier (LEI)</label>
                    <input type="text" name="entityId" class="form-input" placeholder="Enter 20-character LEI code">
                    <div class="text-xs text-gray-500 mt-1">The unique 20-character alphanumeric code assigned to the legal entity</div>
                </div>
                <div>
                    <label class="block text-sm font-medium mb-2">Legal Entity Name</label>
                    <input type="text" name="legalName" class="form-input" placeholder="Enter the legal name of the entity">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-2">Jurisdiction</label>
                    <select name="jurisdiction" class="form-select">
                        <option value="">Select jurisdiction (optional)</option>
                        <option value="US">United States</option>
                        <option value="GB">United Kingdom</option>
                        <option value="DE">Germany</option>
                        <option value="FR">France</option>
                        <option value="JP">Japan</option>
                        <option value="CA">Canada</option>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary w-full">
                    <i class="fas fa-play mr-2"></i>Generate GLEIF ZK Proof
                </button>
            </form>
        `;
    }

    setupEventListeners() {
        document.getElementById('gleif-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const parameters = Object.fromEntries(formData.entries());
            
            // Remove empty values
            Object.keys(parameters).forEach(key => {
                if (!parameters[key]) delete parameters[key];
            });

            await window.app.executeTool('get-GLEIF-verification-with-sign', parameters);
        });
    }
}

window.GLEIFComponent = GLEIFComponent;
EOF

    # Corporate Component
    cat > public/js/components/corporate.js << 'EOF'
class CorporateComponent {
    constructor() {
        this.render();
        this.setupEventListeners();
    }

    render() {
        const container = document.getElementById('corporate-content');
        container.innerHTML = `
            <form id="corporate-form" class="space-y-4">
                <div>
                    <label class="block text-sm font-medium mb-2">Company Name</label>
                    <input type="text" name="companyName" class="form-input" placeholder="Enter the legal company name" required>
                </div>
                <div>
                    <label class="block text-sm font-medium mb-2">Registration Number</label>
                    <input type="text" name="registrationNumber" class="form-input" placeholder="Enter company registration number">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-2">Jurisdiction</label>
                    <select name="jurisdiction" class="form-select" required>
                        <option value="">Select jurisdiction</option>
                        <option value="US-DE">Delaware, USA</option>
                        <option value="US-NY">New York, USA</option>
                        <option value="US-CA">California, USA</option>
                        <option value="GB">United Kingdom</option>
                        <option value="DE">Germany</option>
                        <option value="SG">Singapore</option>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary w-full">
                    <i class="fas fa-play mr-2"></i>Generate Corporate ZK Proof
                </button>
            </form>
        `;
    }

    setupEventListeners() {
        document.getElementById('corporate-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const parameters = Object.fromEntries(formData.entries());
            
            Object.keys(parameters).forEach(key => {
                if (!parameters[key]) delete parameters[key];
            });

            await window.app.executeTool('get-Corporate-Registration-verification-with-sign', parameters);
        });
    }
}

window.CorporateComponent = CorporateComponent;
EOF

    # Create remaining component files with basic content
    for component in exim compliance risk; do
        cat > "public/js/components/${component}.js" << EOF
class ${component^}Component {
    constructor() {
        this.render();
    }

    render() {
        const container = document.getElementById('${component}-content');
        container.innerHTML = \`
            <div class="text-center py-8 text-gray-500">
                <i class="fas fa-cog text-4xl mb-4 opacity-50"></i>
                <p>${component^} verification component</p>
                <p class="text-sm">Implementation coming soon...</p>
            </div>
        \`;
    }
}

window.${component^}Component = ${component^}Component;
EOF
    done
}

# Create main app JavaScript
create_main_app() {
    cat > public/js/app.js << 'EOF'
class ZKPretApp {
    constructor() {
        this.currentTab = 'gleif';
        this.isExecuting = false;
        this.serverStatus = null;
        this.init();
    }

    async init() {
        this.setupEventListeners();
        await this.checkConnection();
        this.initializeComponents();
    }

    setupEventListeners() {
        // Tab navigation
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab || e.target.closest('.tab-btn').dataset.tab);
            });
        });

        // Settings
        document.getElementById('settings-btn').addEventListener('click', () => {
            document.getElementById('settings-modal').classList.remove('hidden');
        });

        ['close-settings', 'cancel-settings'].forEach(id => {
            document.getElementById(id).addEventListener('click', () => {
                document.getElementById('settings-modal').classList.add('hidden');
            });
        });

        document.getElementById('save-settings').addEventListener('click', () => {
            notifications.info('Settings', 'Settings saved (restart required for changes)');
            document.getElementById('settings-modal').classList.add('hidden');
        });
    }

    switchTab(tabName) {
        if (this.isExecuting) {
            notifications.warning('Execution in Progress', 'Please wait for current execution to complete');
            return;
        }

        // Update buttons
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update content
        document.querySelectorAll('.tab-content').forEach(content => content.classList.add('hidden'));
        document.getElementById(`${tabName}-tab`).classList.remove('hidden');

        this.currentTab = tabName;
    }

    async checkConnection() {
        try {
            const health = await zkpretAPI.healthCheck();
            this.serverStatus = health;
            this.updateConnectionStatus(health.status === 'healthy');
            this.updateServerStatus(health);
        } catch (error) {
            this.updateConnectionStatus(false);
        }
    }

    updateConnectionStatus(connected) {
        const status = document.getElementById('connection-status');
        status.innerHTML = `
            <div class="w-3 h-3 ${connected ? 'bg-green-400' : 'bg-red-400'} rounded-full"></div>
            <span class="text-sm text-gray-600">${connected ? 'Connected' : 'Disconnected'}</span>
        `;
    }

    updateServerStatus(status) {
        const container = document.getElementById('server-status');
        container.innerHTML = `
            <div class="space-y-3">
                <div class="flex items-center justify-between">
                    <span class="text-sm font-medium">Status</span>
                    <span class="status-indicator status-${status.status === 'healthy' ? 'connected' : 'degraded'}">${status.status || 'unknown'}</span>
                </div>
                <div class="flex items-center justify-between">
                    <span class="text-sm font-medium">ZK-PRET Server</span>
                    <span class="text-sm ${status.services?.zkPretServer ? 'text-green-600' : 'text-red-600'}">
                        <i class="fas fa-${status.services?.zkPretServer ? 'check' : 'times'} mr-1"></i>
                        ${status.services?.zkPretServer ? 'Online' : 'Offline'}
                    </span>
                </div>
                <div class="text-xs text-gray-500">
                    Last updated: ${new Date(status.timestamp).toLocaleString()}
                </div>
            </div>
        `;
    }

    initializeComponents() {
        new GLEIFComponent();
        new CorporateComponent();
        new EximComponent();
        new ComplianceComponent();
        new RiskComponent();
    }

    async executeTool(toolName, parameters) {
        if (this.isExecuting) {
            notifications.warning('Execution in Progress', 'Another tool is currently executing');
            return;
        }

        this.isExecuting = true;
        const resultsContainer = document.getElementById('execution-results');
        
        resultsContainer.innerHTML = `
            <div class="text-center py-8">
                <i class="fas fa-spinner fa-spin text-2xl mb-4 text-blue-600"></i>
                <p>Generating ZK Proof...</p>
                <p class="text-sm text-gray-600 mt-2">This may take a few moments</p>
            </div>
        `;

        try {
            const result = await zkpretAPI.executeTool(toolName, parameters);
            
            if (result.success) {
                notifications.success('Success', 'ZK Proof generated successfully');
                resultsContainer.innerHTML = `
                    <div class="result-card success">
                        <div class="flex items-center mb-2">
                            <i class="fas fa-check-circle text-green-600 mr-2"></i>
                            <span class="font-semibold">Success</span>
                        </div>
                        <div class="space-y-2 text-sm">
                            <div><strong>Tool:</strong> ${toolName}</div>
                            <div><strong>ZK Proof:</strong> ${result.result?.zkProofGenerated ? 'Generated' : 'Failed'}</div>
                            <div><strong>Time:</strong> ${result.executionTime}</div>
                            ${result.result?.output ? `<div class="mt-3"><strong>Output:</strong><div class="code-output mt-1">${result.result.output.substring(0, 500)}${result.result.output.length > 500 ? '...' : ''}</div></div>` : ''}
                        </div>
                    </div>
                `;
            } else {
                notifications.error('Failed', 'ZK Proof generation failed');
                resultsContainer.innerHTML = `
                    <div class="result-card error">
                        <div class="flex items-center mb-2">
                            <i class="fas fa-exclamation-circle text-red-600 mr-2"></i>
                            <span class="font-semibold">Failed</span>
                        </div>
                        <div class="text-sm">
                            <div><strong>Error:</strong> ${result.result?.error || 'Unknown error'}</div>
                        </div>
                    </div>
                `;
            }
        } catch (error) {
            notifications.error('Error', error.message);
            resultsContainer.innerHTML = `
                <div class="text-center py-8 text-red-500">
                    <i class="fas fa-exclamation-triangle text-2xl mb-4"></i>
                    <p>Execution failed</p>
                    <p class="text-sm">${error.message}</p>
                </div>
            `;
        } finally {
            this.isExecuting = false;
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.app = new ZKPretApp();
});
EOF
}

# Create all source files
create_source_files() {
    print_status "Creating source files..."
    
    create_tsconfig
    create_server_files
    create_frontend_files
    create_main_app
    
    print_success "All source files created"
}

# Copy environment file
setup_env() {
    if [ ! -f ".env.local" ]; then
        if [ -f ".env" ]; then
            cp .env .env.local
            print_success "Environment file copied to .env.local"
            print_warning "Please update .env.local with your specific configuration"
        else
            print_error ".env file not found"
        fi
    else
        print_warning ".env.local already exists"
    fi
}

# Build the project
build_project() {
    print_status "Building project..."
    
    if npm run build; then
        print_success "Project built successfully"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Verify setup
verify_setup() {
    print_status "Verifying setup..."
    
    # Check if essential files exist
    ESSENTIAL_FILES=(
        "src/server.ts"
        "src/services/zkPretClient.ts"
        "src/utils/logger.ts"
        "src/types/index.ts"
        "public/index.html"
        "public/js/app.js"
        "public/js/utils/api.js"
        "public/js/components/gleif.js"
        "public/js/components/corporate.js"
        "public/css/styles.css"
        "tsconfig.json"
        ".env"
        ".env.local"
        "package.json"
    )
    
    local missing_files=0
    
    for file in "${ESSENTIAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_success "✓ $file exists"
        else
            print_error "✗ $file is missing"
            missing_files=$((missing_files + 1))
        fi
    done
    
    if [ $missing_files -eq 0 ]; then
        print_success "All essential files are present"
        return 0
    else
        print_error "$missing_files essential files are missing"
        return 1
    fi
}

# Main setup process
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║       ZK-PRET-WEB-APP Setup          ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_node
    check_npm
    create_directories
    create_package_json
    create_env_file
    install_dependencies
    create_source_files
    setup_env
    build_project
    
    if verify_setup; then
        echo -e "${GREEN}"
        echo "╔═══════════════════════════════════════╗"
        echo "║            Setup Complete!            ║"
        echo "╚═══════════════════════════════════════╝"
        echo -e "${NC}"
        
        print_success "ZK-PRET-WEB-APP is ready!"
        echo ""
        print_status "Next steps:"
        echo "  1. Update .env.local with your ZK-PRET-SERVER configuration"
        echo "  2. Run 'npm run dev' for development mode"
        echo "  3. Run 'npm start' for production mode"
        echo "  4. Open http://localhost:3000 in your browser"
        echo ""
        print_status "Configuration examples:"
        echo "  • HTTP Mode: ZK_PRET_SERVER_TYPE=http, ZK_PRET_SERVER_URL=http://localhost:3001"
        echo "  • STDIO Mode: ZK_PRET_SERVER_TYPE=stdio, ZK_PRET_STDIO_PATH=../ZK-PRET-TEST-V3"
        echo "  • Vercel Mode: ZK_PRET_SERVER_TYPE=vercel, ZK_PRET_SERVER_URL=https://your-app.vercel.app"
    else
        print_error "Setup completed with errors. Please check the missing files."
        exit 1
    fi
}

# Run main function
main