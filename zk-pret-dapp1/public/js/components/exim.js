class EximComponent {
    constructor() {
        this.render();
    }

    render() {
        const container = document.getElementById('exim-content');
        container.innerHTML = `
            <div class="text-center py-8 text-gray-500">
                <i class="fas fa-cog text-4xl mb-4 opacity-50"></i>
                <p>Exim verification component</p>
                <p class="text-sm">Implementation coming soon...</p>
            </div>
        `;
    }
}

window.EximComponent = EximComponent;
