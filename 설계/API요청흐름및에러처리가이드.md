# 🔄 API 요청 흐름 및 에러 처리 가이드

> 이 문서는 프로젝트의 모든 API 요청이 어떻게 처리되는지, 성공/실패 시 어떤 코드가 실행되어 어떤 응답이 생성되는지를 정리합니다.

---

## 📋 목차

1. [필터 체인 구조](#1-필터-체인-구조)
2. [로그인 관련 흐름](#2-로그인-관련-흐름)
3. [인증이 필요한 API 흐름](#3-인증이-필요한-api-흐름)
4. [비즈니스 로직 에러 흐름](#4-비즈니스-로직-에러-흐름)
5. [유효성 검증 에러 흐름](#5-유효성-검증-에러-흐름)
6. [응답 형식 정리](#6-응답-형식-정리)

---

## 1. 필터 체인 구조

### 1.1 요청 처리 순서

```
[클라이언트 요청]
       ↓
┌──────────────────────────────────────────────────────────────┐
│  1. JwtAccessTokenCheckAndSaveUserInfoFilter                 │
│     - 토큰 추출 및 검증                                        │
│     - 유효하면 SecurityContext에 인증 정보 저장                 │
└──────────────────────────────────────────────────────────────┘
       ↓
┌──────────────────────────────────────────────────────────────┐
│  2. JwtLoginFilter ("/api/login" URL만 동작)                  │
│     - 로그인 요청 처리                                         │
│     - JWT 토큰 발급                                           │
└──────────────────────────────────────────────────────────────┘
       ↓
┌──────────────────────────────────────────────────────────────┐
│  3. Spring Security Authorization                            │
│     - URL별 인증/인가 검사                                     │
│     - .authenticated() 설정된 URL에 인증 없으면 차단            │
└──────────────────────────────────────────────────────────────┘
       ↓
┌──────────────────────────────────────────────────────────────┐
│  4. Controller → Service → Repository                        │
│     - 비즈니스 로직 처리                                       │
└──────────────────────────────────────────────────────────────┘
       ↓
┌──────────────────────────────────────────────────────────────┐
│  5. GlobalExceptionHandler (예외 발생 시)                     │
│     - 모든 예외를 통합 처리                                    │
└──────────────────────────────────────────────────────────────┘
       ↓
[응답 반환]
```

### 1.2 필터 등록 위치

**📁 파일:** `SecurityConfig.java` (Line 167-174)

```java
http
    .addFilterAt(
        new JwtLoginFilter(..., "/api/login"),
        UsernamePasswordAuthenticationFilter.class)
    .addFilterBefore(
        new JwtAccessTokenCheckAndSaveUserInfoFilter(jwtUtil, customUserDetailsService),
        UsernamePasswordAuthenticationFilter.class);
```

---

## 2. 로그인 관련 흐름

### 2.1 ✅ 로그인 성공 (ID/PW 일치)

**요청:**
```http
POST /api/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "correct_password"
}
```

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter.doFilterInternal()
    │
    ├─ 📁 JwtAccessTokenCheckAndSaveUserInfoFilter.java (Line 35-36)
    │   String token = getTokenFromRequest(request);  // 토큰 없음 → null
    │   if (token == null) { chain.doFilter(); return; }  // 그냥 통과
    │
    ↓
[2] JwtLoginFilter.attemptAuthentication()
    │
    ├─ 📁 JwtLoginFilter.java (Line 40-56)
    │   // /api/login URL이므로 이 필터 동작
    │   Map<String, String> credentials = new ObjectMapper()
    │       .readValue(request.getInputStream(), ...);
    │   String username = credentials.get("username");
    │   String password = credentials.get("password");
    │   return authenticationManager.authenticate(authRequest);
    │
    ↓
[3] CustomUserDetailsService.loadUserByUsername()
    │
    ├─ 📁 CustomUserDetailsService.java (Line 19-25)
    │   UserEntity userEntity = userRepository.findByUsername(username)
    │       .orElseThrow(() -> new UsernameNotFoundException(...));
    │   return new CustomUserAccount(UserDTO.from(userEntity));
    │
    ↓
[4] Spring Security가 비밀번호 검증 (BCryptPasswordEncoder)
    │
    ↓
[5] JwtLoginFilter.successfulAuthentication()
    │
    ├─ 📁 JwtLoginFilter.java (Line 63-93)
    │   String accessToken = jwtUtil.createAccessToken(username);
    │   String refreshToken = jwtUtil.createRefreshToken(username);
    │   refreshService.saveRefresh(refreshToken);
    │   
    │   // 브라우저: 쿠키 설정
    │   addCookie(response, "access_token", accessToken, -1);
    │   addCookie(response, "refresh_token", refreshToken, -1);
    │   response.setStatus(HttpServletResponse.SC_OK);
    │
    ↓
[응답] HTTP 200 OK + Set-Cookie 헤더
```

**응답:**
```http
HTTP/1.1 200 OK
Set-Cookie: access_token=eyJhbGc...; HttpOnly; Path=/
Set-Cookie: refresh_token=eyJhbGc...; HttpOnly; Path=/
```

---

### 2.2 ❌ 로그인 실패 (ID/PW 불일치)

**요청:**
```http
POST /api/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "wrong_password"
}
```

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter.doFilterInternal()
    │
    ├─ 토큰 없음 → 그냥 통과
    │
    ↓
[2] JwtLoginFilter.attemptAuthentication()
    │
    ├─ 📁 JwtLoginFilter.java (Line 53)
    │   return authenticationManager.authenticate(authRequest);
    │   // 비밀번호 불일치 → AuthenticationException 발생!
    │
    ↓
[3] JwtLoginFilter.unsuccessfulAuthentication()
    │
    ├─ 📁 JwtLoginFilter.java (Line 107-117)
    │   response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    │   response.setContentType("application/json;charset=UTF-8");
    │   
    │   ErrorResponse errorResponse = ErrorResponse.of(
    │       "아이디 또는 비밀번호가 일치하지 않습니다.",
    │       "AUTHENTICATION_FAILED"
    │   );
    │   response.getWriter().write(new ObjectMapper().writeValueAsString(errorResponse));
    │
    ↓
[응답] HTTP 401 Unauthorized
```

**응답:**
```json
{
  "success": false,
  "message": "아이디 또는 비밀번호가 일치하지 않습니다.",
  "errorCode": "AUTHENTICATION_FAILED",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

### 2.3 ❌ 로그인 실패 (존재하지 않는 사용자)

**요청:**
```http
POST /api/login
Content-Type: application/json

{
  "username": "nonexistent",
  "password": "any_password"
}
```

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter → 통과
    │
    ↓
[2] JwtLoginFilter.attemptAuthentication()
    │
    ↓
[3] CustomUserDetailsService.loadUserByUsername()
    │
    ├─ 📁 CustomUserDetailsService.java (Line 20-22)
    │   UserEntity userEntity = userRepository.findByUsername(username)
    │       .orElseThrow(() -> new UsernameNotFoundException(
    │           "사용자를 찾을 수 없습니다: " + username));
    │   // UsernameNotFoundException 발생!
    │
    ↓
[4] Spring Security가 AuthenticationException으로 변환
    │
    ↓
[5] JwtLoginFilter.unsuccessfulAuthentication() 실행
    │
    ↓
[응답] HTTP 401 + ErrorResponse
```

---

## 3. 인증이 필요한 API 흐름

### 3.1 ✅ 로그인한 사용자가 게시글 작성

**요청:**
```http
POST /api/community
Cookie: access_token=eyJhbGc...
Content-Type: application/json

{
  "title": "테스트 제목",
  "content": "테스트 내용입니다."
}
```

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter.doFilterInternal()
    │
    ├─ 📁 JwtAccessTokenCheckAndSaveUserInfoFilter.java (Line 35-67)
    │   String token = getTokenFromRequest(request);  // 쿠키에서 토큰 추출
    │   
    │   String tokenType = jwtUtil.getTokenType(token);  // "access"
    │   
    │   if (!jwtUtil.validateToken(token)) { ... }  // 유효함 → 통과
    │   
    │   // ✅ SecurityContext에 인증 정보 저장
    │   String username = jwtUtil.extractUsername(token);
    │   UserDetails userDetails = userDetailsService.loadUserByUsername(username);
    │   SecurityContextHolder.getContext().setAuthentication(authenticationToken);
    │   
    │   chain.doFilter(request, response);  // 인증된 상태로 통과!
    │
    ↓
[2] JwtLoginFilter
    │
    ├─ /api/login이 아니므로 동작 안 함 → 통과
    │
    ↓
[3] Spring Security Authorization
    │
    ├─ 📁 SecurityConfig.java (Line 107-109)
    │   .requestMatchers(HttpMethod.POST, "/api/community", "/api/community/**")
    │   .authenticated()
    │   // SecurityContext에 인증 정보 있음 → 통과!
    │
    ↓
[4] CommunityController.createCommunity()
    │
    ├─ 📁 CommunityController.java (Line 51-57)
    │   @PostMapping
    │   public ResponseEntity<ApiResponse<Long>> createCommunity(
    │       @Valid @RequestBody CommunityCreateDTO createDTO,
    │       @AuthenticationPrincipal CustomUserAccount userAccount) {
    │       
    │       Long communityId = communityService.createCommunity(
    │           createDTO, userAccount.getUsername());
    │       return ResponseEntity.status(HttpStatus.CREATED)
    │           .body(ApiResponse.success("게시글이 작성되었습니다", communityId));
    │   }
    │
    ↓
[5] CommunityService.createCommunity()
    │
    ├─ 📁 CommunityService.java (Line 29-35)
    │   UserEntity user = userRepository.findByUsername(username)
    │       .orElseThrow(() -> EntityNotFoundException.of("사용자", username));
    │   CommunityEntity community = createDTO.toEntity(user);
    │   CommunityEntity savedCommunity = communityRepository.save(community);
    │   return savedCommunity.getId();
    │
    ↓
[응답] HTTP 201 Created
```

**응답:**
```json
{
  "success": true,
  "message": "게시글이 작성되었습니다",
  "data": 123
}
```

---

### 3.2 ❌ 로그인 안 한 사용자가 게시글 작성 시도

**요청:**
```http
POST /api/community
Content-Type: application/json
(토큰 없음)

{
  "title": "테스트 제목",
  "content": "테스트 내용입니다."
}
```

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter.doFilterInternal()
    │
    ├─ 📁 JwtAccessTokenCheckAndSaveUserInfoFilter.java (Line 35-39)
    │   String token = getTokenFromRequest(request);  // null
    │   if (token == null) {
    │       chain.doFilter(request, response);  // 인증 없이 통과
    │       return;
    │   }
    │
    ↓
[2] JwtLoginFilter → /api/login 아니므로 통과
    │
    ↓
[3] Spring Security Authorization
    │
    ├─ 📁 SecurityConfig.java (Line 107-109)
    │   .requestMatchers(HttpMethod.POST, "/api/community", "/api/community/**")
    │   .authenticated()
    │   // SecurityContext에 인증 정보 없음 → 차단!
    │
    ↓
[4] AuthenticationEntryPoint 실행
    │
    ├─ 📁 SecurityConfig.java (Line 178-205)
    │   http.exceptionHandling(ex -> ex
    │       .authenticationEntryPoint((request, response, authException) -> {
    │           response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    │           response.setContentType("application/json;charset=UTF-8");
    │           
    │           String errorCode = "NOT_AUTHENTICATED";
    │           String errorMessage = "인증이 필요합니다.";
    │           
    │           // ErrorResponse 형식으로 응답
    │           String jsonResponse = String.format(
    │               "{\"success\":false,\"message\":\"%s\",\"errorCode\":\"%s\",...}",
    │               errorMessage, errorCode);
    │           response.getWriter().write(jsonResponse);
    │       })
    │   );
    │
    ↓
[응답] HTTP 401 Unauthorized
```

**응답:**
```json
{
  "success": false,
  "message": "인증이 필요합니다.",
  "errorCode": "NOT_AUTHENTICATED",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

### 3.3 ❌ Access Token 만료 상태로 요청

**요청:**
```http
POST /api/community
Cookie: access_token=eyJhbGc...(만료된 토큰)
Content-Type: application/json

{
  "title": "테스트 제목",
  "content": "테스트 내용입니다."
}
```

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter.doFilterInternal()
    │
    ├─ 📁 JwtAccessTokenCheckAndSaveUserInfoFilter.java (Line 50-54)
    │   String token = getTokenFromRequest(request);  // 토큰 있음
    │   
    │   if (!jwtUtil.validateToken(token)) {  // ❌ 만료됨!
    │       request.setAttribute("ERROR_CAUSE", "토큰만료");
    │       chain.doFilter(request, response);  // 인증 없이 통과
    │       return;
    │   }
    │
    ↓
[2] Spring Security Authorization → 인증 없음 → 차단!
    │
    ↓
[3] AuthenticationEntryPoint 실행
    │
    ├─ 📁 SecurityConfig.java (Line 178-205)
    │   String errorCause = request.getAttribute("ERROR_CAUSE");  // "토큰만료"
    │   
    │   if ("토큰만료".equals(errorCause)) {
    │       errorMessage = "Access Token이 만료되었습니다. 토큰을 재발급해주세요.";
    │       errorCode = "TOKEN_EXPIRED";
    │   }
    │
    ↓
[응답] HTTP 401 Unauthorized
```

**응답:**
```json
{
  "success": false,
  "message": "Access Token이 만료되었습니다. 토큰을 재발급해주세요.",
  "errorCode": "TOKEN_EXPIRED",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

## 4. 비즈니스 로직 에러 흐름

### 4.1 ❌ 로그인한 사용자가 다른 사람 글 삭제 시도

**요청:**
```http
DELETE /api/community/123
Cookie: access_token=eyJhbGc...(userB의 토큰)
```
> 게시글 123의 작성자는 userA

**흐름:**

```
[1] JwtAccessTokenCheckAndSaveUserInfoFilter.doFilterInternal()
    │
    ├─ 토큰 유효 → SecurityContext에 userB 인증 정보 저장
    │
    ↓
[2] Spring Security Authorization
    │
    ├─ 📁 SecurityConfig.java (Line 113-115)
    │   .requestMatchers(HttpMethod.DELETE, "/api/community/**")
    │   .authenticated()
    │   // userB 인증됨 → 통과!
    │
    ↓
[3] CommunityController.deleteCommunity()
    │
    ├─ 📁 CommunityController.java (Line 75-81)
    │   @DeleteMapping("/{communityId}")
    │   public ResponseEntity<ApiResponse<Void>> deleteCommunity(
    │       @PathVariable Long communityId,
    │       @AuthenticationPrincipal CustomUserAccount userAccount) {
    │       
    │       communityService.deleteCommunity(communityId, userAccount.getUsername());
    │       // userAccount.getUsername() = "userB"
    │   }
    │
    ↓
[4] CommunityService.deleteCommunity()
    │
    ├─ 📁 CommunityService.java (Line 77-87)
    │   CommunityEntity community = communityRepository.findByIdAndIsDeletedFalse(communityId)
    │       .orElseThrow(() -> EntityNotFoundException.of("게시글", communityId));
    │   
    │   // community.getUser().getUsername() = "userA"
    │   // username = "userB"
    │   if (!community.isWrittenBy(username)) {  // userA != userB
    │       throw AccessDeniedException.forDelete("게시글");  // ❌ 예외 발생!
    │   }
    │
    ↓
[5] GlobalExceptionHandler.handleBusinessException()
    │
    ├─ 📁 GlobalExceptionHandler.java (Line 31-37)
    │   @ExceptionHandler(BusinessException.class)
    │   public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException e) {
    │       log.warn("Business Exception: {} - {}", e.getErrorCode(), e.getMessage());
    │       
    │       ErrorResponse response = ErrorResponse.of(e.getMessage(), e.getErrorCode());
    │       return ResponseEntity.status(e.getStatus()).body(response);
    │       // e.getStatus() = HttpStatus.FORBIDDEN (403)
    │   }
    │
    ↓
[응답] HTTP 403 Forbidden
```

**응답:**
```json
{
  "success": false,
  "message": "본인의 게시글만 삭제할 수 있습니다.",
  "errorCode": "ACCESS_DENIED",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

### 4.2 ❌ 존재하지 않는 게시글 조회

**요청:**
```http
GET /api/community/999999
```

**흐름:**

```
[1] 필터 통과 (공개 API)
    │
    ↓
[2] CommunityController.getCommunityDetail()
    │
    ├─ 📁 CommunityController.java (Line 40-44)
    │   @GetMapping("/{communityId}")
    │   public ResponseEntity<ApiResponse<CommunityDTO>> getCommunityDetail(
    │       @PathVariable Long communityId) {
    │       CommunityDTO community = communityService.getCommunityDetail(communityId);
    │   }
    │
    ↓
[3] CommunityService.getCommunityDetail()
    │
    ├─ 📁 CommunityService.java (Line 50-58)
    │   CommunityEntity community = communityRepository
    │       .findByIdAndIsDeletedFalse(communityId)  // 999999 없음!
    │       .orElseThrow(() -> EntityNotFoundException.of("게시글", communityId));
    │   // EntityNotFoundException 발생!
    │
    ↓
[4] GlobalExceptionHandler.handleBusinessException()
    │
    ├─ 📁 GlobalExceptionHandler.java (Line 31-37)
    │   // EntityNotFoundException extends BusinessException
    │   // e.getStatus() = HttpStatus.NOT_FOUND (404)
    │   // e.getMessage() = "게시글을(를) 찾을 수 없습니다: 999999"
    │   // e.getErrorCode() = "NOT_FOUND"
    │
    ↓
[응답] HTTP 404 Not Found
```

**응답:**
```json
{
  "success": false,
  "message": "게시글을(를) 찾을 수 없습니다: 999999",
  "errorCode": "NOT_FOUND",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

### 4.3 ❌ 하루에 같은 가게 리뷰 2번 작성 시도

**요청:**
```http
POST /api/reviews
Cookie: access_token=eyJhbGc...
Content-Type: application/json

{
  "dollShopId": 857,
  "rating": 5,
  "machineStrength": 3,
  "content": "두 번째 리뷰"
}
```
> 오늘 이미 857번 가게에 리뷰를 작성한 상태

**흐름:**

```
[1] 필터 통과 (인증됨)
    │
    ↓
[2] ReviewController.createReview()
    │
    ├─ 📁 ReviewController.java (Line 65-71)
    │
    ↓
[3] ReviewService.createReview()
    │
    ├─ 📁 ReviewService.java (Line 66-72)
    │   // 하루에 한 번만 작성 가능 체크
    │   if (reviewRepository.existsByUser_IdAndDollShop_IdAndCreatedAtBetweenAndIsDeletedFalse(
    │           user.getId(), dollShop.getId(), startOfDay, endOfDay)) {
    │       throw new BusinessRuleException(
    │           "해당 가게에 대한 리뷰는 하루에 한 번만 작성할 수 있습니다.");  // ❌
    │   }
    │
    ↓
[4] GlobalExceptionHandler.handleBusinessException()
    │
    ├─ // BusinessRuleException extends BusinessException
    │   // e.getStatus() = HttpStatus.BAD_REQUEST (400)
    │   // e.getErrorCode() = "BUSINESS_RULE_VIOLATION"
    │
    ↓
[응답] HTTP 400 Bad Request
```

**응답:**
```json
{
  "success": false,
  "message": "해당 가게에 대한 리뷰는 하루에 한 번만 작성할 수 있습니다.",
  "errorCode": "BUSINESS_RULE_VIOLATION",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

### 4.4 ❌ 이미 삭제된 게시글 다시 삭제 시도

**요청:**
```http
DELETE /api/community/123
Cookie: access_token=eyJhbGc...(작성자 본인)
```
> 게시글 123은 이미 삭제된 상태 (isDeleted = true)

**흐름:**

```
[1] 필터 통과 → 컨트롤러 도달
    │
    ↓
[2] CommunityService.deleteCommunity()
    │
    ├─ 📁 CommunityService.java (Line 77-79)
    │   CommunityEntity community = communityRepository
    │       .findByIdAndIsDeletedFalse(communityId)  // isDeleted=true라서 없음!
    │       .orElseThrow(() -> EntityNotFoundException.of("게시글", communityId));
    │
    ↓
[3] GlobalExceptionHandler → HTTP 404
```

**또는** (isDeleted 체크 안 하는 쿼리로 조회한 경우):

```
[2] CommunityEntity.softDelete()
    │
    ├─ 📁 CommunityEntity.java (Line 76-80)
    │   public void softDelete() {
    │       if (this.isDeleted) {
    │           throw DuplicateResourceException.alreadyDeleted("게시글");  // ❌
    │       }
    │       this.isDeleted = true;
    │   }
    │
    ↓
[3] GlobalExceptionHandler.handleBusinessException()
    │
    ├─ // DuplicateResourceException extends BusinessException
    │   // e.getStatus() = HttpStatus.CONFLICT (409)
    │   // e.getErrorCode() = "DUPLICATE_RESOURCE"
    │
    ↓
[응답] HTTP 409 Conflict
```

**응답:**
```json
{
  "success": false,
  "message": "이미 삭제된 게시글입니다.",
  "errorCode": "DUPLICATE_RESOURCE",
  "timestamp": "2026-01-16T14:30:00"
}
```

---

## 5. 유효성 검증 에러 흐름

### 5.1 ❌ 게시글 작성 시 제목 누락

**요청:**
```http
POST /api/community
Cookie: access_token=eyJhbGc...
Content-Type: application/json

{
  "title": "",
  "content": "내용만 있음"
}
```

**흐름:**

```
[1] 필터 통과 → 컨트롤러 도달
    │
    ↓
[2] CommunityController.createCommunity()
    │
    ├─ 📁 CommunityController.java (Line 51-53)
    │   @PostMapping
    │   public ResponseEntity<ApiResponse<Long>> createCommunity(
    │       @Valid @RequestBody CommunityCreateDTO createDTO,  // ← @Valid 검증!
    │       ...
    │
    ├─ 📁 CommunityCreateDTO.java (Line 16-17)
    │   @NotBlank(message = "제목은 필수입니다")
    │   @Size(max = 200, message = "제목은 200자 이하여야 합니다")
    │   private String title;
    │   
    │   // title이 빈 문자열 → @NotBlank 위반!
    │   // MethodArgumentNotValidException 발생!
    │
    ↓
[3] GlobalExceptionHandler.handleValidationException()
    │
    ├─ 📁 GlobalExceptionHandler.java (Line 44-67)
    │   @ExceptionHandler(MethodArgumentNotValidException.class)
    │   public ResponseEntity<ErrorResponse> handleValidationException(
    │           MethodArgumentNotValidException e) {
    │       
    │       List<ErrorResponse.FieldError> fieldErrors = e.getBindingResult()
    │           .getFieldErrors()
    │           .stream()
    │           .map(error -> ErrorResponse.FieldError.builder()
    │               .field(error.getField())           // "title"
    │               .message(error.getDefaultMessage()) // "제목은 필수입니다"
    │               .rejectedValue(error.getRejectedValue()) // ""
    │               .build())
    │           .collect(Collectors.toList());
    │       
    │       ErrorResponse response = ErrorResponse.of(
    │           "입력값이 올바르지 않습니다.",
    │           "VALIDATION_ERROR",
    │           fieldErrors
    │       );
    │       return ResponseEntity.badRequest().body(response);
    │   }
    │
    ↓
[응답] HTTP 400 Bad Request
```

**응답:**
```json
{
  "success": false,
  "message": "입력값이 올바르지 않습니다.",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2026-01-16T14:30:00",
  "errors": [
    {
      "field": "title",
      "message": "제목은 필수입니다",
      "rejectedValue": ""
    }
  ]
}
```

---

### 5.2 ❌ 회원가입 시 여러 필드 검증 실패

**요청:**
```http
POST /api/join
Content-Type: application/json

{
  "username": "ab",
  "password": "12",
  "email": "invalid-email",
  "nickname": ""
}
```

**흐름:**

```
[1] JoinController.join()
    │
    ├─ 📁 JoinController.java (Line 23)
    │   @PostMapping
    │   public ResponseEntity<ApiResponse<Void>> join(
    │       @Valid @RequestBody JoinDTO joinDTO)  // ← @Valid 검증!
    │
    ├─ 📁 JoinDTO.java
    │   @Size(min = 4, ...) username = "ab"  → 위반! (4자 미만)
    │   @Size(min = 4, ...) password = "12"  → 위반! (4자 미만)
    │   @Email email = "invalid-email"       → 위반! (이메일 형식 X)
    │   @NotBlank nickname = ""              → 위반! (빈 문자열)
    │
    ↓
[2] GlobalExceptionHandler.handleValidationException()
    │
    ↓
[응답] HTTP 400 Bad Request
```

**응답:**
```json
{
  "success": false,
  "message": "입력값이 올바르지 않습니다.",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2026-01-16T14:30:00",
  "errors": [
    {
      "field": "username",
      "message": "아이디는 4~20자여야 합니다",
      "rejectedValue": "ab"
    },
    {
      "field": "password",
      "message": "비밀번호는 4자 이상이어야 합니다",
      "rejectedValue": "12"
    },
    {
      "field": "email",
      "message": "이메일 형식이 올바르지 않습니다",
      "rejectedValue": "invalid-email"
    },
    {
      "field": "nickname",
      "message": "닉네임은 필수입니다",
      "rejectedValue": ""
    }
  ]
}
```

---

## 6. 응답 형식 정리

### 6.1 성공 응답 (ApiResponse)

```json
{
  "success": true,
  "message": "작업이 완료되었습니다.",
  "data": { ... }  // 실제 데이터 (없을 수도 있음)
}
```

### 6.2 에러 응답 (ErrorResponse)

```json
{
  "success": false,
  "message": "에러 메시지",
  "errorCode": "ERROR_CODE",
  "timestamp": "2026-01-16T14:30:00",
  "errors": [...]  // 유효성 검증 에러 시에만 존재
}
```

### 6.3 에러 코드 정리

| errorCode | HTTP 상태 | 발생 위치 | 설명 |
|-----------|----------|----------|------|
| `AUTHENTICATION_FAILED` | 401 | JwtLoginFilter | 로그인 실패 (ID/PW 불일치) |
| `NOT_AUTHENTICATED` | 401 | SecurityConfig | 인증 필요 (토큰 없음) |
| `TOKEN_EXPIRED` | 401 | SecurityConfig / RefreshController | Access/Refresh Token 만료 |
| `TOKEN_REQUIRED` | 401 | RefreshController | Refresh Token 헤더 없음 |
| `TOKEN_DISCARDED` | 401 | RefreshController | 폐기된 토큰 (로그아웃됨) |
| `NOT_FOUND` | 404 | GlobalExceptionHandler | 리소스 없음 |
| `ACCESS_DENIED` | 403 | GlobalExceptionHandler | 권한 없음 (본인 아님) |
| `BUSINESS_RULE_VIOLATION` | 400 | GlobalExceptionHandler | 비즈니스 규칙 위반 |
| `DUPLICATE_RESOURCE` | 409 | GlobalExceptionHandler | 중복/이미 처리됨 |
| `VALIDATION_ERROR` | 400 | GlobalExceptionHandler | 유효성 검증 실패 (@Valid) |
| `INVALID_JSON` | 400 | GlobalExceptionHandler | JSON 파싱 실패 |
| `MISSING_PARAMETER` | 400 | GlobalExceptionHandler | 필수 파라미터 누락 |
| `TYPE_MISMATCH` | 400 | GlobalExceptionHandler | 파라미터 타입 불일치 |
| `INTERNAL_SERVER_ERROR` | 500 | GlobalExceptionHandler | 예상치 못한 서버 오류 |

---

## 📁 관련 파일 위치 요약

| 파일 | 역할 |
|------|------|
| `jwt/config/SecurityConfig.java` | 필터 등록, URL 권한 설정, 인증 실패 핸들러 |
| `jwt/filter/JwtAccessTokenCheckAndSaveUserInfoFilter.java` | 토큰 검증 및 인증 정보 저장 |
| `jwt/filter/JwtLoginFilter.java` | 로그인 처리, 토큰 발급 |
| `jwt/service/CustomUserDetailsService.java` | 사용자 조회 (로그인 시) |
| `common/exception/GlobalExceptionHandler.java` | 모든 예외 통합 처리 |
| `common/exception/EntityNotFoundException.java` | 404 에러 |
| `common/exception/AccessDeniedException.java` | 403 에러 |
| `common/exception/BusinessRuleException.java` | 400 에러 (비즈니스 규칙) |
| `common/exception/DuplicateResourceException.java` | 409 에러 |
| `common/dto/ApiResponse.java` | 성공 응답 DTO |
| `common/dto/ErrorResponse.java` | 에러 응답 DTO |

