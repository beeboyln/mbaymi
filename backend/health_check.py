#!/usr/bin/env python3
"""
Health check script for Mbaymi Backend
Verifies that all components are working correctly
"""

import sys
import requests
from pathlib import Path

def check_database():
    """Check if database connection works"""
    print("\n📊 Checking Database Connection...")
    try:
        from app.database import SessionLocal
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        print("   ✅ Database connection OK")
        return True
    except Exception as e:
        print(f"   ❌ Database error: {e}")
        return False

def check_api():
    """Check if API is running"""
    print("\n🔗 Checking API Endpoints...")
    try:
        response = requests.get("http://localhost:8000/")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ API Running: {data.get('name')}")
            return True
        else:
            print(f"   ❌ API returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("   ❌ Cannot connect to API on localhost:8000")
        print("      Make sure backend is running: python -m uvicorn app.main:app --reload")
        return False
    except Exception as e:
        print(f"   ❌ API error: {e}")
        return False

def check_health():
    """Check health endpoint"""
    print("\n❤️ Checking Health Endpoint...")
    try:
        response = requests.get("http://localhost:8000/health")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Health: {data.get('status')}")
            return True
        else:
            print(f"   ❌ Health returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Health check error: {e}")
        return False

def check_swagger():
    """Check Swagger API docs"""
    print("\n📚 Checking API Documentation...")
    try:
        response = requests.get("http://localhost:8000/docs")
        if response.status_code == 200:
            print("   ✅ Swagger docs available at http://localhost:8000/docs")
            return True
        else:
            print(f"   ❌ Swagger returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Swagger error: {e}")
        return False

def main():
    print("\n" + "="*50)
    print("   🌾 Mbaymi Backend Health Check")
    print("="*50)
    
    checks = {
        "API": check_api(),
        "Health": check_health(),
        "Swagger": check_swagger(),
    }
    
    # Database check requires imports
    try:
        checks["Database"] = check_database()
    except:
        print("\n📊 Checking Database Connection...")
        print("   ⚠️  Database check skipped (run from backend directory)")
    
    print("\n" + "="*50)
    print("   📋 Summary")
    print("="*50)
    
    for check, status in checks.items():
        symbol = "✅" if status else "❌"
        print(f"   {symbol} {check}")
    
    all_pass = all(checks.values())
    
    print("\n" + "="*50)
    if all_pass:
        print("   ✅ All checks passed! Backend is ready.")
        print("   🚀 You can now run Flutter app.")
    else:
        print("   ❌ Some checks failed. See details above.")
        print("   🔧 Make sure backend server is running:")
        print("      python -m uvicorn app.main:app --reload")
    print("="*50 + "\n")
    
    return 0 if all_pass else 1

if __name__ == "__main__":
    sys.exit(main())
