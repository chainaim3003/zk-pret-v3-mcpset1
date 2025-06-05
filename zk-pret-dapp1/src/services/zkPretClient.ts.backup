import dotenv from 'dotenv';
dotenv.config();

import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { spawn } from 'child_process';
import path from 'path';
import { readFileSync, existsSync, mkdirSync, writeFileSync, unlinkSync } from 'fs';
import { logger } from '../utils/logger.js';
import type { ZKPretServerResponse, ToolExecutionResult, ServerStatus, ZKPretClientConfig } from '../types/index.js';

class ZKPretClient {
  private client?: AxiosInstance;
  private config: ZKPretClientConfig;
  private initialized: boolean = false;

  constructor() {
    // DEBUG: Log environment variables
    console.log('=== ZK-PRET CLIENT INITIALIZATION ===');
    console.log('DEBUG: process.env.ZK_PRET_SERVER_TYPE =', process.env.ZK_PRET_SERVER_TYPE);
    console.log('DEBUG: process.env.ZK_PRET_STDIO_PATH =', process.env.ZK_PRET_STDIO_PATH);
    console.log('DEBUG: Raw env type =', typeof process.env.ZK_PRET_SERVER_TYPE);

    this.config = {
      serverUrl: process.env.ZK_PRET_SERVER_URL || 'http://localhost:3001',
      timeout: parseInt(process.env.ZK_PRET_SERVER_TIMEOUT || '120000'),
      retries: 3,
      serverType: (process.env.ZK_PRET_SERVER_TYPE as any) || 'http',
      stdioPath: process.env.ZK_PRET_STDIO_PATH || '../ZK-PRET-TEST-V3',
      stdioBuildPath: process.env.ZK_PRET_STDIO_BUILD_PATH || './src/tests/with-sign'
    };

    // DEBUG: Log final config
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
      
      // Check for specific script files
      const testFiles = [
        'GLEIFVerificationTestWithSign.ts',
        'CorporateRegistrationVerificationTestWithSign.ts',
        'EXIMVerificationTestWithSign.ts'
      ];
      
      console.log('Checking for script files:');
      for (const file of testFiles) {
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
      'get-GLEIF-verification-with-sign': 'GLEIFVerificationTestWithSign.ts',
      'get-Corporate-Registration-verification-with-sign': 'CorporateRegistrationVerificationTestWithSign.ts',
      'get-EXIM-verification-with-sign': 'EXIMVerificationTestWithSign.ts',
      'get-BSDI-compliance-verification': 'BusinessStandardDataIntegrityVerificationTest.ts',
      'get-BPI-compliance-verification': 'BusinessProcessIntegrityVerificationFileTestWithSign.ts',
      'get-RiskLiquidityACTUS-Verifier-Test_adv_zk': 'RiskLiquidityACTUSVerifierTest_adv_zk_WithSign.ts',
      'get-RiskLiquidityACTUS-Verifier-Test_Basel3_Withsign': 'RiskLiquidityACTUSVerifierTest_basel3_Withsign.ts'
    };

    const scriptFile = toolScriptMap[toolName];
    if (!scriptFile) {
      throw new Error(`Unknown tool: ${toolName}. Available tools: ${Object.keys(toolScriptMap).join(', ')}`);
    }

    const scriptPath = path.join(this.config.stdioPath!, this.config.stdioBuildPath!, scriptFile);
    
    console.log('=== STDIO TOOL EXECUTION ===');
    console.log('Tool Name:', toolName);
    console.log('Script File:', scriptFile);
    console.log('Script Path:', scriptPath);
    console.log('============================');
    
    return await this.executeNodeScript(scriptPath, parameters);
  }

  async executeNodeScript(scriptPath: string, parameters: any = {}): Promise<any> {
    // First try to compile and execute as JavaScript
    try {
      console.log('🔧 Attempting TypeScript compilation approach...');
      const jsResult = await this.executeWithCompilation(scriptPath, parameters);
      if (jsResult) {
        return jsResult;
      }
    } catch (error) {
      console.log('⚠️ Compilation approach failed:', error instanceof Error ? error.message : String(error));
      console.log('📋 Full compilation error details:', error);
    }

    return new Promise((resolve, reject) => {
      const args = this.prepareScriptArgs(parameters);
      
      // Multiple execution strategies to try
      const strategies = [
        {
          name: 'Node.js with tsx import (Node v20+)',
          executor: 'node',
          args: ['--import', 'tsx/esm', '--no-warnings', scriptPath, ...args]
        },
        {
          name: 'Node.js direct execution (may fail on TS)',
          executor: 'node',
          args: [scriptPath, ...args]
        },
        {
          name: 'tsx direct execution',
          executor: 'tsx',
          args: [scriptPath, ...args]
        },
        {
          name: 'ts-node with ESM',
          executor: 'ts-node',
          args: ['--esm', '--transpile-only', scriptPath, ...args]
        },
        {
          name: 'Node.js with tsx import and experimental modules',
          executor: 'node',
          args: ['--import', 'tsx/esm', '--experimental-modules', '--no-warnings', scriptPath, ...args]
        },
        {
          name: 'Node.js with module resolution flags',
          executor: 'node',
          args: ['--experimental-modules', '--experimental-json-modules', scriptPath, ...args]
        },
        {
          name: 'Node.js with experimental import assertions',
          executor: 'node',
          args: ['--experimental-loader', './node_modules/tsx/esm/index.mjs', '--no-warnings', scriptPath, ...args]
        },
        {
          name: 'ts-node with CommonJS',
          executor: 'ts-node',
          args: ['--prefer-ts-exts', '--transpile-only', scriptPath, ...args]
        },
        {
          name: 'Node.js with tsx ESM (legacy)',
          executor: 'node',
          args: ['--loader', 'tsx/esm', '--no-warnings', scriptPath, ...args]
        },
        {
          name: 'Node.js with tsx CJS',
          executor: 'node',
          args: ['--loader', 'tsx/cjs', '--no-warnings', scriptPath, ...args]
        },
        {
          name: 'Node.js with ts-node ESM loader',
          executor: 'node',
          args: ['--loader', 'ts-node/esm', '--no-warnings', scriptPath, ...args]
        },
        {
          name: 'Node.js with experimental specifier resolution',
          executor: 'node',
          args: ['--experimental-specifier-resolution=node', '--loader', 'tsx/esm', '--no-warnings', scriptPath, ...args]
        }
      ];
      
      let currentStrategyIndex = 0;
      
      const tryNextStrategy = () => {
        if (currentStrategyIndex >= strategies.length) {
          console.log(`🔨 All execution strategies failed. Let\'s try a manual compilation approach...`);
          
          // Last resort: try to manually fix the script and run it
          this.tryManualScriptFix(scriptPath, parameters, resolve, reject);
          return;
        }
        
        const strategy = strategies[currentStrategyIndex];
        currentStrategyIndex++;
        
        console.log(`🔄 Trying strategy ${currentStrategyIndex}/${strategies.length}: ${strategy.name}`);
        
        // Check if script file exists and analyze its content
        if (!existsSync(scriptPath)) {
          console.log('❌ SCRIPT FILE DOES NOT EXIST:', scriptPath);
          reject(new Error(`Script file does not exist: ${scriptPath}`));
          return;
        }
        console.log('✅ Script file exists');
        
        // Analyze file content for module diagnostics (only on first strategy)
        if (currentStrategyIndex === 1) {
          try {
            const fileContent = readFileSync(scriptPath, 'utf8');
            console.log('=== FILE CONTENT ANALYSIS ===');
            console.log('File size:', fileContent.length, 'characters');
            
            // Check for module indicators
            const hasRequire = fileContent.includes('require(');
            const hasImport = fileContent.includes('import ');
            const hasExports = fileContent.includes('exports.');
            const hasModuleExports = fileContent.includes('module.exports');
            const hasESImport = /import\s+.*\s+from\s+['"]/.test(fileContent);
            const hasESExport = /export\s+(default|const|function|class)/.test(fileContent);
            
            console.log('Module system indicators:');
            console.log('  - CommonJS require():', hasRequire);
            console.log('  - ES6 import:', hasImport);
            console.log('  - ES6 import syntax:', hasESImport);
            console.log('  - CommonJS exports:', hasExports);
            console.log('  - CommonJS module.exports:', hasModuleExports);
            console.log('  - ES6 export:', hasESExport);
            
            // Show first few lines
            const lines = fileContent.split('\n').slice(0, 10);
            console.log('First 10 lines of file:');
            lines.forEach((line: string, index: number) => {
              console.log(`  ${index + 1}: ${line}`);
            });
            
            console.log('=============================');
          } catch (error) {
            console.log('Failed to analyze file content:', error);
          }
        }
        
        // LOG: What we're about to execute
        console.log('=== SCRIPT EXECUTION DEBUG ===');
        console.log('Strategy:', strategy.name);
        console.log('Script Path:', scriptPath);
        console.log('Working Directory:', this.config.stdioPath);
        console.log('Arguments:', args);
        console.log('Full Command:', `${strategy.executor} ${strategy.args.join(' ')}`);
        console.log('Parameters:', JSON.stringify(parameters, null, 2));
        console.log('Environment PATH:', process.env.PATH?.substring(0, 200) + '...');
        
        const childProcess = spawn(strategy.executor, strategy.args, {
          cwd: this.config.stdioPath,
          stdio: ['pipe', 'pipe', 'pipe'],
          env: { 
            ...process.env,
            NODE_OPTIONS: '--experimental-loader tsx/esm --no-warnings',
            TS_NODE_ESM: '1'
          }
        });

        let stdout = '';
        let stderr = '';
        let isResolved = false;
        let strategyFailed = false;

        const timeoutId = setTimeout(() => {
          if (!isResolved) {
            isResolved = true;
            strategyFailed = true;
            childProcess.kill('SIGTERM');
            console.log(`❌ STRATEGY TIMEOUT after ${this.config.timeout}ms: ${strategy.name}`);
            tryNextStrategy();
          }
        }, this.config.timeout);

        childProcess.stdout.on('data', (data: Buffer) => {
          const output = data.toString();
          stdout += output;
          console.log('📤 STDOUT:', output.trim());
        });

        childProcess.stderr.on('data', (data: Buffer) => {
          const output = data.toString();
          stderr += output;
          console.log('📥 STDERR:', output.trim());
        });

        childProcess.on('close', (code: number | null) => {
          if (!isResolved && !strategyFailed) {
            isResolved = true;
            clearTimeout(timeoutId);
            
            console.log('=== SCRIPT EXECUTION COMPLETE ===');
            console.log('Strategy:', strategy.name);
            console.log('Exit Code:', code);
            console.log('Final STDOUT Length:', stdout.length);
            console.log('Final STDERR Length:', stderr.length);
            if (stdout.length > 0) {
              console.log('Final STDOUT:', stdout.substring(0, 500) + (stdout.length > 500 ? '...' : ''));
            }
            if (stderr.length > 0) {
              console.log('Final STDERR:', stderr.substring(0, 500) + (stderr.length > 500 ? '...' : ''));
            }
            console.log('=====================================');
            
            if (code === 0) {
              console.log(`✅ SCRIPT COMPLETED SUCCESSFULLY with strategy: ${strategy.name}`);
              resolve({
                success: true,
                result: {
                  status: 'completed',
                  zkProofGenerated: true,
                  timestamp: new Date().toISOString(),
                  output: stdout,
                  stderr: stderr,
                  executionStrategy: strategy.name
                }
              });
            } else {
              console.log(`❌ STRATEGY FAILED with exit code ${code}: ${strategy.name}`);
              console.log('Error output:', stderr || stdout || 'No output');
              
              // Check if this is a "require is not defined" error or similar module issue
              const errorOutput = (stderr + stdout).toLowerCase();
              if (errorOutput.includes('require is not defined') || 
                  errorOutput.includes('module is not defined') ||
                  errorOutput.includes('exports is not defined')) {
                console.log('🔍 Detected module system error, trying next strategy...');
                tryNextStrategy();
              } else {
                // This might be an actual script error, not a module system issue
                reject(new Error(`Script failed with exit code ${code}: ${stderr || stdout || 'No output'}`));
              }
            }
          }
        });

        childProcess.on('error', (error: Error) => {
          if (!isResolved && !strategyFailed) {
            isResolved = true;
            clearTimeout(timeoutId);
            console.log(`❌ STRATEGY PROCESS ERROR: ${strategy.name}`);
            console.log('Error details:', {
              name: error.name,
              message: error.message,
              stack: error.stack?.substring(0, 300)
            });
            
            // Check if this is a "command not found" error
            if (error.message.includes('ENOENT') || error.message.includes('spawn')) {
              console.log(`⚠️ Executor '${strategy.executor}' not found, trying next strategy...`);
              tryNextStrategy();
            } else {
              reject(error);
            }
          }
        });

        // Log when process starts
        console.log(`🚀 Process spawned with PID: ${childProcess.pid} using strategy: ${strategy.name}`);
      };
      
      // Start with the first strategy
      tryNextStrategy();
    });
  }

  async tryManualScriptFix(scriptPath: string, parameters: any, resolve: Function, reject: Function): Promise<void> {
    try {
      console.log('🔧 Attempting manual script modification...');
      
      // Read the original script
      const originalContent = readFileSync(scriptPath, 'utf8');
      
      // Create a modified version that should work in Node.js
      let modifiedContent = originalContent;
      
      // Add CommonJS compatibility at the top
      const compatibilityHeader = `
// Auto-added compatibility layer
if (typeof require === 'undefined') {
  global.require = (await import('module')).createRequire(import.meta.url);
}
if (typeof __dirname === 'undefined') {
  global.__dirname = new URL('.', import.meta.url).pathname;
}
if (typeof __filename === 'undefined') {
  global.__filename = new URL(import.meta.url).pathname;
}

`;
      
      modifiedContent = compatibilityHeader + modifiedContent;
      
      // Create temp directory and modified file
      const tempDir = path.join(this.config.stdioPath!, '.temp');
      if (!existsSync(tempDir)) {
        mkdirSync(tempDir, { recursive: true });
      }
      
      const modifiedFileName = 'modified_' + path.basename(scriptPath);
      const modifiedFilePath = path.join(tempDir, modifiedFileName);
      
      writeFileSync(modifiedFilePath, modifiedContent, 'utf8');
      console.log('✅ Created modified script:', modifiedFilePath);
      
      // Try to execute the modified script
      const args = this.prepareScriptArgs(parameters);
      
      console.log('🚀 Executing modified script with tsx...');
      const nodeProcess = spawn('tsx', [modifiedFilePath, ...args], {
        cwd: this.config.stdioPath,
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { ...process.env }
      });

      let stdout = '';
      let stderr = '';

      nodeProcess.stdout.on('data', (data: Buffer) => {
        const output = data.toString();
        stdout += output;
        console.log('📤 MODIFIED-STDOUT:', output.trim());
      });

      nodeProcess.stderr.on('data', (data: Buffer) => {
        const output = data.toString();
        stderr += output;
        console.log('📥 MODIFIED-STDERR:', output.trim());
      });

      nodeProcess.on('close', (code: number | null) => {
        // Cleanup
        try {
          unlinkSync(modifiedFilePath);
        } catch (e) {}

        if (code === 0) {
          console.log('✅ Modified script execution successful');
          resolve({
            success: true,
            result: {
              status: 'completed',
              zkProofGenerated: true,
              timestamp: new Date().toISOString(),
              output: stdout,
              stderr: stderr,
              executionStrategy: 'Manual script modification with tsx'
            }
          });
        } else {
          reject(new Error(`Modified script execution failed with code ${code}: ${stderr || stdout || 'No output'}`));
        }
      });

      nodeProcess.on('error', (error: Error) => {
        // Cleanup
        try {
          unlinkSync(modifiedFilePath);
        } catch (e) {}
        reject(error);
      });
      
    } catch (error) {
      console.log('❌ Manual script fix failed:', error);
      reject(new Error('All execution strategies including manual fix failed. The TypeScript file may have incompatible module syntax.'));
    }
  }

  async executeWithCompilation(scriptPath: string, parameters: any = {}): Promise<any> {
    return new Promise((resolve, reject) => {
      console.log('🔧 Attempting TypeScript compilation approach...');
      
      // Create a temporary directory for compiled JS
      const tempDir = path.join(this.config.stdioPath!, '.temp');
      const jsFileName = path.basename(scriptPath, '.ts') + '.js';
      const jsFilePath = path.join(tempDir, jsFileName);
      
      // Ensure temp directory exists
      if (!existsSync(tempDir)) {
        mkdirSync(tempDir, { recursive: true });
      }

      // Try different TypeScript compilation approaches
      const tscCommands = [
        {
          name: 'npx tsc',
          cmd: 'npx',
          args: ['tsc', scriptPath, '--outDir', tempDir, '--target', 'es2020', '--module', 'commonjs', '--moduleResolution', 'node', '--allowJs', '--skipLibCheck']
        },
        {
          name: 'tsc direct',
          cmd: 'tsc',
          args: [scriptPath, '--outDir', tempDir, '--target', 'es2020', '--module', 'commonjs', '--moduleResolution', 'node', '--allowJs', '--skipLibCheck']
        },
        {
          name: 'node with tsc module',
          cmd: 'node',
          args: ['-e', `
            const { spawn } = require('child_process');
            const proc = spawn('tsc', [
              '${scriptPath.replace(/\\/g, '/')}',
              '--outDir', '${tempDir.replace(/\\/g, '/')}',
              '--target', 'es2020',
              '--module', 'commonjs',
              '--moduleResolution', 'node',
              '--allowJs',
              '--skipLibCheck'
            ]);
            proc.on('close', (code) => process.exit(code));
          `]
        }
      ];
      
      let currentCommandIndex = 0;
      
      const tryNextCommand = () => {
        if (currentCommandIndex >= tscCommands.length) {
          reject(new Error('All TypeScript compilation methods failed. TypeScript compiler not available.'));
          return;
        }
        
        const tscCommand = tscCommands[currentCommandIndex];
        currentCommandIndex++;
        
        console.log(`📋 Trying compilation method ${currentCommandIndex}/${tscCommands.length}: ${tscCommand.name}`);
        console.log(`Command: ${tscCommand.cmd} ${tscCommand.args.join(' ')}`);
        
        const tscProcess = spawn(tscCommand.cmd, tscCommand.args, {
          cwd: this.config.stdioPath,
          stdio: ['pipe', 'pipe', 'pipe']
        });

        let tscStderr = '';
        let tscStdout = '';
        
        tscProcess.stdout.on('data', (data: Buffer) => {
          tscStdout += data.toString();
          console.log('🔧 TSC-STDOUT:', data.toString().trim());
        });
        
        tscProcess.stderr.on('data', (data: Buffer) => {
          tscStderr += data.toString();
          console.log('🔧 TSC-STDERR:', data.toString().trim());
        });

        tscProcess.on('close', (code: number | null) => {
          if (code === 0 && existsSync(jsFilePath)) {
            console.log('✅ TypeScript compilation successful, executing JavaScript...');
            
            // Execute the compiled JavaScript
            const args = this.prepareScriptArgs(parameters);
            const nodeProcess = spawn('node', [jsFilePath, ...args], {
              cwd: this.config.stdioPath,
              stdio: ['pipe', 'pipe', 'pipe'],
              env: { ...process.env }
            });

            let stdout = '';
            let stderr = '';

            nodeProcess.stdout.on('data', (data: Buffer) => {
              const output = data.toString();
              stdout += output;
              console.log('📤 JS-STDOUT:', output.trim());
            });

            nodeProcess.stderr.on('data', (data: Buffer) => {
              const output = data.toString();
              stderr += output;
              console.log('📥 JS-STDERR:', output.trim());
            });

            nodeProcess.on('close', (jsCode: number | null) => {
              // Cleanup
              try {
                unlinkSync(jsFilePath);
              } catch (e) {}

              if (jsCode === 0) {
                console.log('✅ JavaScript execution successful');
                resolve({
                  success: true,
                  result: {
                    status: 'completed',
                    zkProofGenerated: true,
                    timestamp: new Date().toISOString(),
                    output: stdout,
                    stderr: stderr,
                    executionStrategy: 'TypeScript compilation to JavaScript'
                  }
                });
              } else {
                reject(new Error(`JavaScript execution failed with code ${jsCode}: ${stderr || stdout}`));
              }
            });

            nodeProcess.on('error', (error: Error) => {
              reject(error);
            });
          } else {
            console.log(`❌ Compilation method ${tscCommand.name} failed:`);
            console.log('Exit code:', code);
            console.log('STDERR:', tscStderr);
            console.log('STDOUT:', tscStdout);
            console.log('Expected JS file:', jsFilePath);
            console.log('JS file exists:', existsSync(jsFilePath));
            
            // Try next compilation method
            tryNextCommand();
          }
        });

        tscProcess.on('error', (error: Error) => {
          console.log(`❌ Compilation method ${tscCommand.name} failed with error:`, error.message);
          // Try next compilation method
          tryNextCommand();
        });
      };
      
      // Start with the first compilation method
      tryNextCommand();
    });
  }

  prepareScriptArgs(parameters: any): string[] {
    const args: string[] = [];
    
    console.log('=== PREPARING SCRIPT ARGS ===');
    console.log('Input parameters:', parameters);
    
    Object.keys(parameters).forEach(key => {
      const value = parameters[key];
      if (value !== null && value !== undefined && value !== '') {
        args.push(`--${key}`, String(value));
        console.log(`Added arg: --${key} = "${String(value)}"`);
      } else {
        console.log(`Skipped empty parameter: ${key} = ${value}`);
      }
    });
    
    console.log('Final args array:', args);
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