import uuid
from datetime import datetime, timedelta
from flask_jwt_extended import create_access_token
from app.models.user import User

def generate_user_id():
    return str(uuid.uuid4())

def create_token(user):
    token_data = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'userType': user.user_type
    }
    
    access_token = create_access_token(
        identity=token_data,
        expires_delta=timedelta(days=1)
    )
    
    return {
        'token': access_token,
        'user': user.to_dict()
    }

def validate_user_data(data):
    required_fields = [
        'name', 'email', 'gender', 'birthDate',
        'address', 'password', 'userType'
    ]
    
    for field in required_fields:
        if field not in data or not data[field]:
            return False, f'{field} is required'
    
    if data['userType'] == 'disabled':
        if 'disabilityType' not in data or not data['disabilityType']:
            return False, 'disabilityType is required for disabled users'
        
        if data['disabilityType'] == 'other':
            if 'disabilityDetail' not in data or not data['disabilityDetail']:
                return False, 'disabilityDetail is required for other disability type'
    
    return True, None 