# 🚀 CI/CD 배포 가이드

## 개요

```
commit → GitHub → GitHub Actions → Docker Hub → Railway
   │         │           │              │           │
   │         │           │              │           └── 컨테이너 실행
   │         │           │              └── 이미지 저장소
   │         │           └── 자동 빌드 & 테스트
   │         └── 코드 저장소
   └── 개발자
```

---

## 📋 사전 준비

### 1. Docker Hub 계정 생성 (10분)

1. https://hub.docker.com 접속
2. 회원가입 (무료)
3. Access Token 생성:
   - 우측 상단 프로필 → **Account Settings**
   - **Security** → **Access Tokens**
   - **New Access Token** 클릭
   - 이름: `github-actions`
   - 권한: `Read, Write, Delete`
   - **Generate** → 토큰 복사해두기!

### 2. GitHub Secrets 설정 (10분)

GitHub 저장소 → **Settings** → **Secrets and variables** → **Actions**

| Secret 이름 | 값 | 설명 |
|------------|-----|------|
| `DOCKER_USERNAME` | Docker Hub 사용자명 | 예: `myusername` |
| `DOCKER_TOKEN` | Docker Hub Access Token | 위에서 생성한 토큰 |
| `RAILWAY_WEBHOOK_URL` | Railway 웹훅 URL | Railway 배포 시 필요 (선택) |

### 3. 환경변수 Secrets 추가 (운영 환경용)

| Secret 이름 | 설명 |
|------------|------|
| `KAKAO_CLIENT_ID` | 카카오 OAuth2 Client ID |
| `KAKAO_CLIENT_SECRET` | 카카오 OAuth2 Client Secret |
| `GOOGLE_CLIENT_ID` | 구글 OAuth2 Client ID |
| `GOOGLE_CLIENT_SECRET` | 구글 OAuth2 Client Secret |
| `JWT_SECRET_KEY` | JWT 서명 키 (최소 32자) |
| `DB_PASSWORD` | 데이터베이스 비밀번호 |

---

## 🔧 GitHub Actions 워크플로우

`.github/workflows/deploy.yml` 파일이 생성되어 있습니다.

### 동작 순서

```
1️⃣ 테스트 (test)
   └── Gradle 테스트 실행
   └── 실패 시 중단!

2️⃣ 빌드 & 푸시 (build-and-push)
   └── Docker 이미지 빌드
   └── Docker Hub에 푸시
   └── 태그: latest, {commit-sha}

3️⃣ 배포 (deploy)
   └── Railway 웹훅 호출 (선택)
```

### 자동 실행 조건

| 이벤트 | 동작 |
|--------|------|
| `main` 또는 `master` 브랜치에 push | 테스트 → 빌드 → 배포 |
| Pull Request | 테스트만 실행 |

---

## 🚂 Railway 배포 (권장)

### 왜 Railway?
- ✅ GitHub 연동 간편
- ✅ Docker Hub 이미지 배포 지원
- ✅ 무료 $5/월 크레딧
- ✅ HTTPS 자동 제공
- ✅ 환경변수 관리 쉬움

### Railway 설정 방법

#### 1. Railway 가입
1. https://railway.app 접속
2. GitHub 계정으로 로그인

#### 2. 새 프로젝트 생성
1. **New Project** → **Deploy from Docker Image**
2. Docker Image: `{DOCKER_USERNAME}/doll-gacha:latest`

#### 3. 환경변수 설정
Railway 대시보드 → **Variables** 탭:

```
SPRING_PROFILES_ACTIVE=prod
SPRING_DATASOURCE_URL=jdbc:mariadb://db:3306/doll_gacha
SPRING_DATASOURCE_USERNAME=doll_gacha
SPRING_DATASOURCE_PASSWORD=your_password
KAKAO_CLIENT_ID=your_kakao_id
KAKAO_CLIENT_SECRET=your_kakao_secret
GOOGLE_CLIENT_ID=your_google_id
GOOGLE_CLIENT_SECRET=your_google_secret
JWT_SECRET_KEY=your_jwt_secret_32_characters_min
APP_BASE_URL=https://your-app.railway.app
```

#### 4. 데이터베이스 추가
1. **New** → **Database** → **MariaDB**
2. 자동으로 환경변수 연결됨

#### 5. 도메인 확인
Railway가 자동으로 `https://your-app.railway.app` 도메인 제공

#### 6. OAuth2 Redirect URI 업데이트
카카오/구글 개발자 콘솔에서:
```
https://your-app.railway.app/login/oauth2/code/kakao
https://your-app.railway.app/login/oauth2/code/google
```

---

## 🔄 배포 프로세스

### 자동 배포 (CI/CD)

```powershell
# 1. 코드 수정
# 2. 커밋 & 푸시
git add .
git commit -m "feat: 새 기능 추가"
git push origin main

# 3. 자동으로:
#    - GitHub Actions 실행
#    - 테스트 통과
#    - Docker 이미지 빌드
#    - Docker Hub 푸시
#    - Railway 배포 (설정된 경우)
```

### GitHub Actions 확인

GitHub 저장소 → **Actions** 탭에서 진행 상황 확인

```
✅ test         → 테스트 통과
✅ build-and-push → Docker Hub에 이미지 푸시 완료
✅ deploy       → Railway 배포 완료
```

---

## 🐳 Docker Hub 이미지 확인

### 이미지 태그

| 태그 | 설명 |
|------|------|
| `latest` | 최신 버전 |
| `abc1234` | 특정 커밋 SHA |

### 로컬에서 Docker Hub 이미지 테스트

```powershell
# 이미지 풀
docker pull {username}/doll-gacha:latest

# 실행
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e JWT_SECRET_KEY=your_secret \
  {username}/doll-gacha:latest
```

---

## ⚠️ 주의사항

### 1. application-prod.yml 수정 필요

실제 배포 시에는 테스트 데이터 삽입 비활성화:

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: update  # create → update로 변경!
  sql:
    init:
      mode: never  # always → never로 변경!
```

### 2. Secrets는 절대 코드에 넣지 않기

```
❌ application.yml에 비밀번호 직접 입력
✅ ${환경변수} 로 참조, Railway/GitHub Secrets에서 관리
```

### 3. 브랜치 전략

```
main (또는 master)  ← 배포 브랜치 (자동 배포)
  │
  ├── develop       ← 개발 브랜치
  │     │
  │     ├── feature/xxx  ← 기능 브랜치
  │     └── feature/yyy
  │
  └── hotfix/xxx    ← 긴급 수정
```

---

## 📊 배포 후 확인

### 1. 헬스체크
```
https://your-app.railway.app/actuator/health
```

### 2. Swagger
```
https://your-app.railway.app/swagger-ui.html
```

### 3. 로그 확인
Railway 대시보드 → **Logs** 탭

---

## 🔧 트러블슈팅

### 빌드 실패 시
1. GitHub Actions 탭에서 에러 로그 확인
2. 로컬에서 `./gradlew test` 실행해서 테스트 통과 확인
3. `docker-compose build` 로컬에서 확인

### 배포 실패 시
1. Railway 대시보드에서 로그 확인
2. 환경변수 누락 확인
3. DB 연결 문제 확인

### 이미지 푸시 실패 시
1. Docker Hub 토큰 만료 확인
2. GitHub Secrets 재설정
3. Docker Hub 저장소 이름 확인

---

## 💡 요약

| 단계 | 할 일 | 예상 시간 |
|------|-------|----------|
| 1 | Docker Hub 가입 & 토큰 생성 | 10분 |
| 2 | GitHub Secrets 설정 | 10분 |
| 3 | Railway 가입 & 프로젝트 생성 | 20분 |
| 4 | 환경변수 설정 | 10분 |
| 5 | OAuth2 Redirect URI 업데이트 | 10분 |
| 6 | `git push` → 자동 배포 확인! | 5분 |

**총 소요 시간: 약 1시간**

