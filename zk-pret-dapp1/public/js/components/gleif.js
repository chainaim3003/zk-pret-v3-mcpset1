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
