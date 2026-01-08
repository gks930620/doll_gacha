-- FileEntity에 usage 컬럼 추가 및 RefType enum 확장

-- 1. usage 컬럼 추가
ALTER TABLE files ADD COLUMN usage VARCHAR(20);

-- 2. 기존 데이터를 THUMBNAIL로 설정 (기존 파일들은 대표 이미지로 간주)
UPDATE files SET usage = 'THUMBNAIL' WHERE usage IS NULL;

-- 3. usage 컬럼을 NOT NULL로 변경 (선택사항)
-- ALTER TABLE files MODIFY COLUMN usage VARCHAR(20) NOT NULL;

-- 참고: RefType enum 값 추가
-- DOLL_SHOP (기존)
-- COMMUNITY (추가)
-- REVIEW (추가)
-- DOLL (추가)

-- Usage enum 값
-- THUMBNAIL: 썸네일/대표 이미지
-- CONTENT: 본문 내용 이미지
-- ATTACHMENT: 첨부 파일

