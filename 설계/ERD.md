# ERD (Entity Relationship Diagram)

## 📊 전체 관계도

```
User (1) ─────< Review (N) >───── (1) DollShop
                  │
                  │ (1)
                  │
                  ↓
            ReviewImage (N)
```

## 📋 엔티티 및 관계

### 1. User (사용자)
- **테이블명**: `users`
- **설명**: 서비스 사용자 (카카오/구글 OAuth, 일반 로그인)

### 2. DollShop (인형뽑기방)
- **테이블명**: `doll_shop`
- **설명**: 전국 인형뽑기방 정보 (카카오맵 API에서 수집)

### 3. Review (리뷰)
- **테이블명**: `reviews`
- **설명**: 사용자가 작성한 인형뽑기방 후기

### 4. ReviewImage (리뷰 이미지)
- **테이블명**: `review_images`
- **설명**: 리뷰에 첨부된 이미지

---

## 🔗 관계 설명

### 1️⃣ User → Review (1:N, 단방향)
- 한 사용자는 여러 리뷰를 작성할 수 있음
- Review만 User를 참조 (ManyToOne)
- FK: `reviews.user_id` → `users.id`

### 2️⃣ DollShop → Review (1:N, 단방향)
- 한 인형뽑기방은 여러 리뷰를 받을 수 있음
- Review만 DollShop을 참조 (ManyToOne)
- FK: `reviews.doll_shop_id` → `doll_shop.id`

### 3️⃣ Review ↔ ReviewImage (1:N, 양방향)
- 한 리뷰는 여러 이미지를 가질 수 있음
- 서로 참조 (OneToMany ↔ ManyToOne)
- FK: `review_images.review_id` → `reviews.id`
- CASCADE: 리뷰 삭제 시 이미지도 함께 삭제

---

## 💡 주요 특징

- **User와 DollShop은 직접적인 관계 없음** - Review를 통해 간접 연결
- **리뷰 소프트 삭제** - `is_deleted` 플래그 사용
- **OAuth 지원** - 카카오, 구글, 일반 로그인
- **지역 검색** - `gubun1`(시/도), `gubun2`(시/군/구)로 빠른 검색

