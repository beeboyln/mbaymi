#!/bin/bash
# 🚀 Deploy Parcel Photo Feature

echo "📦 Building and deploying to Koyeb..."

# 1. Git commit and push
git add .
git commit -m "🌾 Add parcel profile photos feature - image_url in crops, improved UI"
git push origin main

echo "⏳ Waiting for Koyeb deployment (usually 2-3 minutes)..."
sleep 10

echo ""
echo "✅ Deployment pushed! Now apply the database migration:"
echo ""
echo "Run this command after deployment is live:"
echo ""
echo "curl -X POST 'https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app/admin/migrate?key=dev-key-change-in-prod'"
echo ""
echo "Or access the API docs to test:"
echo "https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app/docs"
