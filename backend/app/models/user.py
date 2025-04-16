from datetime import datetime
from app import db
import bcrypt
import uuid
from werkzeug.security import generate_password_hash, check_password_hash

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    birth_date = db.Column(db.Date, nullable=False)
    address = db.Column(db.String(200), nullable=False)
    detail_address = db.Column(db.String(200))
    password_hash = db.Column(db.String(256), nullable=False)
    user_type = db.Column(db.String(20), nullable=False)
    disability_type = db.Column(db.String(20))
    disability_detail = db.Column(db.String(100))
    gmfcs_level = db.Column(db.String(20))
    developmental_type = db.Column(db.String(50))
    other_disability_name = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __init__(self, **kwargs):
        # password를 따로 저장
        password = kwargs.pop('password', None)
        # 나머지 필드들로 부모 클래스 초기화
        super(User, self).__init__(**kwargs)
        # password가 있으면 해시 처리
        if password:
            self.set_password(password)
        # id가 없으면 자동 생성
        if not self.id:
            self.id = str(uuid.uuid4())

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'gender': self.gender,
            'birthDate': self.birth_date.isoformat(),
            'address': self.address,
            'detailAddress': self.detail_address,
            'userType': self.user_type,
            'disabilityType': self.disability_type,
            'disabilityDetail': self.disability_detail,
            'gmfcsLevel': self.gmfcs_level,
            'developmentalType': self.developmental_type,
            'otherDisabilityName': self.other_disability_name,
            'createdAt': self.created_at.isoformat(),
            'updatedAt': self.updated_at.isoformat()
        } 