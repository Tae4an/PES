"""
로깅 설정
"""
import logging
import sys
from pythonjsonlogger import jsonlogger
from .config import settings


def setup_logging():
    """로깅 설정 초기화"""
    
    # 로그 포맷 설정
    log_format = '%(asctime)s %(name)s %(levelname)s %(message)s'
    
    # JSON 로거 (프로덕션 환경)
    if not settings.DEBUG:
        logHandler = logging.StreamHandler(sys.stdout)
        formatter = jsonlogger.JsonFormatter(log_format)
        logHandler.setFormatter(formatter)
    else:
        # 개발 환경에서는 일반 포맷
        logHandler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        logHandler.setFormatter(formatter)
    
    # 루트 로거 설정
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, settings.LOG_LEVEL))
    root_logger.addHandler(logHandler)
    
    return root_logger


# 로거 인스턴스
logger = setup_logging()

