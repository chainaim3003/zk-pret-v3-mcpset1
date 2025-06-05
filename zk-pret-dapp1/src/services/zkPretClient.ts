import dotenv from 'dotenv';
dotenv.config();

import axios, { AxiosInstance } from 'axios';
import { spawn } from 'child_process';
import path from 'path';
import { existsSync } from 'fs';
import { logger } from '../utils/logger.js';
import type { ZKPretServerResponse, ToolExecutionResult, ServerStatus, ZKPretClientConfig } from '../types/index.js';

class ZKPretClient {
  private client?: AxiosInstance;
  private config: ZKPretClientConfig;
  private initialized: boolean = false;

  constructor() {
    console.log('=== ZK-PRET CLIENT INITIALIZATION (PRE-COMPILATION STRATEGY) ===');
    console.log('DEBUG: process.env.ZK_PRET_SERVER_TYPE =', process.env.ZK_PRET_SERVER_TYPE);
    console.log('DEBUG: process.env.ZK_PRET_STDIO_PATH =', process.env.ZK_PRET_STDIO_PATH);

    this.config = {
      serverUrl: process.env.ZK_PRET_SERVER_URL || 'http://localhost:3001',
      timeout: parseInt(process.env.ZK_PRET_SERVER_TIMEOUT || '120000'),
      retries: 3,
      serverType: (process.env.ZK_PRET_SERVER_TYPE as any) || 'http',
      stdioPath: process.env.ZK_PRET_STDIO_PATH || '../ZK-PRET-TEST-V3',
      stdioBuildPath: process.env.ZK_PRET_STDIO_BUILD_PATH || './build/tests/with-sign'
    };

    console.log('DEBUG: Final serverType =', this.config.serverType);
    console.log('DEBUG: Final stdioPath =', this.config.stdioPath);
    console.log('DEBUG: Final stdioBuildPath =', this.config.stdioBuildPath);
    console.log('=====================================');

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
      logger.warn('ZK-PRET-SERVER client initialization failed', {
        error: error instanceof Error ? error.message : String(error),
        serverType: this.config.serverType,
        stdioPath: this.config.stdioPath
      });
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
      console.log('=== STDIO HEALTH CHECK ===');
      console.log('Checking path:', this.config.stdioPath);
      
      const fs = await import('fs/promises');
      await fs.access(this.config.stdioPath!);
      console.log('✅ Main path exists');
      
      const buildPath = path.join(this.config.stdioPath!, this.config.stdioBuildPath!);
      console.log('Checking build path:', buildPath);
      await fs.access(buildPath);
      console.log('✅ Build path exists');
      
      // Check for compiled JavaScript files
      const jsFiles = [
        'GLEIFVerificationTestWithSign.js',
        'CorporateRegistrationVerificationTestWithSign.js',
        'EXIMVerificationTestWithSign.js'
      ];
      
      console.log('Checking for compiled JavaScript files:');
      for (const file of jsFiles) {
        const filePath = path.join(buildPath, file);
        try {
          await fs.access(filePath);
          console.log(`✅ Found: ${file}`);
        } catch {
          console.log(`❌ Missing: ${file}`);
        }
      }
      
      console.log('=========================');
      
      return {
        connected: true,
        status: { mode: 'stdio', path: this.config.stdioPath, buildPath }
      };
    } catch (error) {
      console.log('❌ STDIO Health Check Failed:', error instanceof Error ? error.message : String(error));
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
      console.log('=== TOOL EXECUTION START ===');
      console.log('Tool Name:', toolName);
      console.log('Parameters:', JSON.stringify(parameters, null, 2));
      console.log('Server Type:', this.config.serverType);
      
      let result;
      
      if (this.config.serverType === 'stdio') {
        result = await this.executeStdioTool(toolName, parameters);
      } else {
        const response = await this.client!.post('/api/tools/execute', { toolName, parameters });
        result = response.data;
      }

      const executionTime = Date.now() - startTime;
      
      console.log('=== TOOL EXECUTION SUCCESS ===');
      console.log('Execution Time:', `${executionTime}ms`);
      console.log('Result Success:', result.success);
      console.log('==============================');
      
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
      
      console.log('=== TOOL EXECUTION FAILED ===');
      console.log('Error:', error instanceof Error ? error.message : String(error));
      console.log('Execution Time:', `${executionTime}ms`);
      console.log('=============================');
      
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
      throw new Error(`Unknown tool: ${toolName}. Available tools: ${Object.keys(toolScriptMap).join(', ')}`);
    }

    console.log('=== STDIO TOOL EXECUTION ===');
    console.log('Tool Name:', toolName);
    console.log('Script File:', scriptFile);
    console.log('============================');
    
    return await this.executePreCompiledScript(scriptFile, parameters);
  }

  async executePreCompiledScript(scriptFile: string, parameters: any = {}): Promise<any> {
    const compiledScriptPath = path.join(this.config.stdioPath!, this.config.stdioBuildPath!, scriptFile);
    
    console.log('🔍 Checking for pre-compiled JavaScript file...');
    console.log('Expected compiled script path:', compiledScriptPath);
    
    if (!existsSync(compiledScriptPath)) {
      console.log('❌ Pre-compiled JavaScript file not found');
      console.log('🔧 Attempting to build the project first...');
      
      const buildSuccess = await this.buildProject();
      if (!buildSuccess) {
        throw new Error(`Pre-compiled JavaScript file not found: ${compiledScriptPath}. Please run 'npm run build' in the ZK-PRET-TEST-V3 directory first.`);
      }
      
      if (!existsSync(compiledScriptPath)) {
        throw new Error(`Build completed but compiled file still not found: ${compiledScriptPath}`);
      }
    }
    
    console.log('✅ Pre-compiled JavaScript file found');
    console.log('🚀 Executing compiled JavaScript file...');
    
    return await this.executeJavaScriptFile(compiledScriptPath, parameters);
  }

  async buildProject(): Promise<boolean> {
    return new Promise((resolve) => {
      console.log('🔨 Building ZK-PRET project...');
      console.log('Working directory:', this.config.stdioPath);
      
      const buildProcess = spawn('npm', ['run', 'build'], {
        cwd: this.config.stdioPath,
        stdio: ['pipe', 'pipe', 'pipe'],
        shell: true
      });

      let stdout = '';
      let stderr = '';

      buildProcess.stdout.on('data', (data: Buffer) => {
        const output = data.toString();
        stdout += output;
        console.log('📤 BUILD-STDOUT:', output.trim());
      });

      buildProcess.stderr.on('data', (data: Buffer) => {
        const output = data.toString();
        stderr += output;
        console.log('📥 BUILD-STDERR:', output.trim());
      });

      buildProcess.on('close', (code: number | null) => {
        if (code === 0) {
          console.log('✅ Project build completed successfully');
          resolve(true);
        } else {
          console.log('❌ Project build failed with exit code:', code);
          console.log('Build STDERR:', stderr);
          console.log('Build STDOUT:', stdout);
          resolve(false);
        }
      });

      buildProcess.on('error', (error: Error) => {
        console.log('❌ Build process error:', error.message);
        resolve(false);
      });
    });
  }

  async executeJavaScriptFile(scriptPath: string, parameters: any = {}): Promise<any> {
    return new Promise((resolve, reject) => {
      const args = this.prepareScriptArgs(parameters);
      
      console.log('=== JAVASCRIPT EXECUTION DEBUG ===');
      console.log('Script Path:', scriptPath);
      console.log('Working Directory:', this.config.stdioPath);
      console.log('Arguments:', args);
      console.log('Full Command:', `node ${scriptPath} ${args.join(' ')}`);
      console.log('===================================');
      
      const nodeProcess = spawn('node', [scriptPath, ...args], {
        cwd: this.config.stdioPath,
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { 
          ...process.env,
          NODE_ENV: 'production'
        }
      });

      let stdout = '';
      let stderr = '';
      let isResolved = false;

      const timeoutId = setTimeout(() => {
        if (!isResolved) {
          isResolved = true;
          nodeProcess.kill('SIGTERM');
          console.log(`❌ EXECUTION TIMEOUT after ${this.config.timeout}ms`);
          reject(new Error(`Script execution timeout after ${this.config.timeout}ms`));
        }
      }, this.config.timeout);

      nodeProcess.stdout.on('data', (data: Buffer) => {
        const output = data.toString();
        stdout += output;
        console.log('📤 STDOUT:', output.trim());
      });

      nodeProcess.stderr.on('data', (data: Buffer) => {
        const output = data.toString();
        stderr += output;
        console.log('📥 STDERR:', output.trim());
      });

      nodeProcess.on('close', (code: number | null) => {
        if (!isResolved) {
          isResolved = true;
          clearTimeout(timeoutId);
          
          console.log('=== JAVASCRIPT EXECUTION COMPLETE ===');
          console.log('Exit Code:', code);
          console.log('Final STDOUT Length:', stdout.length);
          console.log('Final STDERR Length:', stderr.length);
          console.log('=====================================');
          
          if (code === 0) {
            console.log('✅ JAVASCRIPT EXECUTION SUCCESSFUL');
            resolve({
              success: true,
              result: {
                status: 'completed',
                zkProofGenerated: true,
                timestamp: new Date().toISOString(),
                output: stdout,
                stderr: stderr,
                executionStrategy: 'Pre-compiled JavaScript execution'
              }
            });
          } else {
            console.log(`❌ JAVASCRIPT EXECUTION FAILED with exit code ${code}`);
            reject(new Error(`Script failed with exit code ${code}: ${stderr || stdout || 'No output'}`));
          }
        }
      });

      nodeProcess.on('error', (error: Error) => {
        if (!isResolved) {
          isResolved = true;
          clearTimeout(timeoutId);
          console.log('❌ JAVASCRIPT PROCESS ERROR:', error.message);
          reject(error);
        }
      });

      console.log(`🚀 JavaScript process spawned with PID: ${nodeProcess.pid}`);
    });
  }

  prepareScriptArgs(parameters: any): string[] {
    console.log('=== PREPARING SCRIPT ARGS ===');
    console.log('Input parameters:', parameters);
    
    // For GLEIF verification, the script expects positional arguments:
    // 1. Company name (from legalName parameter)
    // 2. Network type (always "TESTNET")
    const args: string[] = [];
    
    // Extract company name from legalName parameter
    const companyName = parameters.legalName || parameters.entityName || parameters.companyName;
    if (companyName) {
      args.push(String(companyName));
      console.log(`Added positional arg 1 (company name): "${companyName}"`);
    } else {
      console.log('⚠️  No company name found in parameters');
    }
    
    // Always add TESTNET as the network type
    args.push('TESTNET');
    console.log('Added positional arg 2 (network type): "TESTNET"');
    
    console.log('Final args array:', args);
    console.log('Command will be: node script.js', args.map(arg => `"${arg}"`).join(' '));
    console.log('=============================');
    
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