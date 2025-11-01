#!/usr/bin/env python3
"""
간단한 FCM 푸시 알림 전송 스크립트

빠르게 푸시 알림을 보낼 때 사용합니다.
"""

import requests
import sys

# 설정
BASE_URL = "http://localhost:8000/api/v1/fcm"

def send_push(token: str, title: str, body: str, data: dict = None):
    """푸시 알림 전송"""
    url = f"{BASE_URL}/send"
    
    payload = {
        "fcm_token": token,
        "title": title,
        "body": body,
        "priority": "high",
        "channel_id": "default"
    }
    
    if data:
        payload["data"] = data
    
    try:
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ 푸시 알림 전송 성공!")
            print(f"   Message ID: {result.get('message_id')}")
            print(f"   전송 시간: {result.get('sent_at')}")
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
    if len(sys.argv) < 4:
        print("사용법:")
        print(f"  python {sys.argv[0]} <FCM_TOKEN> <TITLE> <BODY>")
        print()
        print("예시:")
        print(f"  python {sys.argv[0]} 'dA1B2...' '긴급 알림' '지진이 발생했습니다!'")
        sys.exit(1)
    
    token = sys.argv[1]
    title = sys.argv[2]
    body = sys.argv[3]
    
    print(f"\n📤 푸시 알림 전송 중...")
    print(f"   제목: {title}")
    print(f"   내용: {body}")
    print(f"   토큰: {token[:20]}...\n")
    
    send_push(token, title, body)


if __name__ == "__main__":
    main()

