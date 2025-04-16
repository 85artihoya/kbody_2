from app import create_app, db
from app.models.user import User

def reset_database():
    app = create_app()
    with app.app_context():
        # 기존 테이블 삭제
        db.drop_all()
        print("Dropped all tables")
        
        # 테이블 재생성
        db.create_all()
        print("Created all tables")
        
        # 트랜잭션 커밋
        db.session.commit()
        print("Database reset completed successfully")

if __name__ == '__main__':
    reset_database() 