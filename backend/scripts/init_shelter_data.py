"""
대피소 데이터 초기화 스크립트 (SQL 파일 기반)
1. shelters.sql 파일 실행
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.session import ShelterAsyncSessionLocal
from sqlalchemy import text


async def main():
    """대피소 데이터 초기화"""
    
    print("=" * 70)
    print("🏗️  대피소 데이터 초기화")
    print("=" * 70)
    
    sql_path = Path(__file__).parent.parent / "app" / "data" / "shelters.sql"
    
    if not sql_path.exists():
        print(f"❌ SQL 파일을 찾을 수 없습니다: {sql_path}")
        return
    
    print(f"\n📄 SQL 파일: {sql_path.name}")
    print(f"📦 크기: {sql_path.stat().st_size / 1024:.1f} KB")
    
    # 사용자 확인
    response = input("\n대피소 테이블을 생성하고 데이터를 삽입하시겠습니까? (y/N): ")
    if response.lower() != 'y':
        print("취소되었습니다.")
        return
    
    async with ShelterAsyncSessionLocal() as db:
        try:
            print("\n⏳ SQL 파일 실행 중...")
            
            # SQL 파일 읽기
            sql_content = sql_path.read_text(encoding='utf-8')
            
            # 불필요한 부분 제거
            lines = []
            skip_sections = [
                '\\restrict',
                '\\unrestrict',
                '\\encoding',
                '\\connect',
                'SET statement_timeout',
                'SET lock_timeout',
                'SET idle_in_transaction',
                'SET transaction_timeout',
                'SET client_encoding',
                'SET standard_conforming_strings',
                'SELECT pg_catalog.set_config',
                'SET check_function_bodies',
                'SET xmloption',
                'SET client_min_messages',
                'SET row_security',
                'CREATE DATABASE',
                'ALTER DATABASE',
                'TOC entry'
            ]
            
            for line in sql_content.split('\n'):
                # 주석 및 불필요한 라인 건너뛰기
                if any(skip in line for skip in skip_sections):
                    continue
                if line.strip().startswith('--') and 'TOC' not in line:
                    continue
                lines.append(line)
            
            cleaned_sql = '\n'.join(lines)
            
            # UUID 확장 활성화
            print("  ⚙️  UUID 확장 활성화...")
            await db.execute(text('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'))
            await db.commit()
            
            # 기존 테이블 확인
            result = await db.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'shelters'
                )
            """))
            table_exists = result.scalar()
            
            if table_exists:
                result = await db.execute(text("SELECT COUNT(*) FROM shelters"))
                existing_count = result.scalar()
                print(f"\n  ⚠️  기존 shelters 테이블 발견 (데이터: {existing_count}개)")
                
                drop_response = input("  기존 테이블을 삭제하고 새로 생성하시겠습니까? (y/N): ")
                if drop_response.lower() == 'y':
                    print("  🗑️  기존 테이블 삭제 중...")
                    await db.execute(text("DROP TABLE IF EXISTS shelters CASCADE"))
                    await db.commit()
                else:
                    print("취소되었습니다.")
                    return
            
            # SQL 실행 (세미콜론으로 분리)
            statements = [s.strip() for s in cleaned_sql.split(';') if s.strip()]
            
            total = len(statements)
            executed = 0
            
            print(f"\n  📝 {total}개 SQL 구문 실행 중...")
            
            for idx, statement in enumerate(statements, 1):
                if not statement or len(statement) < 10:
                    continue
                
                try:
                    await db.execute(text(statement))
                    executed += 1
                    
                    # 진행 상황 표시 (10%마다)
                    if idx % max(1, total // 10) == 0:
                        progress = (idx / total) * 100
                        print(f"  ⏳ 진행: {progress:.0f}% ({idx}/{total})")
                
                except Exception as e:
                    error_msg = str(e)
                    # 이미 존재하는 객체는 무시
                    if 'already exists' in error_msg or 'duplicate' in error_msg.lower():
                        continue
                    # INSERT 실패는 로깅만
                    if 'INSERT' in statement[:50].upper():
                        print(f"  ⚠️  INSERT 실패 (계속 진행): {error_msg[:50]}...")
                        continue
                    # 그 외 오류는 출력
                    print(f"  ⚠️  경고: {error_msg[:100]}...")
            
            await db.commit()
            
            # 결과 확인
            print("\n  🔍 결과 확인 중...")
            
            result = await db.execute(text("SELECT COUNT(*) FROM shelters"))
            total_count = result.scalar()
            
            result = await db.execute(text("""
                SELECT shelter_type, COUNT(*) as count
                FROM shelters
                GROUP BY shelter_type
                ORDER BY count DESC
            """))
            type_stats = result.fetchall()
            
            print("\n" + "=" * 70)
            print("✅ 완료")
            print("=" * 70)
            print(f"SQL 구문 실행: {executed}/{total}개")
            print(f"대피소 데이터: {total_count}개")
            print()
            print("📊 유형별 통계:")
            
            emoji_map = {
                '지진대피소': '🌊',
                '해일대피소': '🌀',
                '민방위대피소': '⚔️',
                '기타대피소': '📦'
            }
            
            for row in type_stats:
                shelter_type, count = row
                emoji = emoji_map.get(shelter_type, '📦')
                percentage = (count / total_count * 100) if total_count > 0 else 0
                print(f"  {emoji} {shelter_type:15s}: {count:3d}개 ({percentage:5.1f}%)")
            print()
            
        except Exception as e:
            print(f"\n❌ 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            await db.rollback()
        finally:
            await db.close()


if __name__ == "__main__":
    asyncio.run(main())