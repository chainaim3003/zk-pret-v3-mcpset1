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
