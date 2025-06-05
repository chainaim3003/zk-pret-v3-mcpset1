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
