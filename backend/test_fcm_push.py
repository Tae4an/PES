#!/usr/bin/env python3
"""
FCM 푸시 알림 테스트 스크립트

사용법:
1. 백엔드 서버가 실행 중이어야 합니다 (http://localhost:8000)
2. 프론트엔드 앱에서 FCM 토큰을 받아옵니다
3. 이 스크립트에 토큰을 입력하고 실행합니다

python test_fcm_push.py
"""

import requests
import json
from datetime import datetime

# 백엔드 API 기본 URL
BASE_URL = "http://localhost:8000/api/v1"

def test_fcm_status():
    """FCM 서비스 상태 확인"""
    print("\n" + "="*60)
    print("1. FCM 서비스 상태 확인")
    print("="*60)
    
    try:
        response = requests.get(f"{BASE_URL}/fcm/status")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ 상태: {data.get('service_status')}")
            print(f"   FCM 초기화: {data.get('fcm_initialized')}")
            print(f"   Firebase 사용 가능: {data.get('firebase_available')}")
            return data.get('fcm_initialized', False)
        else:
            print(f"❌ 오류: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 연결 실패: {e}")
        return False


def register_fcm_token(fcm_token: str):
    """FCM 토큰 등록"""
    print("\n" + "="*60)
    print("2. FCM 토큰 등록")
    print("="*60)
    
    try:
        payload = {
            "fcm_token": fcm_token,
            "user_id": "test_user",
            "device_type": "mobile",
            "app_version": "1.0.0"
        }
        
        response = requests.post(
            f"{BASE_URL}/fcm/token/register",
            json=payload
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ 토큰 등록 성공")
            print(f"   토큰 ID: {data.get('token_id')}")
            print(f"   메시지: {data.get('message')}")
            return True
        else:
            print(f"❌ 등록 실패: {response.status_code}")
            print(f"   {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 오류: {e}")
        return False


def send_simple_push(fcm_token: str, title: str, body: str, extra_data: dict = None):
    """간단한 푸시 알림 전송"""
    print("\n" + "="*60)
    print("3. 푸시 알림 전송")
    print("="*60)
    
    try:
        payload = {
            "fcm_token": fcm_token,
            "title": title,
            "body": body,
            "priority": "high",
            "channel_id": "default"
        }
        
        if extra_data:
            payload["data"] = extra_data
        
        print(f"\n📤 전송할 내용:")
        print(f"   제목: {title}")
        print(f"   내용: {body}")
        if extra_data:
            print(f"   추가 데이터: {json.dumps(extra_data, ensure_ascii=False, indent=2)}")
        
        response = requests.post(
            f"{BASE_URL}/fcm/send",
            json=payload
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✅ 푸시 알림 전송 성공!")
            print(f"   메시지 ID: {data.get('message_id')}")
            print(f"   전송 시간: {data.get('sent_at')}")
            print(f"\n💡 앱을 확인하여 알림이 수신되었는지 확인하세요!")
            return True
        else:
            print(f"\n❌ 전송 실패: {response.status_code}")
            print(f"   {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 오류: {e}")
        return False


def send_test_notification(fcm_token: str):
    """기본 테스트 알림 전송"""
    print("\n" + "="*60)
    print("4. 테스트 알림 전송 (기존 API)")
    print("="*60)
    
    try:
        payload = {
            "fcm_token": fcm_token,
            "title": "PES 테스트 알림",
            "body": "Firebase 푸시 알림이 정상적으로 작동합니다!"
        }
        
        response = requests.post(
            f"{BASE_URL}/fcm/test/notification",
            json=payload
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ 테스트 알림 전송 성공!")
            print(f"   전송 시간: {data.get('sent_at')}")
            return True
        else:
            print(f"❌ 전송 실패: {response.status_code}")
            print(f"   {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 오류: {e}")
        return False


def main():
    """메인 함수"""
    print("\n")
    print("="*60)
    print("  FCM 푸시 알림 테스트 도구")
    print("="*60)
    
    # 1. FCM 상태 확인
    fcm_ready = test_fcm_status()
    
    if not fcm_ready:
        print("\n⚠️  FCM이 초기화되지 않았습니다.")
        print("   Firebase 서비스 계정 키를 확인하세요.")
        print(f"   경로: backend/credentials/firebase-service-account.json")
        return
    
    # 2. FCM 토큰 입력
    print("\n" + "="*60)
    print("FCM 토큰 입력")
    print("="*60)
    print("💡 프론트엔드 앱에서 FCM 토큰을 복사해서 붙여넣으세요.")
    print("   (앱 실행 시 로그에서 'FCM Token:' 확인)")
    print()
    
    fcm_token = input("FCM 토큰: ").strip()
    
    if not fcm_token:
        print("❌ FCM 토큰이 입력되지 않았습니다.")
        return
    
    print(f"\n✅ 토큰: {fcm_token[:20]}...")
    
    # 3. 토큰 등록
    register_fcm_token(fcm_token)
    
    # 4. 다양한 알림 테스트
    print("\n" + "="*60)
    print("푸시 알림 테스트 시작")
    print("="*60)
    
    # 테스트 1: 기본 알림
    send_simple_push(
        fcm_token=fcm_token,
        title="🚨 긴급 재난 알림",
        body="지진이 발생했습니다. 즉시 안전한 곳으로 대피하세요!"
    )
    
    input("\n⏸️  다음 테스트를 진행하려면 Enter를 누르세요...")
    
    # 테스트 2: 데이터 포함 알림
    send_simple_push(
        fcm_token=fcm_token,
        title="📍 대피소 안내",
        body="가장 가까운 대피소까지 도보 5분 거리입니다.",
        extra_data={
            "screen": "shelter_detail",
            "shelter_id": "12345",
            "distance": "0.5",
            "action": "navigate"
        }
    )
    
    input("\n⏸️  다음 테스트를 진행하려면 Enter를 누르세요...")
    
    # 테스트 3: 재난 행동카드 알림 (기존 API)
    send_test_notification(fcm_token)
    
    print("\n" + "="*60)
    print("✅ 모든 테스트 완료!")
    print("="*60)
    print("\n💡 앱에서 3개의 알림을 받았는지 확인하세요.")
    print("   - 긴급 재난 알림")
    print("   - 대피소 안내 (데이터 포함)")
    print("   - 테스트 알림")
    print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⏹️  테스트 중단됨")
    except Exception as e:
        print(f"\n\n❌ 오류 발생: {e}")

