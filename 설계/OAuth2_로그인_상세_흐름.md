# 현재 프로젝트 OAuth2 로그인 상세 흐름 (Code Level Analysis)

## 1. 로그인 시작 (요청 단계)
**파일:** `Oauth2LoginController.java`
**URL:** 
- Web: `/custom-oauth2/login/web/{provider}`
- App: `/custom-oauth2/login/app/{provider}`

1.  **클라이언트 요청:**
    *   사용자가 카카오/구글 로그인 버튼을 클릭하면 위 URL로 요청을 보냅니다.
2.  **ClientRegistration 조회:**
    *   `ClientRegistrationRepository`를 통해 `application.yml`에 설정된 제공자 정보(clientId, redirectUri 등)를 가져옵니다.
3.  **OAuth2AuthorizationRequest 생성:**
    *   `state` 값(UUID)을 생성하여 보안을 강화합니다.
    *   **Web:** `target` 속성을 "web"으로 설정합니다.
    *   **App:** `target` 속성을 "app"으로 설정합니다. 또한, 에뮬레이터 환경을 고려하여 `redirect_uri`의 `localhost`를 `10.0.2.2`로 변환합니다.
4.  **요청 저장:**
    *   `InMemoryAuthorizationRequestRepository.saveAuthorizationRequest`를 호출하여 요청 정보를 저장합니다.
5.  **리다이렉트:**
    *   제공자의 인증 페이지(Authorization URI)로 리다이렉트합니다 (`response.sendRedirect`).

---

## 2. 인증 요청 저장 (Repository)
**파일:** `InMemoryAuthorizationRequestRepository.java`

1.  **저장소:**
    *   Redis 대신 `ConcurrentHashMap`을 사용하여 메모리에 `state`를 키로 요청 객체를 저장합니다.
2.  **자동 만료:**
    *   저장 시 별도 스레드를 실행하여 5분 후 해당 `state`를 자동으로 삭제합니다.
3.  **조회 방식 변경:**
    *   기본 `removeAuthorizationRequest` 메서드는 조회 시 데이터를 삭제하지만, 여기서는 **삭제하지 않고 조회만 하도록(`get`) 커스터마이징** 되어 있습니다.
    *   이는 `OAuth2LoginAuthenticationFilter`가 조회한 후, 나중에 `SuccessHandler`에서도 `target` 정보를 확인하기 위해 데이터가 필요하기 때문입니다.

---

## 3. 유저 정보 로드 및 저장 (Service)
**파일:** `CustomOAuth2UserService.java`
**동작:** 소셜 로그인 성공 후 실행

1.  **유저 정보 가져오기:**
    *   `DefaultOAuth2UserService.loadUser`를 호출하여 제공자로부터 유저 정보를 받아옵니다.
2.  **엔티티 변환:**
    *   `OAuthProvider` Enum을 사용하여 제공자별(Kakao, Google) 속성(`attributes`)을 `UserDTO`로 변환합니다.
3.  **DB 저장/업데이트:**
    *   `username`(provider_providerId)으로 DB를 조회합니다.
    *   **신규 유저:** `UserEntity`를 생성하여 저장합니다.
    *   **기존 유저:** 이메일, 닉네임 등 변경된 정보를 업데이트합니다.
4.  **결과 반환:**
    *   `CustomUserAccount` (UserDetails + OAuth2User 구현체)를 반환합니다.

---

## 4. 로그인 성공 처리 (Handler)
**파일:** `OAuth2LoginSuccessHandler.java`
**동작:** 인증 및 유저 로드 완료 후 실행

1.  **토큰 생성:**
    *   `JwtUtil`을 사용하여 Access Token과 Refresh Token을 생성합니다.
2.  **Refresh Token 저장:**
    *   `RefreshService.saveRefresh`를 통해 DB에 저장합니다.
3.  **타겟 확인:**
    *   `InMemoryAuthorizationRequestRepository`에서 `state`로 저장된 요청을 조회하여 `target` 값("web" 또는 "app")을 확인합니다.
4.  **응답 분기 처리:**
    *   **Case A (App):**
        *   `http://10.0.2.2:8080/login/success`로 리다이렉트합니다.
        *   Query Parameter로 `access_token`과 `refresh_token`을 전달합니다.
        *   앱(WebView)에서 이 URL을 가로채서 토큰을 추출하고 창을 닫습니다.
    *   **Case B (Web):**
        *   `addCookie` 메서드로 Access/Refresh Token을 **HttpOnly 쿠키**에 담습니다 (`maxAge: -1`).
        *   `/map` 페이지로 리다이렉트합니다.
5.  **요청 정보 삭제:**
    *   `authorizationRequestRepository.deleteAuthorizationRequest(state)`를 호출하여 메모리에서 요청 정보를 명시적으로 삭제합니다.

---

## 5. 실패 처리
**설정:** `SecurityConfig`

1.  **FailureHandler:**
    *   로그인 실패 시 `HttpServletResponse.SC_UNAUTHORIZED` (401) 에러를 반환하고 로그를 출력합니다.

