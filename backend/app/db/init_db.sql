-- PES 데이터베이스 초기화 스크립트

-- PostGIS 확장 활성화
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(255) UNIQUE NOT NULL,
    fcm_token VARCHAR(512),
    age_group VARCHAR(50),
    mobility VARCHAR(50) DEFAULT '정상',
    is_active BOOLEAN DEFAULT TRUE,
    last_location_update TIMESTAMP,
    location GEOGRAPHY(POINT, 4326),
    admin_region VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST(location);

-- 재난 테이블
CREATE TABLE IF NOT EXISTS disasters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    msg_id VARCHAR(255) UNIQUE NOT NULL,
    disaster_type VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    disaster_area GEOGRAPHY(POLYGON, 4326),
    severity VARCHAR(50),
    issued_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_disasters_msg_id ON disasters(msg_id);
CREATE INDEX IF NOT EXISTS idx_disasters_type ON disasters(disaster_type);
CREATE INDEX IF NOT EXISTS idx_disasters_area ON disasters USING GIST(disaster_area);

-- 대피소 테이블
CREATE TABLE IF NOT EXISTS shelters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address VARCHAR(512) NOT NULL,
    shelter_type VARCHAR(100) NOT NULL,
    capacity INTEGER,
    area_m2 FLOAT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    phone VARCHAR(50),
    operator VARCHAR(255),
    has_parking VARCHAR(10),
    has_generator VARCHAR(10)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_shelters_type ON shelters(shelter_type);
CREATE INDEX IF NOT EXISTS idx_shelters_location ON shelters USING GIST(location);

-- 샘플 대피소 데이터 삽입 (서울 영등포구 기준)
INSERT INTO shelters (name, address, shelter_type, capacity, location, phone, has_parking, has_generator) VALUES
('영등포초등학교', '서울시 영등포구 영등포로 123', '초등학교', 500, ST_GeogFromText('SRID=4326;POINT(126.8962 37.5263)'), '02-1234-5678', '가능', '있음'),
('영등포구민체육센터', '서울시 영등포구 영등포로 234', '체육관', 800, ST_GeogFromText('SRID=4326;POINT(126.9000 37.5280)'), '02-2345-6789', '가능', '있음'),
('영등포도서관', '서울시 영등포구 영등포로 345', '도서관', 300, ST_GeogFromText('SRID=4326;POINT(126.8920 37.5240)'), '02-3456-7890', '불가능', '있음'),
('신길초등학교', '서울시 영등포구 신길로 111', '초등학교', 450, ST_GeogFromText('SRID=4326;POINT(126.9100 37.5150)'), '02-4567-8901', '가능', '있음'),
('당산중학교', '서울시 영등포구 당산로 222', '중학교', 600, ST_GeogFromText('SRID=4326;POINT(126.9020 37.5340)'), '02-5678-9012', '가능', '있음'),
('여의도공원 대피소', '서울시 영등포구 여의도동', '임시대피소', 1000, ST_GeogFromText('SRID=4326;POINT(126.9230 37.5280)'), '02-6789-0123', '가능', '없음'),
('문래청소년수련관', '서울시 영등포구 문래로 333', '수련관', 400, ST_GeogFromText('SRID=4326;POINT(126.8950 37.5180)'), '02-7890-1234', '가능', '있음'),
('영등포구청', '서울시 영등포구 당산로 444', '공공기관', 350, ST_GeogFromText('SRID=4326;POINT(126.8960 37.5260)'), '02-8901-2345', '가능', '있음');

-- 샘플 대피소 데이터 (강남구)
INSERT INTO shelters (name, address, shelter_type, capacity, location, phone, has_parking, has_generator) VALUES
('대치초등학교', '서울시 강남구 대치동 123', '초등학교', 550, ST_GeogFromText('SRID=4326;POINT(127.0632 37.4945)'), '02-1111-2222', '가능', '있음'),
('강남구민체육센터', '서울시 강남구 역삼동 234', '체육관', 900, ST_GeogFromText('SRID=4326;POINT(127.0360 37.5000)'), '02-2222-3333', '가능', '있음'),
('역삼중학교', '서울시 강남구 역삼로 345', '중학교', 650, ST_GeogFromText('SRID=4326;POINT(127.0380 37.5010)'), '02-3333-4444', '가능', '있음');

-- 뷰 생성 (활성 사용자)
CREATE OR REPLACE VIEW active_users AS
SELECT * FROM users
WHERE is_active = TRUE
  AND last_location_update >= NOW() - INTERVAL '1 hour';

-- 함수: 사용자와 대피소 간 거리 계산
CREATE OR REPLACE FUNCTION calculate_distance_to_shelter(
    user_lat FLOAT,
    user_lng FLOAT,
    shelter_id UUID
) RETURNS FLOAT AS $$
DECLARE
    distance_km FLOAT;
BEGIN
    SELECT ST_Distance(
        ST_GeogFromText('SRID=4326;POINT(' || user_lng || ' ' || user_lat || ')'),
        location
    ) / 1000.0 INTO distance_km
    FROM shelters
    WHERE id = shelter_id;
    
    RETURN distance_km;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE users IS '사용자 정보 (세션 단위)';
COMMENT ON TABLE disasters IS '재난 정보';
COMMENT ON TABLE shelters IS '대피소 정보';

