# 🚀 실제 서비스 배포 가이드

로컬에서 Docker로 잘 돌아가는 것을 확인했으니, 이제 **인터넷에서 누구나 접속**할 수 있게 배포해봅시다!

---

## 📋 목차
0. [배포 개념 이해하기](#0-배포-개념-이해하기)
1. [배포 방식 비교](#1-배포-방식-비교)
2. [Docker Hub에 이미지 올리기](#2-docker-hub에-이미지-올리기)
3. [클라우드 서비스 배포](#3-클라우드-서비스-배포)
4. [도메인 연결](#4-도메인-연결)

---

## 0. 배포 개념 이해하기

### 🐳 Docker 용어 정리

| 용어 | 정의 | 비유 |
|------|------|------|
| **이미지** | 앱 + 실행환경 + 설정이 담긴 패키지 | 붕어빵 틀, USB 설치디스크 |
| **컨테이너** | 이미지를 실행한 인스턴스 | 구워진 붕어빵, 실행 중인 프로그램 |
| **Docker Hub** | 이미지 저장소 | GitHub (코드 대신 이미지 저장) |

### 📦 Docker 이미지 안에 들어있는 것

```
┌─────────────────────────────────────┐
│         Docker 이미지               │
├─────────────────────────────────────┤
│  ✅ OS (경량 리눅스 - Alpine)       │
│  ✅ Java 17 (JRE)                   │
│  ✅ 당신의 앱 (JAR 파일)            │
│  ✅ 설정 파일들                     │
│  ✅ 시간대, 환경변수                │
└─────────────────────────────────────┘
```

**즉, 이미지 = 앱 실행에 필요한 모든 것!**

---

### 🚀 배포 방식 2가지

#### 방식 A: Docker Hub 경유 (직접 서버 관리)

```
  [로컬 PC]              [Docker Hub]           [서버 (Oracle/AWS)]
      │                       │                        │
      │ 1. docker build       │                        │
      │ (이미지 생성)         │                        │
      │                       │                        │
      │ 2. docker push        │                        │
      ├──────────────────────▶│                        │
      │                       │                        │
      │                       │  3. docker pull        │
      │                       │◀───────────────────────┤
      │                       │                        │
      │                       │  4. docker run         │
      │                       │                   ┌────┴────┐
      │                       │                   │ 🚀 실행 │
      │                       │                   └─────────┘

📌 특징: 빌드, 업로드, 실행 전부 내가 직접
📌 사용처: AWS EC2, Oracle Cloud, 자체 서버
```

#### 방식 B: PaaS 자동 배포 (Railway, Render)

```
  [GitHub]                              [Railway/Render 서버]
      │                                        │
      │  git push                              │
      ├───────────────────────────────────────▶│
      │                                        │
      │                        1. 코드 감지     │
      │                        2. docker build │ ← 자동!
      │                        3. docker run   │ ← 자동!
      │                                   ┌────┴────┐
      │                                   │ 🚀 실행 │
      │                                   └─────────┘

📌 특징: git push만 하면 알아서 빌드 + 배포
📌 사용처: Railway, Render, Fly.io
```

---

### 📋 두 방식 비교

| | Docker Hub 경유 | Railway/Render |
|---|---|---|
| **이미지 빌드** | 내가 직접 (`docker build`) | ✅ 자동 |
| **이미지 업로드** | 내가 직접 (`docker push`) | ✅ 자동 (내부 처리) |
| **서버 실행** | 내가 직접 (`docker run`) | ✅ 자동 |
| **서버 관리** | 내가 직접 (보안, 업데이트 등) | ✅ 알아서 해줌 |
| **장점** | 완전한 제어, 무료 가능 | 클릭 몇 번이면 끝 |
| **단점** | 명령어 다 쳐야 함, 복잡 | 세부 설정 제한, 유료 |
| **추천 대상** | 실무 경험 쌓고 싶은 분 | 빠르게 배포하고 싶은 분 |

---

## 1. 배포 방식 비교

### 🤔 어디에 배포할까?

| 서비스 | 난이도 | 월 비용 | 방식 | 특징 |
|--------|--------|---------|------|------|
| **Railway** | ⭐ 쉬움 | 무료~$5 | GitHub 자동 | git push만 하면 끝! DB도 클릭으로 추가 |
| **Render** | ⭐ 쉬움 | 무료~$7 | GitHub 자동 | 무료 티어 있음, PostgreSQL만 지원 |
| **Fly.io** | ⭐⭐ 보통 | 무료~$5 | Docker 직접 | CLI 도구 사용, 글로벌 배포 |
| **Oracle Cloud** | ⭐⭐ 보통 | **평생 무료** | Docker Hub | 진짜 서버 경험, 한국 리전 |
| **AWS EC2** | ⭐⭐⭐ 어려움 | $5~20 | Docker Hub | 실무 표준, 복잡하지만 강력 |
| **Naver Cloud** | ⭐⭐ 보통 | 유료 | Docker Hub | 한국 서버, 빠른 속도 |

### 🎯 추천 선택 가이드

```
질문 1: 돈 쓸 수 있어?
  │
  ├─ YES → Railway (가장 쉬움, 월 $5 정도)
  │
  └─ NO → 질문 2: 서버 직접 만져보고 싶어?
              │
              ├─ YES → Oracle Cloud (무료 + 실무 경험)
              │
              └─ NO → Render 무료 티어 (제한 있지만 무료)
```

### 📊 상세 비교

| 항목 | Railway | Render | Oracle Cloud |
|------|---------|--------|--------------|
| **설정 시간** | 10분 | 15분 | 1시간+ |
| **DB 지원** | MariaDB ✅ | PostgreSQL만 | 직접 설치 |
| **무료 한도** | $5 크레딧/월 | 750시간/월 | 평생 무료 |
| **슬립 모드** | 없음 | 15분 미사용시 슬립 | 없음 |
| **커스텀 도메인** | ✅ 무료 | ✅ 무료 | ✅ 직접 설정 |
| **HTTPS** | ✅ 자동 | ✅ 자동 | 직접 설정 |
| **한국 서버** | ❌ | ❌ | ✅ 서울 리전 |

---

## 2. Docker Hub에 이미지 올리기

Docker Hub는 **Docker 이미지 저장소**입니다.
GitHub가 코드를 저장하듯, Docker Hub는 Docker 이미지를 저장합니다.

### Step 1: Docker Hub 계정 만들기
1. https://hub.docker.com 접속
2. Sign Up (무료)
3. 이메일 인증

### Step 2: Docker Hub 로그인
```powershell
# Docker Hub 로그인
docker login

# Username: (Docker Hub 아이디 입력)
# Password: (Docker Hub 비밀번호 입력)
# Login Succeeded 나오면 성공!
```

### Step 3: 이미지 태그 붙이기
```powershell
# 현재 이미지 확인
docker images

# 이미지에 Docker Hub 형식으로 태그 붙이기
# 형식: docker tag [로컬이미지명] [DockerHub아이디]/[저장소명]:[태그]
docker tag doll_gacha-app your-dockerhub-id/doll-gacha:latest
docker tag doll_gacha-app your-dockerhub-id/doll-gacha:v1.0.0

# 예시 (아이디가 "john123"인 경우)
# docker tag doll_gacha-app john123/doll-gacha:latest
```

### Step 4: Docker Hub에 푸시
```powershell
# 이미지 업로드
docker push your-dockerhub-id/doll-gacha:latest
docker push your-dockerhub-id/doll-gacha:v1.0.0

# 업로드 완료 후 https://hub.docker.com 에서 확인 가능
```

### 💡 Docker Hub를 쓰는 이유
- 어떤 서버에서든 `docker pull`로 이미지 다운로드 가능
- 버전 관리 (v1.0.0, v1.1.0, latest 등)
- CI/CD 파이프라인에서 활용

---

## 3. 클라우드 서비스 배포

### 🚂 Option A: Railway (가장 쉬움, 추천!)

Railway는 GitHub 연동으로 **자동 배포**해주는 서비스입니다.

#### Step 1: Railway 가입
1. https://railway.app 접속
2. "Start a New Project" 클릭
3. GitHub 계정으로 로그인

#### Step 2: 프로젝트 생성
1. "Deploy from GitHub repo" 선택
2. 이 프로젝트의 GitHub 저장소 선택
3. Railway가 자동으로 Dockerfile 감지

#### Step 3: 환경변수 설정
Railway 대시보드에서:
1. Variables 탭 클릭
2. 다음 환경변수 추가:
```
KAKAO_CLIENT_ID=xxx
KAKAO_CLIENT_SECRET=xxx
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
JWT_SECRET_KEY=xxx
APP_BASE_URL=https://your-app.railway.app
```

#### Step 4: 데이터베이스 추가
1. "+ New" 클릭
2. "Database" → "MariaDB" 선택
3. 자동으로 DB 생성됨
4. 연결 정보를 앱 환경변수에 추가

#### Step 5: 배포 확인
- Railway가 자동으로 빌드 및 배포
- 제공되는 URL로 접속 (예: https://doll-gacha-production.up.railway.app)

---

### 🎨 Option B: Render

#### Step 1: Render 가입
1. https://render.com 접속
2. GitHub 계정으로 로그인

#### Step 2: Web Service 생성
1. "New +" → "Web Service"
2. GitHub 저장소 연결
3. 설정:
   - Name: `doll-gacha`
   - Environment: `Docker`
   - Plan: `Free` (무료)

#### Step 3: 환경변수 설정
- Environment Variables에서 `.env` 내용 추가

#### Step 4: 데이터베이스 생성
1. "New +" → "PostgreSQL" (Render는 MariaDB 미지원)
2. 또는 외부 DB 서비스 사용 (PlanetScale, Supabase 등)

---

### ☁️ Option C: Oracle Cloud (무료 서버)

Oracle Cloud는 **평생 무료** 서버를 제공합니다!

#### Step 1: 계정 생성
1. https://cloud.oracle.com 접속
2. "무료로 시작하기" 클릭
3. 신용카드 필요 (결제는 안 됨)

#### Step 2: VM 인스턴스 생성
1. Compute → Instances → Create Instance
2. Image: Ubuntu 22.04
3. Shape: VM.Standard.E2.1.Micro (무료)
4. SSH 키 다운로드

#### Step 3: 서버 접속
```powershell
# SSH 접속
ssh -i your-key.pem ubuntu@<서버IP>
```

#### Step 4: Docker 설치
```bash
# 서버에서 실행
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
# 재접속
```

#### Step 5: 앱 배포
```bash
# Docker Hub에서 이미지 가져오기
docker pull your-dockerhub-id/doll-gacha:latest

# 또는 docker-compose.yml 복사 후 실행
docker-compose up -d
```

#### Step 6: 포트 열기
Oracle Cloud Console → Networking → Virtual Cloud Networks
→ Security Lists → Ingress Rules에서 8080 포트 열기

---

## 4. 도메인 연결

### 무료 도메인 옵션
- **Freenom**: .tk, .ml 등 무료 도메인 (불안정)
- **Railway/Render**: 기본 제공 서브도메인

### 유료 도메인 (추천)
- **가비아**: .com 연 15,000원
- **Cloudflare**: 원가에 판매
- **Namecheap**: 저렴함

### 도메인 연결 방법
1. 도메인 구매
2. DNS 설정에서 A 레코드 추가
   - Type: A
   - Name: @ (또는 www)
   - Value: 서버 IP 주소
3. HTTPS 설정 (Let's Encrypt 무료)

---

## 5. 실제 배포 체크리스트

### 🔧 로컬 Docker에서 먼저 확인할 것

**로컬 Docker에서 되면 → 클라우드에서도 거의 된다!**

하지만 몇 가지 차이점이 있습니다:

| 기능 | 로컬에서 해결하면? | 클라우드 추가 작업 |
|------|-------------------|-------------------|
| 파일 업로드/미리보기 | ✅ 해결됨 | PaaS는 외부 저장소 필요할 수 있음 |
| 카카오/구글 로그인 | ⚠️ localhost로만 테스트 | redirect URI 변경 필수! |
| HTTPS | 불필요 | Railway/Render는 자동, VM은 직접 설정 |

### 📁 파일 저장 주의사항

```
로컬 Docker:
  → ./uploads 볼륨 마운트 → 파일 유지됨 ✅

클라우드 PaaS (Railway/Render):
  → 컨테이너 재시작하면 파일 사라짐! ❌
  → 해결: AWS S3, Cloudflare R2 등 외부 저장소

클라우드 VM (Oracle/AWS EC2):
  → 서버 디스크에 직접 저장 가능 ✅
```

### 배포 전 확인
- [ ] 모든 환경변수 설정 완료
- [ ] `ddl-auto: update` 확인 (create 금지!)
- [ ] OAuth 리다이렉트 URL 변경 (localhost → 실제 도메인)
- [ ] CORS 설정 확인
- [ ] 민감한 정보 코드에 없는지 확인

### OAuth 리다이렉트 URL 변경

**카카오 개발자 콘솔:**
1. https://developers.kakao.com 접속
2. 내 애플리케이션 → 앱 선택
3. 카카오 로그인 → Redirect URI 추가
   - `https://your-domain.com/login/oauth2/code/kakao`

**구글 클라우드 콘솔:**
1. https://console.cloud.google.com 접속
2. APIs & Services → Credentials
3. OAuth 2.0 Client → 승인된 리디렉션 URI 추가
   - `https://your-domain.com/login/oauth2/code/google`

---

## 🎯 가장 빠른 배포 방법 (요약)

### Railway로 10분 안에 배포하기

```powershell
# 1. GitHub에 코드 푸시
git add .
git commit -m "Ready for deployment"
git push origin main

# 2. Railway 접속
# https://railway.app

# 3. GitHub 저장소 연결

# 4. 환경변수 설정

# 5. MariaDB 추가

# 6. 배포 완료! 🎉
```

---

## 🎯 배포 방법 선택하기

문서를 다 읽었으면, 아래에서 원하는 방식을 선택하세요!

### Option 1: 🚂 Railway (추천 - 가장 쉬움)
```
✅ 장점: git push만 하면 자동 배포, DB 클릭으로 추가
❌ 단점: 월 $5 정도 비용, 한국 서버 없음
⏱️ 소요시간: 10분
📌 추천: 빠르게 배포하고 싶은 분
```

### Option 2: 🎨 Render (무료 가능)
```
✅ 장점: 무료 티어 있음, 설정 쉬움
❌ 단점: MariaDB 미지원(PostgreSQL만), 15분 미사용시 슬립
⏱️ 소요시간: 15분
📌 추천: 무료로 테스트해보고 싶은 분
```

### Option 3: ☁️ Oracle Cloud (무료 + 실무 경험)
```
✅ 장점: 평생 무료, 진짜 서버 경험, 한국 서버
❌ 단점: 설정 복잡, SSH/리눅스 명령어 필요
⏱️ 소요시간: 1시간+
📌 추천: 실무 경험 쌓고 싶은 분, 무료 원하는 분
```

---

## 📌 다음 단계

**원하는 방식을 선택해서 알려주세요!**

1. **"Railway로 할래"** → Railway 배포 상세 가이드
2. **"Render로 할래"** → Render 배포 상세 가이드  
3. **"Oracle로 할래"** → Oracle Cloud 배포 상세 가이드
4. **"Docker Hub 먼저"** → Docker Hub 업로드부터 진행

선택하면 바로 진행합니다! 🚀

