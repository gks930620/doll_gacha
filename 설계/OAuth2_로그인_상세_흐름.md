# 현재 프로젝트 OAuth2 로그인 상세 흐름 (Code Level Analysis)

## 1. 로그인 시작 (요청 단계)
**파일:** `Oauth2LoginController.java`
**URL:** `/custom-oauth2/login/{web|app}/{provider}`

1.  **요청 수신:** 사용자가 로그인 버튼을 누르면 컨트롤러가 요청을 받습니다.
2.  **정보 생성:**
    *   `state`: 랜덤한 UUID 생성 (예: `abc-123`) -> **이게 티켓 번호입니다.**
    *   `target`: URL 경로에 따라 "app" 또는 "web"으로 설정.
3.  **저장 (`saveAuthorizationRequest`):**
    *   `InMemoryAuthorizationRequestRepository`의 `authorizationRequests` 맵에 저장합니다.
    *   Key: `abc-123` (state)
    *   Value: `{ target: "app", ... }` (요청 정보)
4.  **리다이렉트:**
    *   사용자를 카카오/구글 로그인 페이지로 보냅니다.
    *   이때 URL 뒤에 `&state=abc-123`을 붙여서 보냅니다.

---

## 2. 인증 진행 (외부 서버)
*   사용자가 카카오/구글 화면에서 로그인을 승인합니다.
*   카카오/구글은 사전에 등록된 우리 서버 주소(`redirect-uri`)로 사용자를 다시 보내줍니다.
*   **중요:** 이때 아까 보냈던 `state=abc-123`을 그대로 다시 돌려줍니다.
*   URL 예시: `http://localhost:8080/login/oauth2/code/kakao?code=인가코드&state=abc-123`

---

## 3. 복귀 및 검증 (필터 단계)
**파일:** `InMemoryAuthorizationRequestRepository.java`
**메서드:** `removeAuthorizationRequest`

1.  **필터 동작:** Spring Security의 `OAuth2LoginAuthenticationFilter`가 복귀 요청을 가로챕니다.
2.  **검증 시도:** "이 요청이 아까 보낸 그 요청이 맞나?" 확인하기 위해 `removeAuthorizationRequest`를 호출합니다.
3.  **State 확인:**
    *   요청 파라미터에서 `state=abc-123`을 읽습니다.
    *   Repository(Map)에서 `abc-123` 키로 저장된 객체를 찾습니다.
4.  **정보 유지 (중요!):**
    *   원래는 여기서 정보를 꺼내고 **삭제(remove)** 하는 것이 기본 동작입니다.
    *   하지만 우리는 **삭제하지 않고 조회(get)** 만 하도록 수정했습니다.
    *   이유: 여기서 지워버리면 다음 단계(성공 핸들러)에서 "앱인지 웹인지" 알 수 없게 되기 때문입니다.

---

## 4. 토큰 발급 및 로그인 처리 (내부 로직)
*   Spring Security가 내부적으로 카카오/구글과 통신하여 `Access Token`을 받고, 사용자 프로필 정보를 가져옵니다.
*   회원가입이 안 되어 있다면 회원가입 처리, 되어 있다면 로그인 처리를 완료합니다.

---

## 5. 성공 처리 (응답 단계)
**파일:** `OAuth2LoginSuccessHandler.java`
**메서드:** `onAuthenticationSuccess`

1.  **최종 확인:** 로그인이 다 끝났으니 사용자를 어디로 보낼지 결정해야 합니다.
2.  **정보 재조회:**
    *   다시 `authorizationRequestRepository`를 조회합니다.
    *   아까 3번 단계에서 지우지 않고 남겨뒀기 때문에, `abc-123` 키로 정보를 찾을 수 있습니다.
3.  **분기 처리:**
    *   저장된 정보에서 `target` 값을 꺼냅니다.
    *   **Case A (App):** `target`이 "app"이면 -> `http://10.0.2.2:8080/login/success`로 리다이렉트 (앱이 가로챔).
    *   **Case B (Web):** `target`이 "web"이면 -> 쿠키를 굽고 `/map` 페이지로 리다이렉트.

---

## 6. Q&A: 왜 SuccessHandler에서 명시적으로 삭제하지 않나요?
*   **질문:** `SuccessHandler`에서 `target` 정보를 다 썼으면, 거기서 삭제해야 깔끔하지 않나요?
*   **답변:** 맞습니다. 원래는 사용 직후 삭제하는 것이 가장 완벽한 설계입니다.
*   **현실적인 이유:**
    1.  우리가 `removeAuthorizationRequest` 메서드를 `get`(조회만 하고 삭제 안 함)으로 변경해버렸기 때문에, `SuccessHandler`에서 이 메서드를 호출해도 삭제되지 않습니다.
    2.  삭제를 위한 별도의 메서드를 또 만들면 코드가 복잡해집니다.
*   **해결책:** 그래서 **"5분 후 자동 삭제(TTL)"** 기능을 넣어두었습니다.
    *   `state`는 고유값이라 재사용될 확률이 거의 없고,
    *   5분 뒤에는 알아서 메모리에서 사라지므로 보안 및 메모리 누수 문제가 해결됩니다.
    *   Oauth2LoginSuccessHandler에서  명시적으로 삭제
---

## 결론
`removeAuthorizationRequest`는 **3번 단계(검증)** 에서 실행됩니다.
이때 `state` 파라미터가 없으면 "어떤 요청에 대한 응답인지" 찾을 수 없으므로 에러가 발생합니다.
따라서 `state`는 전체 과정의 **연결 고리** 역할을 하는 필수적인 요소입니다.
