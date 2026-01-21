# 🐳 로컬 Docker 환경 문제 해결 가이드

> 로컬에서는 잘 되는데 Docker에서 안 될 때 확인할 사항들

---

## 🔐 1. OAuth2 로그인 문제

### 문제 현상
- Docker에서 카카오/구글 로그인 시 `UsernameNotFoundException` 발생
- `"사용자를 찾을 수 없습니다: kakao4663679805"` 에러
- Whitelabel Error Page 표시

### 원인 분석

```
로컬 환경                    Docker 환경
┌─────────────────┐         ┌─────────────────┐
│ 로컬 MariaDB    │         │ Docker MariaDB  │
│ (포트 3406)     │         │ (포트 3407)     │
│ 사용자 O        │         │ 사용자 X ❌     │
└─────────────────┘         └─────────────────┘
          ↑
    브라우저 쿠키에 JWT 토큰 저장됨 (로컬에서 로그인)
          ↓
    Docker 접속 시 같은 쿠키 전송 → Docker DB에는 해당 사용자 없음!
```

**핵심 원인**: 같은 `localhost` 도메인을 사용하면 **쿠키가 공유**됨

### 수정 방법

**`JwtAccessTokenCheckAndSaveUserInfoFilter.java`**

```java
import org.springframework.security.core.userdetails.UsernameNotFoundException;

// try-catch 블록에 추가
} catch (JwtException e) {
    request.setAttribute("ERROR_CAUSE", "잘못된토큰");
    chain.doFilter(request, response);
} catch (UsernameNotFoundException e) {
    // DB에 사용자가 없는 경우 → 쿠키 삭제 후 비로그인 상태로 처리
    log.warn("JWT 토큰의 사용자가 DB에 없음: {}. 쿠키 삭제", e.getMessage());
    
    // access_token 쿠키 삭제
    Cookie accessTokenCookie = new Cookie("access_token", null);
    accessTokenCookie.setMaxAge(0);
    accessTokenCookie.setPath("/");
    response.addCookie(accessTokenCookie);
    
    // refresh_token 쿠키 삭제
    Cookie refreshTokenCookie = new Cookie("refresh_token", null);
    refreshTokenCookie.setMaxAge(0);
    refreshTokenCookie.setPath("/");
    response.addCookie(refreshTokenCookie);
    
    chain.doFilter(request, response);  // 비로그인으로 통과
}
```

### 일반적인 고려사항

| 항목 | 설명 |
|------|------|
| **환경 분리** | 로컬/Docker/운영 환경마다 DB가 다름 → JWT 토큰 호환 안됨 |
| **쿠키 충돌** | 같은 `localhost` 도메인이면 쿠키 공유됨 |
| **예외 처리** | 사용자 없을 때 500 에러 대신 graceful 처리 필요 |
| **Redirect URI** | OAuth2 제공자(카카오/구글) 콘솔에 Docker 환경 URL도 등록해야 함 |

### 수동 해결 방법 (임시)

브라우저에서 쿠키 삭제:
1. 개발자도구 열기 (F12)
2. Application 탭 → Cookies → localhost
3. `access_token`, `refresh_token` 삭제

---

## 📁 2. 파일 업로드/다운로드 문제

### 문제 현상
- 커뮤니티 에디터에서 이미지 업로드 → **201 성공**, 하지만 **이미지 표시 안됨**
- 첨부파일 다운로드 → **404 에러**
- `<img src="/uploads/xxx.png">` 이미지 깨짐

### 원인 분석

```
로컬 환경                              Docker 환경
┌──────────────────────────┐         ┌──────────────────────────┐
│ file.upload-dir=./uploads│         │ file.upload-dir=/app/uploads│
│ 상대 경로 → 잘 작동      │         │ 끝에 / 없음 → 경로 결합 오류 │
│                          │         │                            │
│ ./uploads/ + xxx.png     │         │ /app/uploads + xxx.png     │
│ = ./uploads/xxx.png ✅   │         │ = /app/uploadsxxx.png ❌   │
└──────────────────────────┘         └──────────────────────────┘
```

### 수정 방법

#### 1. `application-prod.yml` - 경로 끝에 `/` 추가

```yaml
# ❌ Before
file:
  upload-dir: /app/uploads

# ✅ After  
file:
  upload-dir: /app/uploads/
```

#### 2. `FileUtil.java` - 안전한 경로 결합

```java
// ❌ Before - 문자열 단순 결합 (위험)
Path filePath = Paths.get(uploadDir + storedFilename);

// ✅ After - Paths.resolve() 사용 (안전)
Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
Path filePath = uploadPath.resolve(storedFilename);
```

#### 3. `FileController.java` - 다운로드 경로도 동일하게 수정

```java
// 절대 경로로 안전하게 처리
Path uploadPath = Paths.get(fileUtil.getUploadDir()).toAbsolutePath().normalize();
Path file = uploadPath.resolve(fileEntity.getStoredFileName());
log.info("파일 다운로드 시도: fileId={}, path={}", fileId, file);
```

#### 4. Docker 볼륨 매핑 확인

```yaml
# docker-compose.yml
services:
  app:
    volumes:
      - ./uploads:/app/uploads  # 호스트 ↔ 컨테이너 연결
```

### 일반적인 고려사항

| 항목 | 설명 |
|------|------|
| **경로 구분자** | Windows(`\`) vs Linux(`/`) → `Paths.get()` 사용 |
| **끝 슬래시** | 디렉토리 경로는 항상 `/`로 끝나도록 통일 |
| **상대 vs 절대 경로** | Docker는 절대 경로 사용 권장 |
| **볼륨 매핑** | 컨테이너 재시작 시 파일 유지되도록 볼륨 설정 필수 |
| **권한 문제** | Linux 컨테이너에서 파일 읽기/쓰기 권한 확인 |

---

## 🎯 3. 환경별 설정 체크리스트

### 로컬 → Docker 배포 시 확인사항

```
┌─────────────────────────────────────────────────────────────────┐
│ ✅ application-prod.yml 파일 경로 설정 확인 (끝에 / 있는지)     │
│ ✅ OAuth2 redirect-uri에 Docker URL 등록                        │
│ ✅ JWT 토큰 예외 처리 (사용자 없을 때 graceful 처리)            │
│ ✅ 파일 경로 결합 시 Paths.resolve() 사용                        │
│ ✅ 볼륨 매핑으로 파일 영속성 확보                                │
│ ✅ 환경변수(.env) 제대로 전달되는지 확인                         │
│ ✅ DB 연결 문자열 (localhost → 컨테이너명)                       │
│ ✅ 브라우저 쿠키 정리 (환경 전환 시)                             │
└─────────────────────────────────────────────────────────────────┘
```

### 환경별 설정 비교

| 설정 | 로컬 | Docker |
|------|------|--------|
| DB URL | `localhost:3406` | `db:3306` (컨테이너명) |
| 파일 경로 | `./uploads/` | `/app/uploads/` |
| 프로파일 | `default` | `prod` |
| 포트 | `8080` | `8080` (매핑) |

---

## 📝 4. 디버깅 명령어 모음

### Docker 로그 확인

```powershell
# 실시간 로그 확인
docker-compose logs -f app

# 최근 100줄만 확인
docker-compose logs --tail=100 app
```

### 컨테이너 내부 확인

```powershell
# 업로드 폴더 파일 목록
docker exec -it doll_gacha_app ls -la /app/uploads/

# 환경변수 확인
docker exec -it doll_gacha_app env | grep -E "(SPRING|FILE)"

# 컨테이너 쉘 접속
docker exec -it doll_gacha_app /bin/sh
```

### 브라우저 쿠키 삭제

```
1. 개발자도구 열기 (F12)
2. Application 탭 → Cookies → localhost
3. access_token, refresh_token 삭제
4. 새로고침
```

### Docker 재빌드

```powershell
# 컨테이너 중지
docker-compose down

# 캐시 없이 재빌드
docker-compose build --no-cache

# 다시 실행
docker-compose up -d
```

---

## 🔑 5. 핵심 교훈

### ❌ 흔한 착각들

1. **"로컬에서 되면 Docker에서도 된다"**
   - 경로, DB, 환경변수 모두 다름
   
2. **"상대 경로가 편하다"**
   - Docker에서는 절대 경로가 안전

3. **"에러가 나면 500 반환하면 된다"**
   - 사용자 경험을 위해 graceful fallback 필요

### ✅ 권장 사항

1. **경로 처리는 항상 `Paths.get().toAbsolutePath().normalize()` 사용**
2. **디렉토리 경로는 끝에 `/` 붙이기**
3. **예외 발생 시 적절한 fallback 처리**
4. **충분한 로그 남기기** (Docker 디버깅은 로그가 생명)
5. **환경 전환 시 브라우저 쿠키 정리**

---

## 📚 관련 파일 목록

- `src/main/resources/application-prod.yml` - Docker 환경 설정
- `src/main/java/.../jwt/filter/JwtAccessTokenCheckAndSaveUserInfoFilter.java` - JWT 필터
- `src/main/java/.../file/util/FileUtil.java` - 파일 저장 유틸
- `src/main/java/.../file/controller/FileController.java` - 파일 API
- `src/main/java/.../common/config/WebConfig.java` - 정적 리소스 설정
- `docker-compose.yml` - Docker 구성
- `Dockerfile` - 이미지 빌드 설정

