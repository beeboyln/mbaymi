"""Test accept/reject authorization workflow"""
import requests
import json

BASE_URL = "http://localhost:8000/api"

# Test data - using existing accounts
FARMER_EMAIL = "farmer@test.com"
FARMER_PASSWORD = "password123"
VET_EMAIL = "vet@test.com"
VET_PASSWORD = "password123"

def login(email: str, password: str) -> str:
    """Login and return token"""
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": password}
    )
    if response.status_code == 200:
        data = response.json()
        return data.get('access_token')
    else:
        print(f"Login failed: {response.status_code}")
        print(response.text)
        return None

def get_pending_authorizations(vet_token: str) -> list:
    """Get pending authorizations for veterinarian"""
    headers = {"Authorization": f"Bearer {vet_token}"}
    response = requests.get(
        f"{BASE_URL}/authorizations/pending",
        headers=headers
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Get pending failed: {response.status_code}")
        print(response.text)
        return []

def accept_authorization(vet_token: str, auth_id: int) -> dict:
    """Accept an authorization request"""
    headers = {"Authorization": f"Bearer {vet_token}"}
    response = requests.post(
        f"{BASE_URL}/authorizations/{auth_id}/accept",
        headers=headers
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Accept failed: {response.status_code}")
        print(response.text)
        return {}

def reject_authorization(vet_token: str, auth_id: int) -> dict:
    """Reject an authorization request"""
    headers = {"Authorization": f"Bearer {vet_token}"}
    response = requests.post(
        f"{BASE_URL}/authorizations/{auth_id}/reject",
        headers=headers
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Reject failed: {response.status_code}")
        print(response.text)
        return {}

def get_accepted_authorizations(vet_token: str, vet_id: int) -> list:
    """Get accepted authorizations for veterinarian"""
    headers = {"Authorization": f"Bearer {vet_token}"}
    response = requests.get(
        f"{BASE_URL}/authorizations/veterinarian/{vet_id}",
        headers=headers
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Get accepted failed: {response.status_code}")
        print(response.text)
        return []

def main():
    print("=== Authorization Accept/Reject Test ===\n")
    
    # Login as vet
    print("1. Logging in as veterinarian...")
    vet_token = login(VET_EMAIL, VET_PASSWORD)
    if not vet_token:
        print("Failed to login as vet!")
        return
    print(f"✓ Vet token obtained: {vet_token[:20]}...\n")
    
    # Get pending authorizations
    print("2. Getting pending authorizations...")
    pending = get_pending_authorizations(vet_token)
    print(f"Found {len(pending)} pending authorizations")
    
    if not pending:
        print("No pending authorizations to test with!")
        return
    
    pending_auth = pending[0]
    auth_id = pending_auth['id']
    farm_name = pending_auth.get('farm', {}).get('name', 'Unknown')
    print(f"First pending: ID={auth_id}, Farm={farm_name}, Status={pending_auth.get('status')}\n")
    
    # Accept the authorization
    print(f"3. Accepting authorization {auth_id}...")
    accepted = accept_authorization(vet_token, auth_id)
    if accepted:
        print(f"✓ Accepted! Status={accepted.get('status')}\n")
    else:
        print("✗ Failed to accept!\n")
        return
    
    # Get accepted authorizations
    print("4. Getting accepted authorizations...")
    # First, we need to get the vet's ID - we'll extract it from the accepted response or from the token
    # For now, let's try to get accepted auths (need vet_id)
    
    # Let's check pending again - should be empty now
    pending_after = get_pending_authorizations(vet_token)
    print(f"Pending after accept: {len(pending_after)} items (should be {len(pending)-1})")
    
    # Try to get accepted from the second pending auth if it exists
    if len(pending) > 1:
        print(f"\n5. Testing reject on another authorization...")
        second_auth = pending[1]
        second_auth_id = second_auth['id']
        print(f"Rejecting authorization {second_auth_id}...")
        
        rejected = reject_authorization(vet_token, second_auth_id)
        if rejected:
            print(f"✓ Rejected! Status={rejected.get('status')}\n")
        else:
            print("✗ Failed to reject!\n")
        
        # Check pending again
        pending_final = get_pending_authorizations(vet_token)
        print(f"Pending after reject: {len(pending_final)} items (should be {len(pending)-2})")
    
    print("\n=== Test Complete ===")

if __name__ == "__main__":
    main()
