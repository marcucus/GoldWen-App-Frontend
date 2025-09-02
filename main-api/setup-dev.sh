#!/bin/bash

# GoldWen API Development Setup Script
# This script helps set up the development environment for the GoldWen API

echo "🚀 Setting up GoldWen API Development Environment..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the main-api directory."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Copy environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update the .env file with your actual configuration values"
else
    echo "✅ .env file already exists"
fi

# Build the application
echo "🔨 Building the application..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
npm run test

if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "⚠️  Some tests failed. Please check the errors above."
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update the .env file with your actual configuration values"
echo "2. Set up PostgreSQL and Redis databases"
echo "3. Run 'npm run start:dev' to start the development server"
echo "4. Visit http://localhost:3000/api/v1/docs for API documentation"
echo ""
echo "For production deployment:"
echo "1. Set NODE_ENV=production in your environment"
echo "2. Update all configuration values for production"
echo "3. Run 'npm run build && npm run start:prod'"