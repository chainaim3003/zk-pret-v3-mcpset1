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
