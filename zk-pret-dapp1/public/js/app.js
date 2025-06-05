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
