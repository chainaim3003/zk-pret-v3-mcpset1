#!/bin/bash

# ZK-PRET Enterprise Compliance Platform Setup Script
# Version: 1.0.0
# Description: Automated setup for ZK-PRET MCP Client and Server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="zk-pret-platform"
NODE_VERSION="18.0.0"
DEFAULT_PORT=3001
DEFAULT_HOST="localhost"

# ASCII Art Banner
print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ZK-PRET PLATFORM                         ║"
    echo "║           Zero-Knowledge Privacy-Preserving                 ║"
    echo "║              Enterprise Technology                           ║"
    echo "║                                                              ║"
    echo "║              🔐 Compliance Verification 🔐                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    log_step "Checking system requirements..."
    
    # Check Node.js
    if command_exists node; then
        NODE_VER=$(node --version | cut -d'v' -f2)
        log_info "Node.js found: v$NODE_VER"
        
        # Check if version is sufficient (18+)
        if [[ $(echo "$NODE_VER" | cut -d'.' -f1) -lt 18 ]]; then
            log_warning "Node.js version should be 18+ for optimal performance"
        fi
    else
        log_error "Node.js not found. Please install Node.js 18+ from https://nodejs.org"
        exit 1
    fi
    
    # Check npm
    if command_exists npm; then
        NPM_VER=$(npm --version)
        log_info "npm found: v$NPM_VER"
    else
        log_error "npm not found. Please install npm"
        exit 1
    fi
    
    # Check Git
    if command_exists git; then
        GIT_VER=$(git --version | cut -d' ' -f3)
        log_info "Git found: v$GIT_VER"
    else
        log_warning "Git not found. Manual installation may be required"
    fi
    
    # Check available ports
    if command_exists lsof; then
        if lsof -i :$DEFAULT_PORT >/dev/null 2>&1; then
            log_warning "Port $DEFAULT_PORT is already in use"
        else
            log_info "Port $DEFAULT_PORT is available"
        fi
    fi
    
    log_success "System requirements check completed"
}

# Create project structure
create_project_structure() {
    log_step "Creating project structure..."
    
    # Create main directories
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    
    # Create directory structure
    mkdir -p {src/{client,server,utils,types,config,middleware,scripts},public,logs,data,docs,tests}
    mkdir -p src/data/{scf,bpmn,gleif,corporate,exim,risk}
    
    # Create subdirectories
    mkdir -p {public/assets,public/css,public/js}
    mkdir -p {tests/unit,tests/integration,tests/e2e}
    mkdir -p {docs/api,docs/guides,docs/examples}
    
    log_success "Project structure created"
}

# Generate package.json
generate_package_json() {
    log_step "Generating package.json..."
    
    cat > package.json << 'EOF'
{
  "name": "zk-pret-platform",
  "version": "1.0.0",
  "description": "Zero-Knowledge Privacy-Preserving Enterprise Technology Platform for Compliance Verification",
  "main": "dist/server.js",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc && npm run copy-static",
    "start": "node dist/server.js",
    "start:prod": "NODE_ENV=production node dist/server.js",
    "copy-static": "cp -r public/* dist/public/ 2>/dev/null || true",
    "clean": "rm -rf dist",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix",
    "setup": "node scripts/setup.js",
    "docker:build": "docker build -t zk-pret-platform .",
    "docker:run": "docker run -p 3001:3001 -e NODE_ENV=production zk-pret-platform"
  },
  "keywords": [
    "zero-knowledge",
    "compliance",
    "blockchain",
    "mina",
    "enterprise",
    "privacy",
    "verification",
    "gleif",
    "basel3",
    "actus"
  ],
  "author": "ZK-PRET Enterprise Team",
  "license": "MIT",
  "dependencies": {
    "@types/node": "^20.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-rate-limit": "^6.7.0",
    "helmet": "^6.1.5",
    "jsonwebtoken": "^9.0.0",
    "tsx": "^3.12.7",
    "typescript": "^5.0.4",
    "winston": "^3.8.2",
    "ws": "^8.13.0",
    "zod": "^3.21.4"
  },
  "devDependencies": {
    "@types/cors": "^2.8.13",
    "@types/express": "^4.17.17",
    "@types/jest": "^29.5.1",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/ws": "^8.5.4",
    "@typescript-eslint/eslint-plugin": "^5.59.5",
    "@typescript-eslint/parser": "^5.59.5",
    "eslint": "^8.40.0",
    "jest": "^29.5.0",
    "nodemon": "^2.0.22",
    "ts-jest": "^29.1.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}
EOF
    
    log_success "package.json generated"
}

# Generate TypeScript configuration
generate_tsconfig() {
    log_step "Generating TypeScript configuration..."
    
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "sourceMap": true,
    "declaration": true,
    "declarationMap": true,
    "removeComments": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitAny": true,
    "noImplicitThis": true,
    "noImplicitReturns": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "baseUrl": "./src",
    "paths": {
      "@/*": ["./*"],
      "@/types/*": ["./types/*"],
      "@/utils/*": ["./utils/*"],
      "@/config/*": ["./config/*"]
    }
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "tests"
  ]
}
EOF
    
    log_success "TypeScript configuration generated"
}

# Generate environment files
generate_env_files() {
    log_step "Generating environment configuration..."
    
    # .env.example
    cat > .env.example << EOF
# ZK-PRET Platform Configuration

# Server Configuration
NODE_ENV=development
ZK_PRET_SERVER_PORT=3001
ZK_PRET_SERVER_HOST=localhost

# ZK-PRET MCP Server Path
ZK_PRET_MCP_SERVER_PATH=../ZK-PRET-TEST-V3/build/src/pretmcpserver/index.js

# Security
JWT_SECRET=your-super-secret-jwt-key-here-change-in-production
CORS_ORIGIN=http://localhost:3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# Logging
LOG_LEVEL=info

# Blockchain Networks
MINA_MAINNET_URL=https://proxy.berkeley.minaexplorer.com/graphql
MINA_TESTNET_URL=https://proxy.berkeley.minaexplorer.com/graphql

# External APIs
GLEIF_API_URL=https://api.gleif.org/api/v1
ACTUS_SERVER_URL=http://98.84.165.146:8083

# Database (Future)
# DATABASE_URL=postgresql://username:password@localhost:5432/zkpret

# Redis (Future)
# REDIS_URL=redis://localhost:6379

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
EOF
    
    # Copy to .env if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env
        log_info "Created .env file from template"
    else
        log_warning ".env file already exists, skipping"
    fi
    
    log_success "Environment files generated"
}

# Generate ESLint configuration
generate_eslint_config() {
    log_step "Generating ESLint configuration..."
    
    cat > .eslintrc.json << 'EOF'
{
  "parser": "@typescript-eslint/parser",
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended"
  ],
  "plugins": ["@typescript-eslint"],
  "parserOptions": {
    "ecmaVersion": 2022,
    "sourceType": "module"
  },
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/explicit-module-boundary-types": "off",
    "@typescript-eslint/no-inferrable-types": "off",
    "prefer-const": "error",
    "no-var": "error"
  },
  "env": {
    "node": true,
    "es2022": true,
    "jest": true
  }
}
EOF
    
    log_success "ESLint configuration generated"
}

# Generate Jest configuration
generate_jest_config() {
    log_step "Generating Jest configuration..."
    
    cat > jest.config.js << 'EOF'
export default {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: [
    '**/__tests__/**/*.ts',
    '**/?(*.)+(spec|test).ts'
  ],
  transform: {
    '^.+\\.ts$': ['ts-jest', {
      useESM: true
    }]
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/types/**/*'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  extensionsToTreatAsEsm: ['.ts'],
  globals: {
    'ts-jest': {
      useESM: true
    }
  }
};
EOF
    
    log_success "Jest configuration generated"
}

# Generate Dockerfile
generate_dockerfile() {
    log_step "Generating Dockerfile..."
    
    cat > Dockerfile << 'EOF'
# ZK-PRET Platform Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install dependencies for building native modules
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S zkpret -u 1001

# Create logs directory with proper permissions
RUN mkdir -p logs && chown -R zkpret:nodejs logs

# Switch to non-root user
USER zkpret

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/api/health || exit 1

# Start the application
CMD ["npm", "start:prod"]
EOF
    
    # Generate .dockerignore
    cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.local
.nyc_output
coverage
.coverage
dist
.DS_Store
logs/*.log
EOF
    
    log_success "Docker configuration generated"
}

# Generate GitHub workflows
generate_github_workflows() {
    log_step "Generating GitHub Actions workflows..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x, 20.x]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    
    - run: npm ci
    - run: npm run lint
    - run: npm run build
    - run: npm test -- --coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3

  docker:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t zk-pret-platform .
    
    - name: Test Docker image
      run: |
        docker run -d --name test-container -p 3001:3001 zk-pret-platform
        sleep 10
        curl -f http://localhost:3001/api/health || exit 1
        docker stop test-container
EOF
    
    log_success "GitHub Actions workflows generated"
}

# Copy source files
copy_source_files() {
    log_step "Setting up source files..."
    
    # Check if source files are available in current directory
    if [ -f "../zk-pret-enhanced-frontend.html" ]; then
        cp ../zk-pret-enhanced-frontend.html public/index.html
        log_info "Copied frontend HTML file"
    else
        log_warning "Frontend HTML file not found, creating placeholder"
        echo "<h1>ZK-PRET Platform</h1><p>Frontend will be served here</p>" > public/index.html
    fi
    
    # Create basic server file if TypeScript files aren't available
    if [ ! -f "../zk-pret-enhanced-server.ts" ]; then
        log_warning "Server TypeScript files not found, creating basic structure"
        
        cat > src/server.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

const app = express();
const PORT = process.env.ZK_PRET_SERVER_PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`ZK-PRET Platform running on port ${PORT}`);
});
EOF
    else
        log_info "Using provided TypeScript server files"
        cp ../zk-pret-enhanced-server.ts src/server.ts
    fi
    
    log_success "Source files configured"
}

# Install dependencies
install_dependencies() {
    log_step "Installing dependencies..."
    
    if command_exists npm; then
        npm install
        log_success "Dependencies installed successfully"
    else
        log_error "npm not found, cannot install dependencies"
        exit 1
    fi
}

# Run initial setup
run_initial_setup() {
    log_step "Running initial project setup..."
    
    # Create logs directory
    mkdir -p logs
    touch logs/.gitkeep
    
    # Create data directories with sample files
    mkdir -p data/{gleif,corporate,exim,risk,business}
    
    # Create sample data files
    echo '{"sample": "gleif data"}' > data/gleif/sample.json
    echo '{"sample": "corporate data"}' > data/corporate/sample.json
    echo '{"sample": "exim data"}' > data/exim/sample.json
    
    log_success "Initial setup completed"
}

# Generate README
generate_readme() {
    log_step "Generating README documentation..."
    
    cat > README.md << 'EOF'
# ZK-PRET Platform

Zero-Knowledge Privacy-Preserving Enterprise Technology Platform for Compliance Verification

## 🚀 Features

- **Zero-Knowledge Proofs**: Privacy-preserving compliance verification
- **Blockchain Integration**: Mina blockchain for proof verification
- **Enterprise Compliance**: GLEIF, Basel 3, ACTUS framework support
- **Real-time Updates**: WebSocket communication
- **Production Ready**: Comprehensive logging, monitoring, and security

## 🛠️ Quick Start

### Prerequisites

- Node.js 18+
- npm 8+
- Git (optional)

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd zk-pret-platform
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Start development server:
```bash
npm run dev
```

5. Visit http://localhost:3001

### Production Deployment

```bash
npm run build
npm start:prod
```

### Docker Deployment

```bash
docker build -t zk-pret-platform .
docker run -p 3001:3001 zk-pret-platform
```

## 📋 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm test` - Run tests
- `npm run lint` - Lint code

## 🔧 Configuration

Environment variables in `.env`:

- `ZK_PRET_SERVER_PORT` - Server port (default: 3001)
- `ZK_PRET_MCP_SERVER_PATH` - Path to MCP server
- `JWT_SECRET` - JWT secret for authentication
- `LOG_LEVEL` - Logging level

## 📚 API Documentation

### Health Check
```
GET /api/health
```

### Tool Execution
```
POST /api/tools/execute
{
  "toolName": "get-GLEIF-data",
  "parameters": {
    "companyName": "Company Name",
    "typeOfNet": "TESTNET"
  }
}
```

### Compliance Categories

- **GLEIF**: `/api/gleif/*` - Global Legal Entity verification
- **Corporate**: `/api/corporate/*` - Corporate registration verification
- **EXIM**: `/api/exim/*` - Export-Import compliance
- **Business**: `/api/business/*` - Business standards verification
- **Risk**: `/api/risk/*` - Risk assessment and Basel 3

## 🏗️ Architecture

```
src/
├── server.ts          # Main server file
├── client/           # MCP client integration
├── utils/            # Utilities and helpers
├── types/            # TypeScript type definitions
├── config/           # Configuration files
├── middleware/       # Express middleware
└── scripts/          # Build and setup scripts
```

## 🧪 Testing

```bash
npm test                # Run all tests
npm run test:watch     # Watch mode
npm run test:coverage  # Coverage report
```

## 📊 Monitoring

- Health endpoint: `/api/health`
- Metrics endpoint: `/api/metrics`
- Logs: `logs/` directory

## 🛡️ Security

- Helmet.js security headers
- Rate limiting
- Input validation with Zod
- JWT authentication ready

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open pull request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- Documentation: `/docs`
- Issues: GitHub Issues
- Email: support@zkpret.com
EOF
    
    log_success "README documentation generated"
}

# Create setup completion script
create_completion_script() {
    log_step "Creating post-setup script..."
    
    cat > scripts/post-setup.sh << 'EOF'
#!/bin/bash

# Post-setup verification script
echo "🔍 Verifying ZK-PRET Platform setup..."

# Check Node.js
echo "Node.js version: $(node --version)"

# Check if build works
echo "Testing build process..."
npm run build

# Check if server starts
echo "Testing server startup..."
timeout 10s npm start || echo "Server test completed"

# Check if tests pass
echo "Running tests..."
npm test

echo "✅ Setup verification completed!"
echo ""
echo "🚀 Next steps:"
echo "1. Review and update .env configuration"
echo "2. Configure ZK-PRET MCP server path"
echo "3. Start development: npm run dev"
echo "4. Visit http://localhost:3001"
EOF
    
    chmod +x scripts/post-setup.sh
    
    log_success "Post-setup script created"
}

# Main setup function
main() {
    print_banner
    
    log_info "Starting ZK-PRET Platform setup..."
    echo ""
    
    # Get user input
    read -p "Enter project name [$PROJECT_NAME]: " input_name
    PROJECT_NAME=${input_name:-$PROJECT_NAME}
    
    read -p "Enter server port [$DEFAULT_PORT]: " input_port
    DEFAULT_PORT=${input_port:-$DEFAULT_PORT}
    
    echo ""
    log_info "Setting up ZK-PRET Platform: $PROJECT_NAME"
    log_info "Server will run on port: $DEFAULT_PORT"
    echo ""
    
    # Run setup steps
    check_requirements
    create_project_structure
    generate_package_json
    generate_tsconfig
    generate_env_files
    generate_eslint_config
    generate_jest_config
    generate_dockerfile
    generate_github_workflows
    copy_source_files
    install_dependencies
    run_initial_setup
    generate_readme
    create_completion_script
    
    echo ""
    log_success "🎉 ZK-PRET Platform setup completed successfully!"
    echo ""
    echo -e "${GREEN}📁 Project created in: ${PWD}${NC}"
    echo -e "${GREEN}🌐 Server will run on: http://localhost:$DEFAULT_PORT${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. ${YELLOW}cd $PROJECT_NAME${NC}"
    echo -e "  2. ${YELLOW}npm run dev${NC}"
    echo -e "  3. ${YELLOW}Visit http://localhost:$DEFAULT_PORT${NC}"
    echo ""
    echo -e "${BLUE}Optional verification:${NC}"
    echo -e "  ${YELLOW}./scripts/post-setup.sh${NC}"
    echo ""
    echo -e "${PURPLE}🔐 Happy compliance verification with zero-knowledge proofs! 🔐${NC}"
}

# Run main function
main "$@"