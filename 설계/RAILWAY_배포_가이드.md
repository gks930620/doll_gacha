# 🚀 Railway 배포 가이드 (CI/CD 포함)

## 📋 목표
GitHub에 커밋/푸시만 하면 자동으로 Railway에 배포되는 CI/CD 파이프라인 구축

---

## 🔄 자동 배포 방법 비교

### 📌 방법 A: Railway GitHub 직접 연동 (⭐ 추천)

```
GitHub Push → Railway가 직접 감지 → Railway가 Dockerfile로 이미지 빌드 → 자동 배포
```

| 장점 | 단점 |
|------|------|
| 설정이 가장 간단함 | Docker Hub에 이미지가 저장되지 않음 |
| 별도 Secret/Webhook 불필요 | Railway 서비스가 GitHub 저장소에 연결되어야 함 |
| Railway가 모든 것을 처리 | |

**설정 방법:**
1. Railway에서 서비스 생성 시 **"Deploy from GitHub Repo"** 선택
2. GitHub 저장소 연결
3. 서비스 Settings → **Deploy on Push = Enabled** 확인
4. 끝! GitHub에 push하면 자동 배포됨

---

### 📌 방법 B: GitHub Actions + Docker Hub + Railway (현재 방식)

```
GitHub Push → GitHub Actions → Gradle 빌드 → Docker 이미지 빌드 → Docker Hub 푸시 → Railway가 Docker Hub 이미지 pull → 배포
```

| 장점 | 단점 |
|------|------|
| Docker Hub에 이미지 보관됨 | 설정이 복잡함 (Secrets, Webhook 등) |
| GitHub Actions에서 테스트 가능 | Docker Hub 무료 계정은 제한 있음 |
| 빌드 과정을 세밀하게 제어 가능 | Railway 자동 재배포 설정 필요 |

**필요한 설정:**
- GitHub Secrets: `DOCKER_USERNAME`, `DOCKER_TOKEN`
- GitHub Actions workflow 파일 (`.github/workflows/deploy.yml`)
- Railway: Docker Image 소스로 서비스 생성

---

## ✅ 현재 선택: 방법 A (Railway GitHub 직접 연동)

> 💡 Docker Hub를 거치지 않고, Railway가 직접 GitHub 저장소를 감지해서 Dockerfile로 이미지를 빌드하고 배포함.

---

---

## 📌 1단계: Docker Hub 설정

### 1-1. Docker Hub 계정 생성
1. https://hub.docker.com 접속
2. 회원가입 (무료)

### 1-2. Access Token 생성
1. 로그인 후 오른쪽 상단 프로필 → **Account Settings**
2. **Security** → **Personal access tokens**
3. **Generate new token** 클릭
4. Token 이름 입력 (예: `github-actions`)
5. **Access permissions**: Read & Write 선택
6. **Generate** 클릭
7. ⚠️ **토큰 복사해서 저장** (다시 볼 수 없음!)

---

## 📌 2단계: GitHub Secrets 설정

### 2-1. GitHub Repository로 이동
1. https://github.com/gks930620/doll_gacha 접속
2. **Settings** 탭 클릭

### 2-2. Secrets 추가
1. 왼쪽 메뉴: **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. 다음 2개의 Secret 추가:

| Name | Value |
|------|-------|
| `DOCKER_USERNAME` | Docker Hub 사용자명 (로그인할 때 쓰는 ID) |
| `DOCKER_PASSWORD` | 1단계에서 생성한 Access Token |

---

## 📌 3단계: GitHub Actions Workflow 확인

`.github/workflows/deploy.yml` 파일이 이미 생성되어 있음.

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - master
  pull_request:
    branches:
      - master

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Build with Gradle
        run: ./gradlew bootJar -x test

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/doll-gacha:latest
            ${{ secrets.DOCKER_USERNAME }}/doll-gacha:${{ github.sha }}
```

### Workflow 설명
| 단계 | 설명 |
|------|------|
| Checkout | GitHub에서 코드 가져오기 |
| Set up JDK 17 | Java 17 설치 |
| Grant execute permission | gradlew 실행 권한 부여 |
| Build with Gradle | `./gradlew bootJar` 실행하여 JAR 빌드 |
| Login to Docker Hub | Docker Hub 로그인 |
| Build and push | Docker 이미지 빌드 후 Docker Hub에 푸시 |

---

## 📌 4단계: GitHub Actions 실행 확인

### 4-1. 커밋 & 푸시
```bash
git add .
git commit -m "메시지"
git push
```

### 4-2. Actions 확인
1. GitHub Repository → **Actions** 탭
2. 워크플로우 실행 상태 확인
3. ✅ 초록색 체크 = 성공
4. ❌ 빨간색 X = 실패 (로그 확인 필요)

### 4-3. Docker Hub 확인
1. https://hub.docker.com 로그인
2. **Repositories** 탭에서 `doll-gacha` 이미지 확인

---

## 📌 5단계: Railway 설정

### 5-1. Railway 가입
1. https://railway.app 접속
2. **GitHub로 로그인** 권장

### 5-2. 새 프로젝트 생성
1. **New Project** 클릭
2. **Deploy from Docker Hub** 선택
3. 이미지 이름 입력: `{DOCKER_USERNAME}/doll-gacha:latest`

### 5-3. MySQL 서비스 추가 (Railway)

> ⚠️ **중요**: 앱 서비스와 별도로 MySQL 서비스를 먼저 만들어야 함!

1. 프로젝트에서 **+ New** → **Database** → **MySQL** 선택
2. 자동으로 DB 생성됨 (MySQL 서비스가 Online 상태가 될 때까지 대기)
3. MySQL 서비스 클릭 → **Variables** 탭에서 자동 생성된 환경변수 확인:

| 변수명 | 설명 |
|--------|------|
| `MYSQLHOST` | MySQL 호스트 주소 (내부 네트워크) |
| `MYSQLPORT` | MySQL 포트 번호 |
| `MYSQLDATABASE` | 데이터베이스 이름 |
| `MYSQLUSER` | 사용자명 |
| `MYSQLPASSWORD` | 비밀번호 |
| `MYSQL_ROOT_PASSWORD` | root 비밀번호 |

> 💡 **참고**: MySQL 서비스의 환경변수는 건들 필요 없음. Railway가 자동으로 생성/관리함.

### 5-4. doll-gacha 서비스 환경변수 설정 ⭐ 핵심!

> ⚠️ **Railway 환경변수 참조 문법**: `${{서비스명.변수명}}`
> 
> - MySQL 서비스의 변수를 참조할 때: `${{MySQL.MYSQLHOST}}`
> - 같은 서비스 내 변수 참조할 때: `${{VARIABLE_NAME}}`

**doll-gacha 서비스** 클릭 → **Variables** 탭에서 다음 환경변수 추가:

#### 📌 필수 환경변수

| 변수명 | 값 |
|--------|-----|
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `SPRING_DATASOURCE_URL` | `jdbc:mariadb://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?allowPublicKeyRetrieval=true&useSSL=false` |
| `SPRING_DATASOURCE_USERNAME` | `${{MySQL.MYSQLUSER}}` |
| `SPRING_DATASOURCE_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` |

#### 📌 OAuth2 환경변수 (카카오/구글 로그인용)

| 변수명 | 값 |
|--------|-----|
| `JWT_SECRET_KEY` | `your-jwt-secret-key-here` (최소 32자 이상 권장) |
| `KAKAO_CLIENT_ID` | 카카오 개발자센터에서 발급받은 REST API 키 |
| `KAKAO_CLIENT_SECRET` | 카카오 개발자센터에서 발급받은 Client Secret |
| `GOOGLE_CLIENT_ID` | 구글 클라우드 콘솔에서 발급받은 클라이언트 ID |
| `GOOGLE_CLIENT_SECRET` | 구글 클라우드 콘솔에서 발급받은 클라이언트 보안 비밀번호 |

#### ❌ 잘못된 예시 vs ✅ 올바른 예시

```bash
# ❌ 잘못된 예시 (변수가 치환되지 않음)
SPRING_DATASOURCE_URL=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}

# ✅ 올바른 예시 (Railway 문법 + MariaDB 드라이버 호환)
SPRING_DATASOURCE_URL=jdbc:mariadb://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?allowPublicKeyRetrieval=true&useSSL=false
```

> 💡 **MariaDB 드라이버 사용 시**: `jdbc:mysql://` 대신 `jdbc:mariadb://` 사용!

---

## 📌 6단계: Railway 도메인 생성

### 6-1. Railway 도메인 생성
1. **doll-gacha 서비스** 클릭
2. **Settings** 탭 → **Networking** 섹션
3. **Generate Domain** 클릭
4. `xxx.up.railway.app` 형식의 도메인 생성됨

---

## 📌 7단계: OAuth2 개발자센터 설정 ⭐ 필수!

> ⚠️ **중요**: Railway 배포 후 반드시 카카오/구글 개발자센터에서 Redirect URI를 추가해야 OAuth2 로그인이 작동함!

### 7-1. 카카오 개발자센터 설정

1. https://developers.kakao.com 접속 → 로그인
2. **내 애플리케이션** → 해당 앱 선택
3. **카카오 로그인** → **Redirect URI** 설정
4. 다음 URI 추가:
   ```
   https://xxx.up.railway.app/login/oauth2/code/kakao
   ```
   (xxx는 Railway에서 생성된 도메인으로 교체)

5. **동의항목** 확인:
   - 닉네임: 필수
   - 이메일: 선택 (필요시 비즈앱 전환)

### 7-2. 구글 클라우드 콘솔 설정

1. https://console.cloud.google.com 접속 → 로그인
2. **API 및 서비스** → **사용자 인증 정보**
3. 해당 OAuth 2.0 클라이언트 ID 클릭
4. **승인된 리디렉션 URI**에 다음 추가:
   ```
   https://xxx.up.railway.app/login/oauth2/code/google
   ```
   (xxx는 Railway에서 생성된 도메인으로 교체)

5. **저장** 클릭

### 7-3. OAuth2 설정 체크리스트

| 플랫폼 | 설정 항목 | 확인 |
|--------|----------|------|
| 카카오 | Redirect URI 추가 | ⬜ |
| 카카오 | 동의항목 설정 | ⬜ |
| 카카오 | 앱 활성화 상태 확인 | ⬜ |
| 구글 | 승인된 리디렉션 URI 추가 | ⬜ |
| 구글 | OAuth 동의 화면 설정 | ⬜ |

---

## 📌 8단계: Railway 자동 배포 설정

### ⭐ 방법 A: Railway GitHub 직접 연동 (추천)

> Railway가 GitHub 저장소를 직접 감지해서 Dockerfile로 이미지를 빌드하고 배포함.
> Docker Hub를 거치지 않음!

**설정 방법:**

1. **기존 Docker Image 서비스 삭제** (선택사항)
   - 현재 Docker Hub 이미지로 만든 서비스가 있다면 삭제

2. **새 서비스 생성 (GitHub 연동)**
   - Railway 프로젝트에서 **+ New** → **GitHub Repo** 선택
   - GitHub 저장소 (`gks930620/doll_gacha`) 연결
   - Railway가 자동으로 Dockerfile을 감지하여 빌드

3. **Deploy on Push 확인**
   - 서비스 클릭 → **Settings** 탭
   - **Source** 섹션에서 GitHub 저장소가 연결되어 있는지 확인
   - **Automatic Deploys** 또는 **Deploy on Push**가 **Enabled** 상태인지 확인

4. **환경변수 재설정**
   - 새로 만든 서비스에 5-4단계의 환경변수 다시 설정

5. **테스트**
   - GitHub에 아무 변경사항이나 커밋/푸시
   - Railway Deployments 탭에서 자동으로 빌드 시작되는지 확인

---

### 방법 B: Docker Hub + Railway (기존 방식, 참고용)

> GitHub Actions에서 Docker Hub로 이미지 푸시 → Railway가 Docker Hub 이미지 사용

**이 방법을 사용하려면:**

1. GitHub Secrets 설정:
   - `DOCKER_USERNAME`: Docker Hub 사용자명
   - `DOCKER_TOKEN`: Docker Hub Access Token

2. Railway 서비스:
   - **Docker Image** 소스로 생성
   - 이미지: `{DOCKER_USERNAME}/doll-gacha:latest`

3. Railway 자동 재배포 설정:
   - Railway는 Docker Hub 이미지 변경을 자동 감지하지 않음
   - 수동으로 **Redeploy** 버튼 클릭 필요
   - 또는 Railway CLI/API로 재배포 트리거 필요

---


## 🔧 트러블슈팅

### GitHub Actions 실패
1. **Actions** 탭에서 실패한 워크플로우 클릭
2. 각 단계별 로그 확인
3. 일반적인 원인:
   - Secrets 미설정
   - Docker Hub 로그인 실패
   - Gradle 빌드 실패

### Railway 배포 실패
1. **Deployments** 탭에서 로그 확인
2. 일반적인 원인:
   - 환경 변수 미설정
   - DB 연결 실패
   - 포트 설정 오류 (Railway는 `PORT` 환경변수 사용)

### ⚠️ DB 연결 오류: "Driver claims to not accept jdbcUrl"

**증상:**
```
Driver org.mariadb.jdbc.Driver claims to not accept jdbcUrl, jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}
```

**원인:** Railway 환경변수 참조 문법이 잘못됨

**해결:**
1. `${변수}` 형식 ❌ → `${{서비스명.변수명}}` 형식 ✅
2. `jdbc:mysql://` ❌ → `jdbc:mariadb://` ✅ (MariaDB 드라이버 사용 시)

```bash
# ✅ 올바른 설정
SPRING_DATASOURCE_URL=jdbc:mariadb://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?allowPublicKeyRetrieval=true&useSSL=false
SPRING_DATASOURCE_USERNAME=${{MySQL.MYSQLUSER}}
SPRING_DATASOURCE_PASSWORD=${{MySQL.MYSQLPASSWORD}}
```

### OAuth2 로그인 실패

**증상:** 카카오/구글 로그인 시 redirect_uri 오류

**원인:** 개발자센터에 Railway 도메인 Redirect URI 미등록

**해결:**
1. 카카오: https://developers.kakao.com → 앱 설정 → Redirect URI 추가
2. 구글: https://console.cloud.google.com → OAuth 클라이언트 → 승인된 리디렉션 URI 추가
3. URI 형식: `https://xxx.up.railway.app/login/oauth2/code/kakao` (또는 google)

---

## 📝 체크리스트

### 방법 A 사용 시 (Railway GitHub 직접 연동 - 추천)
- [ ] Railway 프로젝트 생성
- [ ] Railway MySQL 서비스 추가
- [ ] Railway에서 GitHub Repo로 서비스 생성
- [ ] Deploy on Push 활성화 확인
- [ ] Railway 서비스 환경변수 설정
- [ ] Railway 도메인 생성
- [ ] 카카오 개발자센터 Redirect URI 추가
- [ ] 구글 클라우드 콘솔 Redirect URI 추가
- [ ] GitHub 커밋 & 푸시로 자동 배포 테스트

### 방법 B 사용 시 (Docker Hub 경유)
- [ ] Docker Hub 계정 생성
- [ ] Docker Hub Access Token 생성
- [ ] GitHub Secrets 설정 (DOCKER_USERNAME, DOCKER_TOKEN)
- [ ] GitHub Actions 워크플로우 파일 생성
- [ ] 커밋 & 푸시
- [ ] GitHub Actions 성공 확인
- [ ] Docker Hub에 이미지 업로드 확인
- [ ] Railway 프로젝트 생성 (Docker Image 소스)
- [ ] Railway MySQL 서비스 추가
- [ ] Railway doll-gacha 서비스 환경변수 설정
- [ ] Railway 도메인 생성
- [ ] 카카오 개발자센터 Redirect URI 추가
- [ ] 구글 클라우드 콘솔 Redirect URI 추가
- [ ] 수동 Redeploy 또는 자동화 설정

---

## 🎯 현재 진행 상황

| 단계 | 상태 | 설명 |
|------|------|------|
| MySQL 서비스 | ✅ 완료 | Railway에 MySQL 서비스 생성됨 (Online) |
| doll-gacha 서비스 | ✅ 완료 | 환경변수 설정 완료 (MariaDB 형식) |
| 도메인 생성 | ✅ 완료 | `doll-gacha-production.up.railway.app` |
| OAuth2 설정 | ⏳ 대기중 | 카카오/구글 개발자센터 Redirect URI 추가 필요 |
| CI/CD | 🔧 전환중 | 방법 A (Railway GitHub 직접 연동)로 전환 권장 |

---

## 🚀 다음 할 일

1. **Railway에서 GitHub 저장소 직접 연동** (방법 A로 전환)
   - 기존 Docker Image 서비스 → GitHub Repo 서비스로 변경
   
2. **카카오/구글 개발자센터에서 Redirect URI 추가** (7단계 참조)

3. **GitHub 커밋 & 푸시하여 자동 배포 테스트**

