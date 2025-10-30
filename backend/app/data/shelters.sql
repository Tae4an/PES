--
-- PostgreSQL database dump
--

\restrict Jv8j8AZZRnwL7gxxAACa7KlHUgYlgubF0g3REouy5dEZNYORDAv7bpdKRwN2X6B

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

-- Started on 2025-10-30 20:43:27

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5828 (class 1262 OID 16388)
-- Name: pes-db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "pes-db" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Korean_Korea.949';


ALTER DATABASE "pes-db" OWNER TO postgres;

\unrestrict Jv8j8AZZRnwL7gxxAACa7KlHUgYlgubF0g3REouy5dEZNYORDAv7bpdKRwN2X6B
\encoding SQL_ASCII
\connect -reuse-previous=on "dbname='pes-db'"
\restrict Jv8j8AZZRnwL7gxxAACa7KlHUgYlgubF0g3REouy5dEZNYORDAv7bpdKRwN2X6B

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 17480)
-- Name: shelters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shelters (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    address character varying(512) NOT NULL,
    shelter_type character varying(100) NOT NULL,
    capacity integer,
    area_m2 double precision,
    phone character varying(50),
    operator character varying(255),
    has_parking character varying(10),
    has_generator character varying(10),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    latitude double precision,
    longitude double precision,
    description text
);


ALTER TABLE public.shelters OWNER TO postgres;

--
-- TOC entry 5829 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE shelters; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.shelters IS '재난 발생 시 시민들이 대피할 수 있는 대피소 정보를 저장하는 테이블';


--
-- TOC entry 5830 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.id IS '대피소 고유 식별자 (UUID 형식, 자동 생성)';


--
-- TOC entry 5831 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.name IS '대피소 시설명 (예: 제주중앙초등학교, 제주체육관)';


--
-- TOC entry 5832 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.address IS '대피소 도로명 주소 (공공데이터포털에서 제공)';


--
-- TOC entry 5833 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.shelter_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.shelter_type IS '대피소 유형 분류 (민방위대피소, 지진대피소, 지진옥외대피소, 초등학교, 중학교, 고등학교, 체육관 등)';


--
-- TOC entry 5834 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.capacity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.capacity IS '최대 수용 가능 인원 수 (단위: 명, NULL 허용)';


--
-- TOC entry 5835 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.area_m2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.area_m2 IS '대피소 총 면적 (단위: 제곱미터, NULL 허용)';


--
-- TOC entry 5836 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.phone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.phone IS '대피소 담당자 또는 운영기관 연락처 (예: 064-123-4567)';


--
-- TOC entry 5837 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.operator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.operator IS '대피소 운영 및 관리 기관 (예: 제주시청, 서귀포시청, 교육청)';


--
-- TOC entry 5838 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.has_parking; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.has_parking IS '주차 시설 보유 여부 (가능/불가능/미확인, NULL 허용)';


--
-- TOC entry 5839 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.has_generator; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.has_generator IS '비상 발전기 보유 여부 (있음/없음/미확인, NULL 허용)';


--
-- TOC entry 5840 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.created_at IS '데이터 최초 생성 시각 (자동 기록)';


--
-- TOC entry 5841 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN shelters.updated_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shelters.updated_at IS '데이터 최종 수정 시각 (자동 기록)';


--
-- TOC entry 5822 (class 0 OID 17480)
-- Dependencies: 224
-- Data for Name: shelters; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.shelters VALUES ('6b45b405-c571-469b-a590-0f7d03c00e6c', '신길온천역 지하보도', '경기 안산시 단원구 황고개로 2', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:29.50657', '2025-10-30 10:26:29.50657', 37.3382991, 126.7656674, '민방위 대피소 : 신길온천역 지하보도 (4호선)');
INSERT INTO public.shelters VALUES ('42d74d6a-e3b6-427f-9d9f-647ad5442c3e', '민방위교육장', '경기도 안산시 상록구 예술광장1로 32(월피동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3296335, 126.8458829, '민방위 대피소 : 민방위교육장');
INSERT INTO public.shelters VALUES ('9a7a11ac-b3be-4fff-ad98-90379c9b20ef', 'e편한세상 선부 파크플레이스', '경기도 안산시 경기도 안산시 단원구 선부광장남로 63', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3284182, 126.8084632, '민방위 대피소 : e편한세상 선부 파크플레이스');
INSERT INTO public.shelters VALUES ('42b2499e-1bff-439f-81be-b2dc0843e48d', 'e편한세상 선부 어반스퀘어', '경기도 안산시 경기도 안산시 단원구 선부광장서로 42', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3335371, 126.8054544, '민방위 대피소 : e편한세상 선부 어반스퀘어');
INSERT INTO public.shelters VALUES ('6e8bbf1f-6176-4b42-a029-f36fd76e18b9', '초지역메이저타운푸르지오에코', '경기도 안산시 단원구 원선1로 10 (원곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3239689, 126.8033356, '민방위 대피소 : 초지역메이저타운푸르지오에코');
INSERT INTO public.shelters VALUES ('6105fb94-b319-4ece-b6b4-3c43afd0b926', '초지역 지하보도', '경기 안산시 단원구 중앙대로 620', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:30.957871', '2025-10-30 10:26:30.957871', 37.3209848, 126.8056155, '민방위 대피소 : 초지역 지하보도 (4호선)');
INSERT INTO public.shelters VALUES ('0ab58bf8-738d-4fcf-b7c6-1ba205b4e2fd', '더헤븐CC', '경기도 안산시 단원구 대선로 466 (대부남동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.232511, 126.5629005, '민방위 대피소 : 더헤븐CC');
INSERT INTO public.shelters VALUES ('21512860-8e81-4e36-9261-6e4d43180f2d', '행복한마을아파트', '경기도 안산시 단원구 초지1로 78(초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3015708, 126.8160743, '민방위 대피소 : 행복한마을아파트');
INSERT INTO public.shelters VALUES ('45b88d22-1265-4b8f-810c-2a24eb925d1a', '중앙역 지하보도', '경기 안산시 단원구 중앙대로 918', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:32.408104', '2025-10-30 10:26:32.408104', 37.3160488, 126.8382004, '민방위 대피소 : 중앙역 지하보도 (4호선)');
INSERT INTO public.shelters VALUES ('30ec7c16-a8be-41d5-82e2-82959d2ddca4', '그랑시티자이2차아파트', '경기도 안산시 상록구 해양5로 17 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2798738, 126.8319834, '민방위 대피소 : 그랑시티자이2차아파트');
INSERT INTO public.shelters VALUES ('bd3f86e0-f67b-4385-ad28-58271015e44a', '한대앞역 지하보도', '경기 안산시 상록구 충장로 337', '민방위대피소', 5000, NULL, '1666-1234', '안산시 상록구', NULL, NULL, '2025-10-30 10:26:33.899937', '2025-10-30 10:26:33.899937', 37.309805, 126.8537837, '민방위 대피소 : 한대앞역 지하보도 (4호선)');
INSERT INTO public.shelters VALUES ('f0777898-f5c6-4521-b5d9-3f13abc20541', '상록수역 지하보도', '경기 안산시 상록구 상록수로 61', '민방위대피소', 5000, NULL, '1666-1234', '안산시 상록구', NULL, NULL, '2025-10-30 10:26:35.345162', '2025-10-30 10:26:35.345162', 37.3028106, 126.865925, '민방위 대피소 : 상록수역 지하보도 (4호선)');
INSERT INTO public.shelters VALUES ('01187b9f-0083-4f2c-bb4e-677eba4ad85d', '반월역 지하보도', '경기 안산시 상록구 건건로 119-10', '민방위대피소', 5000, NULL, '1666-1234', '안산시 상록구', NULL, NULL, '2025-10-30 10:26:36.780848', '2025-10-30 10:26:36.780848', 37.3120754, 126.9035659, '민방위 대피소 : 반월역 지하보도 (수인선)');
INSERT INTO public.shelters VALUES ('c5a9a1e5-3c09-4dcc-9fa9-fdb105a0fa3e', '천년가리더스카이아파트', '경기도 안산시 단원구 와동로 125 (와동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3409577, 126.8251984, '민방위 대피소 : 천년가리더스카이아파트');
INSERT INTO public.shelters VALUES ('36ac020f-5f7c-42e9-b3a2-fb3c42559854', '사리역 지하보도', '경기 안산시 상록구 충장로 103', '민방위대피소', 5000, NULL, '1666-1234', '안산시 상록구', NULL, NULL, '2025-10-30 10:26:38.189255', '2025-10-30 10:26:38.189255', 37.2917336, 126.8573823, '민방위 대피소 : 사리역 지하보도 (수인선)');
INSERT INTO public.shelters VALUES ('6223f1ca-5a67-4420-8f1a-434a8cfecf96', '원시역 지하보도', '경기 안산시 단원구 산단로 70', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:39.653496', '2025-10-30 10:26:39.653496', 37.31013009999999, 126.7885157, '민방위 대피소 : 원시역 지하보도 (수인선)');
INSERT INTO public.shelters VALUES ('155c5ca0-f03d-4149-aa97-75db7f591f20', '현대1차아파트', '경기도 안산시 상록구 감골1로 43 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2890698, 126.8501454, '민방위 대피소 : 현대1차아파트');
INSERT INTO public.shelters VALUES ('142434ad-2f26-4670-b51c-0b5a15c4d602', '건건동 대림아파트 주차장', '경기도 안산시 상록구 건건8길 2 (건건동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3108665, 126.906137, '민방위 대피소 : 건건동 대림아파트 주차장');
INSERT INTO public.shelters VALUES ('144226c9-2070-405f-8da8-20350c763bd1', '한화꿈에그린 아파트 지하주차장', '경기도 안산시 단원구 원선1로 37(원곡동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3268998, 126.8027287, '민방위 대피소 : 한화꿈에그린 아파트 지하주차장');
INSERT INTO public.shelters VALUES ('162324ee-655f-446d-857a-dcaeb3e885cd', '안산공업고등학교', '경기도 안산시 상록구 안산공고로 51(부곡동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.336275, 126.8605842, '민방위 대피소 : 안산공업고등학교');
INSERT INTO public.shelters VALUES ('22e38121-14dd-4f11-b09a-26f2f5962ac0', '안산강서고등학교(본관 지하 1층)', '경기도 안산시 단원구 삼일로 367 (와동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3345319, 126.8182632, '민방위 대피소 : 안산강서고등학교(본관 지하 1층)');
INSERT INTO public.shelters VALUES ('6a27d20b-05b5-4d72-a79f-69d919fccd69', '힐스테이트중앙아파트 지하주차장 전체(지하 1층~2층)', '경기도 안산시 단원구 고잔로 81 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.319978, 126.8352205, '민방위 대피소 : 힐스테이트중앙아파트 지하주차장 전체(지하 1층~2층)');
INSERT INTO public.shelters VALUES ('708f51bd-6952-4215-bbef-76fd5cc78a0b', '본원초등학교', '경기도 안산시 상록구 샘골로 83 (본오동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2911681, 126.8619836, '민방위 대피소 : 본원초등학교');
INSERT INTO public.shelters VALUES ('815a29c6-7a1b-445b-bdda-5e62ca89b0a2', '뉴라성관관호텔', '경기도 안산시 상록구 상록수로 34 (본오동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.30210470000001, 126.8637773, '민방위 대피소 : 뉴라성관관호텔');
INSERT INTO public.shelters VALUES ('8169db29-ce3b-4279-991d-62f240532015', '엘리지움2차아파트(지하주차장)', '경기도 안산시 상록구 네고지2길 47 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2947416, 126.8529842, '민방위 대피소 : 엘리지움2차아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('853f17c7-4077-49c1-922e-054676624bc6', '두산아파트 지하주차장(101동앞)', '경기도 안산시 단원구 새뿔길 42 (신길동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3365647, 126.7753133, '민방위 대피소 : 두산아파트 지하주차장(101동앞)');
INSERT INTO public.shelters VALUES ('929c1501-b2ea-4c71-8dd3-aa6860009f92', '센트럴푸르지오 아파트(안산)', '경기도 안산시 단원구 고잔로 115 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3197599, 126.8389936, '민방위 대피소 : 센트럴푸르지오 아파트(안산)');
INSERT INTO public.shelters VALUES ('957c7838-9e13-4497-9131-d65d29a0b6cd', '엘리지움아파트(지하1층~4층 주차장)', '경기도 안산시 상록구 석호로 204 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2947987, 126.8534569, '민방위 대피소 : 엘리지움아파트(지하1층~4층 주차장)');
INSERT INTO public.shelters VALUES ('9722d7b7-5fdd-4790-bb09-7f417ecb51f2', '웰플렉스(안산상록수우체국)', '경기도 안산시 상록구 용신로 364 (본오동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3014898, 126.8623457, '민방위 대피소 : 웰플렉스(안산상록수우체국)');
INSERT INTO public.shelters VALUES ('b7b3c72b-a724-475b-bc2a-367521ed0684', '시우역 지하보도', '경기 안산시 단원구 동산로 50', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:41.126665', '2025-10-30 10:26:41.126665', 37.3132797, 126.7962774, '민방위 대피소 : 시우역 지하보도 (수인선)');
INSERT INTO public.shelters VALUES ('04cecac4-f8d2-4534-bda4-d89109f4d9fb', '선부역 지하보도', '경기 안산시 단원구 선부광장로 68', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:42.57906', '2025-10-30 10:26:42.57906', 37.3337983, 126.8091129, '민방위 대피소 : 선부역 지하보도 (수인선)');
INSERT INTO public.shelters VALUES ('65409985-0df0-40a1-a3b1-20178c3012f4', '달미역 지하보도', '경기 안산시 단원구 순환로 160', '민방위대피소', 5000, NULL, '1666-1234', '안산시 단원구', NULL, NULL, '2025-10-30 10:26:44.027929', '2025-10-30 10:26:44.027929', 37.3456915, 126.8187206, '민방위 대피소 : 달미역 지하보도 (수인선)');
INSERT INTO public.shelters VALUES ('27943224-8ca1-4769-87c0-b1e3faa24ad0', '초지역메이저타운푸르지오메트로', '경기도 안산시 단원구 화랑로 170(초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3223059, 126.8066239, '민방위 대피소 : 초지역메이저타운푸르지오메트로');
INSERT INTO public.shelters VALUES ('1142d5bf-bdaa-49d5-975a-e2a8d32ce8e4', '그린빌13단지', '경기도 안산시 단원구 광덕2로 17(초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3117095, 126.8132303, '민방위 대피소 : 그린빌13단지');
INSERT INTO public.shelters VALUES ('7a8f8ab4-f5e2-4e2d-b8b0-ee0f0d49cc3d', '그린빌14단지', '경기도 안산시 단원구 광덕2로 32(초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3102212, 126.8256889, '민방위 대피소 : 그린빌14단지');
INSERT INTO public.shelters VALUES ('a4604c39-85dd-4f00-a18e-5469226b81dc', '그린빌12단지', '경기도 안산시 단원구 광덕2로 74(초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3102212, 126.8256889, '민방위 대피소 : 그린빌12단지');
INSERT INTO public.shelters VALUES ('ae90189e-e640-4be6-ba1d-67b3a4d9be13', '그린빌11단지', '경기도 안산시 단원구 화정천서로 161(초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3115031, 126.818896, '민방위 대피소 : 그린빌11단지');
INSERT INTO public.shelters VALUES ('c0db8aa7-41bb-4919-a4be-a807a4710a18', '명휘원', '경기도 안산시 상록구 해안로 865 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.2839128, 126.8403258, '민방위 대피소 : 명휘원');
INSERT INTO public.shelters VALUES ('027cf95d-ca71-45f3-8277-d9c815c276bd', '부곡교회', '경기도 안산시 상록구 성호로 352 (부곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3339288, 126.8622987, '민방위 대피소 : 부곡교회');
INSERT INTO public.shelters VALUES ('a1bac557-cb70-449f-bce2-446fa3de3d2f', '부암교회', '경기도 안산시 상록구 태마당로 48 (부곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3318922, 126.8641227, '민방위 대피소 : 부암교회');
INSERT INTO public.shelters VALUES ('f2fdcf84-c39c-471c-bc6d-220e847aa34a', '상록수명륜교회', '경기도 안산시 상록구 세류로 16 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.2853183, 126.8615512, '민방위 대피소 : 상록수명륜교회');
INSERT INTO public.shelters VALUES ('329ca915-bd83-4f94-ba20-168c2ae7a4b3', '그랑시티자이1차아파트', '경기도 안산시 상록구 해양4로 31 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.282651, 126.8302544, '민방위 대피소 : 그랑시티자이1차아파트');
INSERT INTO public.shelters VALUES ('331614cd-5369-44d5-891c-fc8ee6ecb157', '본오주공아파트', '경기도 안산시 상록구 본삼로 8 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.300371, 126.8612018, '민방위 대피소 : 본오주공아파트');
INSERT INTO public.shelters VALUES ('3bb87ada-796b-4203-9523-5a3bab815b46', '현대2차아파트', '경기도 안산시 상록구 감골2로 12 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2913819, 126.8544848, '민방위 대피소 : 현대2차아파트');
INSERT INTO public.shelters VALUES ('16cd32ed-4a13-4f6c-aafa-e0060500b7a2', '안산 롯데캐슬 더 퍼스트', '경기도 안산시 단원구 원초로 61(초지동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.327521, 126.8056067, '민방위 대피소 : 안산 롯데캐슬 더 퍼스트');
INSERT INTO public.shelters VALUES ('2ae60914-e633-4413-87d1-e6400df9888f', '고잔1차푸르지오아파트(지하주차장)', '경기도 안산시 단원구 광덕동로 26 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3062471, 126.8340192, '민방위 대피소 : 고잔1차푸르지오아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('2ae874ea-9e23-45e0-a410-0bfd15d7bb0a', '융보연립단지 지하주차장', '경기도 안산시 단원구 와동로1길 15 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3322858, 126.8253012, '민방위 대피소 : 융보연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('2b7b32a5-2197-44f4-b61f-11db5dbb792f', '창동2차 연립단지 지하주차장', '경기도 안산시 단원구 와동로 5 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3319937, 126.8258506, '민방위 대피소 : 창동2차 연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('340f2544-fe42-40b8-b1a6-dc9cb3d0f25a', '신유7차 연립단지 지하주차장', '경기도 안산시 단원구 화정로안길 35 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3333163, 126.8209153, '민방위 대피소 : 신유7차 연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('3e7a7fe6-0510-41bb-aa99-2ce4c817efb3', '안산레이크타운푸르지오(지하주차장)', '경기도 안산시 단원구 광덕동로 25 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3058085, 126.8311489, '민방위 대피소 : 안산레이크타운푸르지오(지하주차장)');
INSERT INTO public.shelters VALUES ('97337c49-f683-415b-9908-dbaa2631a009', '이호초등학교', '경기도 안산시 상록구 고목로3길 44 (본오동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2865229, 126.8604562, '민방위 대피소 : 이호초등학교');
INSERT INTO public.shelters VALUES ('9b95c567-d016-476e-bc0a-bcbc96e79e55', '안산파크푸르지오', '경기도 안산시 상록구 화랑로 534 (성포동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.319367, 126.8475344, '민방위 대피소 : 안산파크푸르지오');
INSERT INTO public.shelters VALUES ('aa0b7c18-1cd4-4ee1-b02f-4984339a1102', '초지역메이저타운푸르지오파크아파트 지하주차장(지하1~3층)', '경기도 안산시 단원구 원초로 90 (초지동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3243053, 126.8074291, '민방위 대피소 : 초지역메이저타운푸르지오파크아파트 지하주차장(지하1~3층)');
INSERT INTO public.shelters VALUES ('bb3a2061-3c9a-47c5-9ff0-e6ebde4a4349', '호수마을아파트 지하주차장(전체)(초지동)', '경기도 안산시 단원구 광덕1로 80 (초지동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.305865, 126.8182928, '민방위 대피소 : 호수마을아파트 지하주차장(전체)(초지동)');
INSERT INTO public.shelters VALUES ('bbf575c1-ebf6-4062-8d96-a6e342ac7bfe', '공작한양아파트 지하주차장', '경기도 안산시 단원구 선부로 166 (선부동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3400907, 126.8128515, '민방위 대피소 : 공작한양아파트 지하주차장');
INSERT INTO public.shelters VALUES ('356ac36d-cae7-4668-9b89-a32d7042f0f3', '올림포스보노피아', '경기도 안산시 상록구 감골2로 47 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.2903588, 126.849618, '민방위 대피소 : 올림포스보노피아');
INSERT INTO public.shelters VALUES ('d9ac863a-0a55-46b7-bf75-b7fb4343c107', '상록수 성당 별관', '경기도 안산시 상록구 이호로 130 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.2882852, 126.8704799, '민방위 대피소 : 상록수 성당 별관');
INSERT INTO public.shelters VALUES ('97a91bd4-5df4-4b45-8ae5-79f8b6cbdb7e', '본오교회', '경기도 안산시 상록구 본오로 6 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.285545, 126.8663679, '민방위 대피소 : 본오교회');
INSERT INTO public.shelters VALUES ('49e45ba9-f0b1-4f28-9df8-9537cf19c051', '성문교회(지하)', '경기도 안산시 단원구 관산2길 27 (원곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3309433, 126.7971615, '민방위 대피소 : 성문교회(지하)');
INSERT INTO public.shelters VALUES ('a705e315-90e3-412d-a9fd-55e704be812a', '안산역 지하보도', '경기도 안산시 단원구 중앙대로 462 (원곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.3249383, 126.7945674, '민방위 대피소 : 안산역 지하보도');
INSERT INTO public.shelters VALUES ('4af2b455-fa8f-4a15-bd11-1cf4c81f1e81', '예누림아파트', '경기도 안산시 상록구 감골2로 11 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2901403, 126.8540154, '민방위 대피소 : 예누림아파트');
INSERT INTO public.shelters VALUES ('732f16d2-a020-4f2c-be7d-4e17520fbad1', '보성프라자', '경기도 안산시 단원구 원초로 30 (원곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3283596, 126.801763, '민방위 대피소 : 보성프라자');
INSERT INTO public.shelters VALUES ('7a56212d-e0ee-4f87-8f10-2723a49433fb', '휴먼시아2단지(지하주차장)', '경기도 안산시 단원구 삼일로 13 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3347322, 126.7790203, '민방위 대피소 : 휴먼시아2단지(지하주차장)');
INSERT INTO public.shelters VALUES ('7cd035a4-9ad5-4d28-92fd-0e66cd85c4a9', '휴먼시아7단지(708동앞 지하주차장)', '경기도 안산시 단원구 신길로 50 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3339804, 126.788881, '민방위 대피소 : 휴먼시아7단지(708동앞 지하주차장)');
INSERT INTO public.shelters VALUES ('8df25cbb-feae-464f-bcfb-11b272e0d05c', '일신건영휴먼빌아파트(선부2)', '경기도 안산시 단원구 선이로 6 (선부동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3418065, 126.8042025, '민방위 대피소 : 일신건영휴먼빌아파트(선부2)');
INSERT INTO public.shelters VALUES ('91d8b90f-52be-4ed1-95a9-300b7ca0282c', '신안 1차아파트', '경기도 안산시 상록구 반석로 44 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2951262, 126.8650068, '민방위 대피소 : 신안 1차아파트');
INSERT INTO public.shelters VALUES ('237fcce1-e20a-4e3a-a620-1e77705aa41d', '한국선진학교', '경기도 안산시 상록구 이호로 113 (본오동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2878461, 126.8689661, '민방위 대피소 : 한국선진학교');
INSERT INTO public.shelters VALUES ('987398fa-fa68-493f-9e75-47797d44df44', '한양프라자', '경기도 안산시 단원구 달미로 63 (선부동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3400907, 126.8128515, '민방위 대피소 : 한양프라자');
INSERT INTO public.shelters VALUES ('477570ad-6bbd-494c-a0f2-8e630c246f01', '양지마을아파트(지하주차장)', '경기도 안산시 단원구 한양대학로 130 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3059934, 126.8370954, '민방위 대피소 : 양지마을아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('4bdd72d7-b1ac-426b-b8a8-1eff22d743c0', '삼익아파트 지하주차장(103동앞)', '경기도 안산시 단원구 새뿔길 55 (신길동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3376637, 126.777456, '민방위 대피소 : 삼익아파트 지하주차장(103동앞)');
INSERT INTO public.shelters VALUES ('57899e6f-2644-493f-8bf4-3f80ffb4cde0', '본오종합사회복지관', '경기도 안산시 상록구 이호로 39 (본오동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2874921, 126.8610868, '민방위 대피소 : 본오종합사회복지관');
INSERT INTO public.shelters VALUES ('5e8fd2ba-a608-4c29-bbf3-d492b2eb23e5', '벽산블루밍아파트 지하주차장', '경기도 안산시 단원구 원선로 50(원곡동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3285894, 126.7996113, '민방위 대피소 : 벽산블루밍아파트 지하주차장');
INSERT INTO public.shelters VALUES ('61723948-d70c-4309-be30-81232972b56b', '동산고등학교', '경기도 안산시 상록구 충장로 56 (본오동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2867791, 126.8578503, '민방위 대피소 : 동산고등학교');
INSERT INTO public.shelters VALUES ('a3be1a28-d223-4888-9d01-894f0095e7f7', '늘봄스위트빌2차', '경기도 안산시 단원구 선부광장로 77 (선부동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 08:42:32.814066', 37.33263549999999, 126.8104525, '민방위 대피소 : 늘봄스위트빌2차');
INSERT INTO public.shelters VALUES ('9e1d7d22-595a-406d-bf0b-3bb79e0b6953', '휴먼시아9단지(902동 지하주차장)', '경기도 안산시 단원구 도일로 26 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3326074, 126.7858249, '민방위 대피소 : 휴먼시아9단지(902동 지하주차장)');
INSERT INTO public.shelters VALUES ('a3db6229-6276-4d80-863a-5e4e4e13fe89', '우성아파트', '경기도 안산시 상록구 본오로 133 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2976989, 126.8650774, '민방위 대피소 : 우성아파트');
INSERT INTO public.shelters VALUES ('ac51c0b7-3486-4a68-8be9-bb023b6525e3', '선경아파트', '경기도 안산시 상록구 감골2로 58 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2919421, 126.8502666, '민방위 대피소 : 선경아파트');
INSERT INTO public.shelters VALUES ('aed09bf4-b6a0-4825-99b1-51acdfd69a68', '월드아파트', '경기도 안산시 상록구 감골로 59 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2871674, 126.8536704, '민방위 대피소 : 월드아파트');
INSERT INTO public.shelters VALUES ('b8c7268b-1eff-4b66-8ccb-70d7133915a1', '휴먼빌아파트(105동앞)', '경기도 안산시 단원구 신각길 18 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3369896, 126.7721057, '민방위 대피소 : 휴먼빌아파트(105동앞)');
INSERT INTO public.shelters VALUES ('bf5c3181-e3e4-45b8-a72d-7f16cefcd3e3', '그린빌16단지 지하주차장(전체)(초지동)', '경기도 안산시 단원구 초지2로 42 (초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3056722, 126.8129204, '민방위 대피소 : 그린빌16단지 지하주차장(전체)(초지동)');
INSERT INTO public.shelters VALUES ('c238c74d-a352-4a87-89d1-1e0376e71f08', '휴먼빌2차아파트(209동옆)', '경기도 안산시 단원구 신각길 44 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3374245, 126.7747057, '민방위 대피소 : 휴먼빌2차아파트(209동옆)');
INSERT INTO public.shelters VALUES ('c35d7a9d-9cdf-46fb-9f17-69b0147dbd39', '한양아파트비상대피시설', '경기도 안산시 상록구 반석로 8 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2952073, 126.8608964, '민방위 대피소 : 한양아파트비상대피시설');
INSERT INTO public.shelters VALUES ('d504e6bb-8223-40c8-97fc-7d5f6dace3e0', '군자상가(지하주차장)', '경기도 안산시 단원구 화랑로 32 (원곡동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3380262, 126.7928043, '민방위 대피소 : 군자상가(지하주차장)');
INSERT INTO public.shelters VALUES ('07de2ea2-c653-4b90-a733-1b1853e6e3cd', '안산세이브시티(선부2)', '경기도 안산시 단원구 선부광장로 23 (선부동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3362521, 126.8096085, '민방위 대피소 : 안산세이브시티(선부2)');
INSERT INTO public.shelters VALUES ('62060eef-681a-4a1f-ab7d-701f2f86049d', '안산고잔4차푸르지오(지하주차장)', '경기도 안산시 단원구 적금로 76 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.086966', 37.3140394, 126.8265822, '민방위 대피소 : 안산고잔4차푸르지오(지하주차장)');
INSERT INTO public.shelters VALUES ('64a7fd29-43a1-42c1-804a-5687b70a10ec', '호수공원대림아파트(지하주차장)', '경기도 안산시 단원구 광덕서로 19 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.086966', 37.306435, 126.8237351, '민방위 대피소 : 호수공원대림아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('a30224b2-de20-40f2-b1a6-551dc691df6b', '서해아파트 지하주차장', '경기도 안산시 상록구 건건5길 6 (건건동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3057995, 126.9046807, '민방위 대피소 : 서해아파트 지하주차장');
INSERT INTO public.shelters VALUES ('a466b865-c1bd-4525-b0aa-583497b2138b', '안산8차푸르지오아파트 지하주차장', '경기도 안산시 단원구 원초로 9(원곡동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.330104, 126.8016434, '민방위 대피소 : 안산8차푸르지오아파트 지하주차장');
INSERT INTO public.shelters VALUES ('a86f6554-1417-4cb8-bf80-c6921733301e', '안산고잔5차푸르지오(지하주차장)', '경기도 안산시 단원구 광덕2로 121 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.086966', 37.3113168, 126.8235061, '민방위 대피소 : 안산고잔5차푸르지오(지하주차장)');
INSERT INTO public.shelters VALUES ('b23b0424-d186-4b7f-828e-705243c5ff65', '무진4차 연립단지 지하주차장', '경기도 안산시 단원구 화정천동로 322 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3334767, 126.8174835, '민방위 대피소 : 무진4차 연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('b80d24d3-6847-4c8c-9f32-8e7c4b6d7d17', '산호한양아파트', '경기도 안산시 단원구 달미로 10 (선부동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.33669039999999, 126.8132831, '민방위 대피소 : 산호한양아파트');
INSERT INTO public.shelters VALUES ('f28b0b2b-eac9-40ed-9f56-776c840f0eee', '동서코아앞 지하도', '경기도 안산시 단원구 중앙대로 921 (고잔동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 08:43:54.685057', 37.3171561, 126.8389793, '민방위 대피소 : 동서코아앞 지하도');
INSERT INTO public.shelters VALUES ('f0287e55-9a96-44da-9b1b-b5c9aaa8b569', '중앙하이츠빌', '경기도 안산시 단원구 안산천서로 23 (고잔동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 08:43:54.685057', 37.3182263, 126.8419098, '민방위 대피소 : 중앙하이츠빌');
INSERT INTO public.shelters VALUES ('035cc7fe-6dcf-4176-bcb1-a6b2a0ec62e6', '제일스포츠(제일CC)', '경기도 안산시 상록구 태마당로 28 (부곡동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3263198, 126.8677366, '민방위 대피소 : 제일스포츠(제일CC)');
INSERT INTO public.shelters VALUES ('b01c3f6b-2fa4-40fe-b579-8e2306e02c8b', '거풍스카이팰리스', '경기도 안산시 단원구 당곡로 11 (고잔동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 08:43:54.685057', 37.3183171, 126.8330022, '민방위 대피소 : 거풍스카이팰리스');
INSERT INTO public.shelters VALUES ('fd4d9744-0e53-41c5-bc88-19888c734ed8', '축복교회(기독교한국침례회)', '경기도 안산시 상록구 소학길 34 (팔곡이동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 08:43:54.685057', 37.297429, 126.8846432, '민방위 대피소 : 축복교회(기독교한국침례회)');
INSERT INTO public.shelters VALUES ('de063d61-a31d-4712-a6ec-58e818b53f91', '그린빌18단지 지하주차장(전체)(초지동)', '경기도 안산시 단원구 초지2로 14 (초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3052451, 126.8098662, '민방위 대피소 : 그린빌18단지 지하주차장(전체)(초지동)');
INSERT INTO public.shelters VALUES ('e5f4884a-176a-4ab0-9a71-ea10155b79bc', '롯데캐슬아파트', '경기도 안산시 단원구 적금로 164 (고잔동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3225164, 126.827716, '민방위 대피소 : 롯데캐슬아파트');
INSERT INTO public.shelters VALUES ('e719e0a8-ae65-4eb8-a868-f42adbb8db91', '신우아파트', '경기도 안산시 상록구 감골로 83 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2889443, 126.8542601, '민방위 대피소 : 신우아파트');
INSERT INTO public.shelters VALUES ('e8ab9279-965a-4afa-9de1-8081baeb33ad', '서울프라자', '경기도 안산시 단원구 삼일로 310 (선부동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.333817, 126.8120842, '민방위 대피소 : 서울프라자');
INSERT INTO public.shelters VALUES ('eba43486-ef43-48f9-b433-806247bb3d00', '요진아파트', '경기도 안산시 상록구 본오로 133 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2976989, 126.8650774, '민방위 대피소 : 요진아파트');
INSERT INTO public.shelters VALUES ('ee382959-c968-48de-b93a-3fb65ad8227c', '롯데마트 지하1,2,3층 주차장(선부점)', '경기도 안산시 단원구 달미로 64 (수정한양아파트)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.339837, 126.815797, '민방위 대피소 : 롯데마트 지하1,2,3층 주차장(선부점)');
INSERT INTO public.shelters VALUES ('f88233ce-d851-4dc4-afba-1f0e89860bae', '롯데마트 상록점 비상대피시설', '경기도 안산시 상록구 반석로 20(본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.2952073, 126.8608964, '민방위 대피소 : 롯데마트 상록점 비상대피시설');
INSERT INTO public.shelters VALUES ('2209b4aa-88bf-4b6d-b3e4-9af29b1905b5', '수정한양아파트', '경기도 안산시 단원구 선부광장북로 67 (선부동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3393491, 126.815809, '민방위 대피소 : 수정한양아파트');
INSERT INTO public.shelters VALUES ('27a4e71f-fca9-4ce2-ba02-364eb49a1474', '그린빌17단지 지하주차장(전체)(초지동)', '경기도 안산시 단원구 초지2로 11 (초지동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3075538, 126.8104222, '민방위 대피소 : 그린빌17단지 지하주차장(전체)(초지동)');
INSERT INTO public.shelters VALUES ('cedc87a8-791c-4581-b1c6-3c6c81d1d4e5', '안산중앙노블레스', '경기도 안산시 단원구 예술대학로 17 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.086966', 37.318662, 126.8365131, '민방위 대피소 : 안산중앙노블레스');
INSERT INTO public.shelters VALUES ('d59f0be4-c6e4-4fea-b46a-323044b7a7cb', '안산메트로타운 힐스테이트 아파트', '경기도 안산시 단원구 석수로 138 (선부동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3489081, 126.8072095, '민방위 대피소 : 안산메트로타운 힐스테이트 아파트');
INSERT INTO public.shelters VALUES ('d9eba957-2d09-48a9-a666-939dc10df36b', '안산초지두산위브', '경기도 안산시 단원구 원선1로 38(초지동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3260854, 126.8041892, '민방위 대피소 : 안산초지두산위브');
INSERT INTO public.shelters VALUES ('da961d42-5b20-4b47-a57f-86c5e1d869f7', '한양대학교(본관 지하1층)', '경기도 안산시 상록구 한양대학로 55 (사동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2960668, 126.8347845, '민방위 대피소 : 한양대학교(본관 지하1층)');
INSERT INTO public.shelters VALUES ('e82c107a-88b6-482c-82be-cc37f3bb13ca', '단원구청', '경기도 안산시 단원구 화랑로 250(초지동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.32086779999999, 126.8152051, '민방위 대피소 : 단원구청');
INSERT INTO public.shelters VALUES ('ef31dd8a-7fb6-4ec3-8ac3-f298ab0f0169', '본오중학교', '경기도 안산시 상록구 본오로 90 (본오동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.2927706, 126.8672518, '민방위 대피소 : 본오중학교');
INSERT INTO public.shelters VALUES ('06baea28-daa3-4fc8-8381-b0ef8245d922', '이동 푸르지오2차아파트 지하주차장', '경기도 안산시 상록구 안산천남1로 70 (이동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3089276, 126.843118, '민방위 대피소 : 이동 푸르지오2차아파트 지하주차장');
INSERT INTO public.shelters VALUES ('0f9423bf-0c5e-4702-9f60-75b05d8b61e5', '푸른마을 3단지아파트(지하주차장)', '경기도 안산시 상록구 삼리로 86 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3039546, 126.8494445, '민방위 대피소 : 푸른마을 3단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('18d7593a-5b8b-4c12-a2b0-c2fe87e7fd14', '성포동 삼환연립 지하주차장', '경기도 안산시 상록구 충장로 452 (성포동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3190403, 126.8504306, '민방위 대피소 : 성포동 삼환연립 지하주차장');
INSERT INTO public.shelters VALUES ('23ccb1d8-ddee-4586-9d2c-3ce11cfda24c', '안산고잔9차푸르지오아파트', '경기도 안산시 상록구 해양로 16 (사동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.2934811, 126.8206526, '민방위 대피소 : 안산고잔9차푸르지오아파트');
INSERT INTO public.shelters VALUES ('06c10c12-f586-49aa-a6a2-d40e09315c7b', '휴먼시아3단지(지하주차장) 105동', '경기도 안산시 단원구 새뿔길 101 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.3361252, 126.7826727, '민방위 대피소 : 휴먼시아3단지(지하주차장) 105동');
INSERT INTO public.shelters VALUES ('103bcff0-cc10-4bf6-9297-747f3bbd706c', '효성아파트(선부2)', '경기도 안산시 단원구 선부로 29 (선부동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:48:40.973323', 37.338474, 126.7991771, '민방위 대피소 : 효성아파트(선부2)');
INSERT INTO public.shelters VALUES ('420d9ab1-d798-4c32-a610-d9d7fa5c5443', '신안 2차아파트', '경기도 안산시 상록구 반석로 9 (본오동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.2976, 126.8612084, '민방위 대피소 : 신안 2차아파트');
INSERT INTO public.shelters VALUES ('46359cb2-54cd-42bc-a53d-46412072c419', '상록마을아파트', '경기도 안산시 상록구 삼리로 23 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3057462, 126.8424525, '민방위 대피소 : 상록마을아파트');
INSERT INTO public.shelters VALUES ('5cf8b2a5-01a7-4166-a72b-1e11dcc0a086', '본오2차아파트', '경기도 안산시 상록구 선진로 114 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.2808936, 126.8533367, '민방위 대피소 : 본오2차아파트');
INSERT INTO public.shelters VALUES ('ee76c17d-dbe0-4833-b457-aaa53bc5a9bd', '안산고잔3차푸르지오(지하주차장)', '경기도 안산시 단원구 광덕3로 201 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.086966', 37.31274, 126.8289095, '민방위 대피소 : 안산고잔3차푸르지오(지하주차장)');
INSERT INTO public.shelters VALUES ('f7fa310e-f1ab-4a69-992d-ac40b4161a1c', '단원마을아파트(지하주차장)', '경기도 안산시 단원구 광덕서로 43 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.086966', 37.3090514, 126.8261604, '민방위 대피소 : 단원마을아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('fa671a2d-b4b4-40e2-a91c-07f72c7e8f88', '동명벽산블루밍아파트 지하주차장', '경기도 안산시 단원구 선부광장북로 36 (선부동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.086966', 37.3377689, 126.81124, '민방위 대피소 : 동명벽산블루밍아파트 지하주차장');
INSERT INTO public.shelters VALUES ('0077a0ae-a52b-4ee5-a6cc-825ec4c82a7f', '네오빌주공아파트(지하주차장)', '경기도 안산시 단원구 광덕동로 78 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.3106978, 126.8342072, '민방위 대피소 : 네오빌주공아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('0160ab52-7d82-41c4-b3ae-9459f0835f85', '안산문화예술의 전당(지하주차장)', '경기도 안산시 단원구 화랑로 312 (고잔동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.3197974, 126.822512, '민방위 대피소 : 안산문화예술의 전당(지하주차장)');
INSERT INTO public.shelters VALUES ('0722fcc1-0fef-4b8f-9eb3-6b58c4b7e45d', '그린빌주공8단지아파트(지하주차장)', '경기도 안산시 단원구 광덕2로 241 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.3106707, 126.8375333, '민방위 대피소 : 그린빌주공8단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('08dca87b-b521-497e-9bc1-ef1717c990b5', '보네르빌리지아파트(지하주차장)', '경기도 안산시 단원구 안산천남로 211 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.3083136, 126.8398657, '민방위 대피소 : 보네르빌리지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('0ac94297-3713-43f7-a9c9-5dec54feef67', '보륭2차 연립단지 지하주차장', '경기도 안산시 단원구 와동로1길 27 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.33289, 126.8241646, '민방위 대피소 : 보륭2차 연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('0ae5fe44-a141-4977-baf0-e0285e67d895', '휴먼시아5단지아파트(506동 지하주차장)', '경기도 안산시 단원구 신길로 94 (신길동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.3387111, 126.7891091, '민방위 대피소 : 휴먼시아5단지아파트(506동 지하주차장)');
INSERT INTO public.shelters VALUES ('1376b3ed-1fbc-4570-8cee-af19de119ffb', '경남아너스빌아파트 지하주차장', '경기도 안산시 단원구 원선1로 61(원곡동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.3289716, 126.8037763, '민방위 대피소 : 경남아너스빌아파트 지하주차장');
INSERT INTO public.shelters VALUES ('3141d305-1bcc-49e1-a250-3b13d0df90e2', '고향마을아파트(지하주차장)', '경기도 안산시 상록구 용하공원로 39 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3068576, 126.8532451, '민방위 대피소 : 고향마을아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('498a5689-b648-4998-886a-59badbacb315', '연지프라자 지하주차장', '경기도 안산시 상록구 각골로 55 (본오동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.294662, 126.872329, '민방위 대피소 : 연지프라자 지하주차장');
INSERT INTO public.shelters VALUES ('4de961cb-4cf9-402e-a771-0a47f367e280', '사사동 현대아파트 지하주차장', '경기도 안산시 상록구 양지마을1길 81 (사사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.2950753, 126.9168439, '민방위 대피소 : 사사동 현대아파트 지하주차장');
INSERT INTO public.shelters VALUES ('51e1937a-fd2d-4d95-a1b7-3ef93ee67faa', '안산국제비즈니스고등학교 체육관 지하 비상대', '경기도 안산시 상록구 수인로 1981 (장상동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3607657, 126.8744225, '민방위 대피소 : 안산국제비즈니스고등학교 체육관 지하 비상대');
INSERT INTO public.shelters VALUES ('5a512f92-edd1-4b4a-9225-ac3e2bfa1f2d', '보륭1차 연립단지 지하주차장', '경기도 안산시 단원구 와동로1길 21 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3325904, 126.8247282, '민방위 대피소 : 보륭1차 연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('5ae30c46-4b35-4177-abb4-8c814c695aa3', '안산중앙병원', '경기도 안산시 상록구 구룡로 87 (일동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3166692, 126.8743284, '민방위 대피소 : 안산중앙병원');
INSERT INTO public.shelters VALUES ('610c20a1-a503-4beb-bed9-d2861d3c80aa', '성포동 동산빌라 지하주차장', '경기도 안산시 상록구 충장로 456 (성포동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3176663, 126.8551759, '민방위 대피소 : 성포동 동산빌라 지하주차장');
INSERT INTO public.shelters VALUES ('63f56a9c-06ba-4074-aae4-a6aa16edad84', '안산고잔7차푸르지오아파트', '경기도 안산시 상록구 해양1로 30 (사동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.2960411, 126.8181649, '민방위 대피소 : 안산고잔7차푸르지오아파트');
INSERT INTO public.shelters VALUES ('b24b58b4-c9c8-42f7-a153-6a4399725265', '성포동 신우연립 지하주차장', '경기도 안산시 상록구 충장로 462 (성포동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3257433, 126.8513395, '민방위 대피소 : 성포동 신우연립 지하주차장');
INSERT INTO public.shelters VALUES ('c2d3e98e-8100-4dbe-af64-c5ca2c92a8fe', '늘푸른아파트(지하주차장)', '경기도 안산시 상록구 중보로 22 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3056868, 126.8514287, '민방위 대피소 : 늘푸른아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('c9ace328-6df9-4718-9365-3b14319656f3', '보륭3차 연립단지 지하주차장', '경기도 안산시 단원구 화정로3길 18 (와동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3319695, 126.8237176, '민방위 대피소 : 보륭3차 연립단지 지하주차장');
INSERT INTO public.shelters VALUES ('cbaf65a3-7b75-4257-81a8-14d555a993a8', '무진연립(지하주차장)', '경기도 안산시 단원구 인현로 39 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3255768, 126.8223937, '민방위 대피소 : 무진연립(지하주차장)');
INSERT INTO public.shelters VALUES ('ccc22d8b-8189-4943-8b9b-6f5fe27d2e5d', '그린빌주공9단지아파트(지하주차장)', '경기도 안산시 단원구 안산천남로 245 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3103446, 126.8403174, '민방위 대피소 : 그린빌주공9단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('fb864adc-04f8-44ea-8c9e-6895e19016ad', '그린빌주공7단지아파트(지하주차장)', '경기도 안산시 단원구 광덕2로 216 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:42:32.814066', '2025-10-30 09:56:35.093582', 37.30864529999999, 126.8336977, '민방위 대피소 : 그린빌주공7단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('6e9a583a-7b88-4d07-a640-80d4ac3c286b', '푸른마을 4단지아파트(지하주차장)', '경기도 안산시 상록구 용하공원로 7 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.30390999999999, 126.8510464, '민방위 대피소 : 푸른마을 4단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('71600ef2-46f0-4045-8508-eef6c22e60af', '상록구청(지하주차장)', '경기도 안산시 상록구 석호로 110-0 (사동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3006546, 126.8465397, '민방위 대피소 : 상록구청(지하주차장)');
INSERT INTO public.shelters VALUES ('7ac4a946-3ce4-48e1-b502-708be656148a', '고려대학교안산병원(본관 지하주차장)', '경기도 안산시 단원구 적금로 123 (고잔동)', '지진대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.319305, 126.8252025, '민방위 대피소 : 고려대학교안산병원(본관 지하주차장)');
INSERT INTO public.shelters VALUES ('82f31614-f99c-4006-82b1-32a5057e7918', '대진연립(지하주차장)', '경기도 안산시 단원구 적금로4길 1 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3275058, 126.8279337, '민방위 대피소 : 대진연립(지하주차장)');
INSERT INTO public.shelters VALUES ('83d09a2c-a647-4787-be60-7687f1e4a709', '동영센트럴타워 지하주차장 비상대피시설', '경기도 안산시 상록구 원당골길 17 (수암동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3635613, 126.8764981, '민방위 대피소 : 동영센트럴타워 지하주차장 비상대피시설');
INSERT INTO public.shelters VALUES ('86203ce5-86ab-4e91-92ae-0529abd39815', '진우연립(지하주차장)', '경기도 안산시 단원구 인현중앙길 28 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3240134, 126.8216597, '민방위 대피소 : 진우연립(지하주차장)');
INSERT INTO public.shelters VALUES ('894879e8-d89d-48bb-8fc5-721f9df238e8', '엠제이프라자 지하주차장 비상대피시설', '경기도 안산시 상록구 갯다리길 7 (수암동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3624987, 126.8749999, '민방위 대피소 : 엠제이프라자 지하주차장 비상대피시설');
INSERT INTO public.shelters VALUES ('9b3381f9-c5fa-4ba0-ae1f-16a6035d9109', '엘리지움 아파트 지하주차장(101동,102동 지하)', '경기도 안산시 상록구 수암길 55 (수암동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.361141, 126.8813466, '민방위 대피소 : 엘리지움 아파트 지하주차장(101동,102동 지하)');
INSERT INTO public.shelters VALUES ('ab62111b-5f99-4a4e-b27f-f29a1f667b21', '푸른마을5단지아파트(지하주차장)', '경기도 안산시 상록구 광덕4로 460 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3033599, 126.8556931, '민방위 대피소 : 푸른마을5단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('acdadb95-9740-44e7-a656-c6ff92fc49a6', '푸른마을2단지아파트(지하주차장)', '경기도 안산시 상록구 중보로 16 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3051647, 126.8488123, '민방위 대피소 : 푸른마을2단지아파트(지하주차장)');
INSERT INTO public.shelters VALUES ('84f62ff5-e8bc-4b3c-8b81-57a56a586eaa', '현대쇼핑(월피동)', '경기도 안산시 상록구 예술광장로 19 (월피동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3292998, 126.8461398, '민방위 대피소 : 현대쇼핑(월피동)');
INSERT INTO public.shelters VALUES ('91b57ca6-27c9-40db-9805-ffaeb587814b', '팔곡마을주공아파트', '경기도 안산시 상록구 정동1길 7 (팔곡일동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.2985029, 126.8867539, '민방위 대피소 : 팔곡마을주공아파트');
INSERT INTO public.shelters VALUES ('9c3fa609-2c03-4a0f-b25c-40c7f3bb4ccf', '숲속마을아파트', '경기도 안산시 상록구 삼리로 24 (사동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3040931, 126.8408698, '민방위 대피소 : 숲속마을아파트');
INSERT INTO public.shelters VALUES ('c706ddab-36c8-42b8-9868-9e21e5f76775', '다농마트 (지하주차장)', '경기도 안산시 상록구 예술광장로 1 (월피동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3283668, 126.8440324, '민방위 대피소 : 다농마트 (지하주차장)');
INSERT INTO public.shelters VALUES ('ce7a6c74-2321-4308-8312-0d6308d9bbd1', '이동 주공그린빌 주차장', '경기도 안산시 상록구 안산천남1로 100 (이동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3109592, 126.8434688, '민방위 대피소 : 이동 주공그린빌 주차장');
INSERT INTO public.shelters VALUES ('f0a2ccd3-c5de-4a59-aad7-e401dc893bf1', '휴먼시아6단지(609동 지하주차장)', '경기도 안산시 단원구 신길로 62 (신길동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3363574, 126.7891448, '민방위 대피소 : 휴먼시아6단지(609동 지하주차장)');
INSERT INTO public.shelters VALUES ('f47fb894-846d-415f-9bfe-b81f5641556d', '영풍맘모스프라자', '경기도 안산시 단원구 고잔로 76 (고잔동)', '민방위대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:48:40.983971', 37.3187816, 126.8348946, '민방위 대피소 : 영풍맘모스프라자');
INSERT INTO public.shelters VALUES ('d95e451f-be31-48e8-9ecb-d738ef228798', '건양그린아파트 지하주차장 비상대피시설', '경기도 안산시 상록구 청룡길 25 (장상동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3592764, 126.8732005, '민방위 대피소 : 건양그린아파트 지하주차장 비상대피시설');
INSERT INTO public.shelters VALUES ('de78c7f7-66ef-4734-b05e-cef263d2504f', '안산동산교회 복지문화센터(지하1층~2층 주차장)', '경기도 안산시 상록구 석호공원로 8 (사동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3015196, 126.8440039, '민방위 대피소 : 안산동산교회 복지문화센터(지하1층~2층 주차장)');
INSERT INTO public.shelters VALUES ('ed6dd349-ff7e-4e78-8f8d-dcb040302bd4', '안산고잔6차푸르지오아파트', '경기도 안산시 상록구 해양1로 11 (사동)', '해일대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.2956781, 126.8238246, '민방위 대피소 : 안산고잔6차푸르지오아파트');
INSERT INTO public.shelters VALUES ('f3139481-c1d2-47a6-852d-88520da0ae01', '대동연립(지하주차장)', '경기도 안산시 단원구 단원안길 61 (고잔동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3309989, 126.8256628, '민방위 대피소 : 대동연립(지하주차장)');
INSERT INTO public.shelters VALUES ('fc4c35ec-ec2e-44dc-8aef-842811b7796a', '성포동 선경아파트 지하주차장', '경기도 안산시 상록구 예술광장1로 131 (성포동)', '기타대피소', NULL, NULL, '1666-1234', NULL, NULL, NULL, '2025-10-30 08:43:54.685057', '2025-10-30 09:56:35.093582', 37.3256878, 126.8432252, '민방위 대피소 : 성포동 선경아파트 지하주차장');


--
-- TOC entry 5671 (class 2606 OID 17489)
-- Name: shelters shelters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shelters
    ADD CONSTRAINT shelters_pkey PRIMARY KEY (id);


--
-- TOC entry 5665 (class 1259 OID 17501)
-- Name: idx_shelters_coords; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shelters_coords ON public.shelters USING btree (latitude, longitude);


--
-- TOC entry 5666 (class 1259 OID 17499)
-- Name: idx_shelters_latitude; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shelters_latitude ON public.shelters USING btree (latitude);


--
-- TOC entry 5667 (class 1259 OID 17500)
-- Name: idx_shelters_longitude; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shelters_longitude ON public.shelters USING btree (longitude);


--
-- TOC entry 5668 (class 1259 OID 17492)
-- Name: idx_shelters_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shelters_name ON public.shelters USING btree (name);


--
-- TOC entry 5669 (class 1259 OID 17491)
-- Name: idx_shelters_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shelters_type ON public.shelters USING btree (shelter_type);


-- Completed on 2025-10-30 20:43:27

--
-- PostgreSQL database dump complete
--

\unrestrict Jv8j8AZZRnwL7gxxAACa7KlHUgYlgubF0g3REouy5dEZNYORDAv7bpdKRwN2X6B

