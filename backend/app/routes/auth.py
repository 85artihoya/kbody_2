from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.user import User
from app.utils.auth import (
    generate_user_id,
    create_token,
    validate_user_data
)
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from app.utils.validators import validate_email, validate_password
import jwt
import os
import re

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        print("Login request data:", data)
        
        # 필수 필드 검증
        if 'email' not in data or 'password' not in data:
            return jsonify({'error': 'Email and password are required'}), 400
        
        # 사용자 조회
        user = User.query.filter_by(email=data['email']).first()
        if not user:
            print("User not found with email:", data['email'])
            return jsonify({'error': 'Invalid email or password'}), 401
            
        # 비밀번호 확인
        if not user.check_password(data['password']):
            print("Invalid password for user:", data['email'])
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # JWT 토큰 생성
        token = jwt.encode({
            'user_id': user.id,
            'exp': datetime.utcnow() + timedelta(days=7)
        }, os.getenv('JWT_SECRET_KEY', 'your-secret-key'), algorithm='HS256')
        
        # 사용자 정보 준비
        user_data = {
            'id': str(user.id),
            'email': user.email,
            'name': user.name,
            'gender': user.gender or '미입력',
            'birth_date': user.birth_date.strftime('%Y-%m-%d') if user.birth_date else None,
            'address': user.address or '미입력',
            'detail_address': user.detail_address or '',
            'user_type': user.user_type or 'disabled',
            'disability_type': user.disability_type or '',
            'disability_detail': user.disability_detail or '',
            'gmfcs_level': user.gmfcs_level or '',
            'developmental_type': user.developmental_type or '',
            'other_disability_name': user.other_disability_name or ''
        }
        
        print("Login successful for user:", user_data)
        
        return jsonify({
            'message': 'Login successful',
            'token': token,
            'user': user_data
        }), 200
        
    except Exception as e:
        print("Login error:", str(e))
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        print("Registration request data:", data)

        # 필수 필드 확인
        required_fields = ['email', 'password', 'name', 'gender', 'birth_date', 'address', 'user_type']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400

        # 이메일 형식 검증
        if not re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', data['email']):
            return jsonify({'error': 'Invalid email format'}), 400

        # 비밀번호 강도 검증
        if len(data['password']) < 8:
            return jsonify({'error': 'Password must be at least 8 characters long'}), 400

        # 기존 사용자 확인
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user:
            print("User already exists with email:", data['email'])
            return jsonify({'error': 'Email already registered'}), 400

        # 생년월일 문자열을 datetime 객체로 변환
        try:
            birth_date = datetime.strptime(data['birth_date'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid birth date format. Use YYYY-MM-DD'}), 400

        # 새 사용자 생성
        user_data = {
            'email': data['email'],
            'name': data['name'],
            'gender': data['gender'],
            'birth_date': birth_date,
            'address': data['address'],
            'detail_address': data.get('detail_address'),
            'user_type': data['user_type'],
            'disability_type': data.get('disability_type'),
            'disability_detail': data.get('disability_detail')
        }

        print("Creating new user with data:", user_data)
        new_user = User(**user_data)
        new_user.set_password(data['password'])  # 비밀번호 해싱
        
        try:
            db.session.add(new_user)
            db.session.commit()
            print("User successfully added to database")
            return jsonify({'message': 'User registered successfully'}), 201
        except Exception as e:
            db.session.rollback()
            print("Database error:", str(e))
            return jsonify({'error': 'Database error occurred'}), 500

    except Exception as e:
        print("Registration error:", str(e))
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    current_user = get_jwt_identity()
    user = User.query.get(current_user['id'])
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    # JWT 토큰은 클라이언트에서 삭제해야 함
    return jsonify({'message': 'Successfully logged out'}), 200

@auth_bp.route('/delete-user/<email>', methods=['DELETE'])
def delete_user(email):
    try:
        user = User.query.filter_by(email=email).first()
        if user:
            db.session.delete(user)
            db.session.commit()
            return jsonify({'message': f'User with email {email} deleted successfully'}), 200
        return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500 