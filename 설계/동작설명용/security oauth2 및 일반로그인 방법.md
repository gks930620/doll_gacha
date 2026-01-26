웹 앱  Ouath2 JWT 로그인방식
-  처음 Oauth2 로그인버튼 시작하는 URL 만큼은  app, web을 구별하는게 좋다.    Oauth2LoginController
    이 때 둘다 /oauth2/authorization/kakao 등의 기본 url보다는 따로 url 만들어야 컨트롤러 탄다.
    (/custom-oauth2/login/web/kakao  )  (/custom-oauth2/login/app/kakao)
    웹은 이후 redirect-uri를 받아  카카오 로그인을 진행하게 됨.   (이곳 redirect는 /api 요청이 아니기 때문에 sendRedirect로 가능)
-  Oauth2 로그인 성공 후 successHandler(Oauth2LoginSuccessHandler)에서는  web app 따로 if-else  구별한다.
     성공 후 웹은 쿠키,  앱은 json 형태로 토큰을 준다.
이후에는 OAUTH2로그인인거 상관없이 가지고 있는 토큰을 서버에 보내서 인증받는 방식은
일반 JWT 로그인이랑 똑같음.

일반 JWT 로그인
-  일반 로그인 시도은 /api/login POST방식 으로 올 때 username,password가 body에 딸려서 오고
    이걸 자체로직으로  로그인여부 판단 (attemptAuthentication  :  웹 앱 가리지 않음)
-  로그인 성공 후 successfulAuthentication  :
    여기서는 웹 앱 구별  (oauth2의 successHandler랑 비슷.    웹은 쿠키,  앱은 json 형식으로 토큰 전달)

일반로그인 , oauth2로그인 이후  공통
-  로그인을 했다면 어떤 클라이언트든 토큰을 가지고 있고,  /api 로그인필요한 곳에 접근할 때
    JwtAccessTokenCheckAndSaveUserInfoFilter에서 매 요청마다 검증
    이 때 토큰 위치가 앱 웹 다르지만   양쪽에서 찾는 코드를 다 작성해서 찾기만 하면 됨
- 로그아웃은 기본적으로 logoutController보다는
  http.logout(logout -> logout  .logoutUrl("/api/logout").logoutSuccessHandler(customLogoutSuccessHandler));
  logoutSuccessHandler에서 jwt방식에 맞게 처리하면 됨.
   웹 앱 구별해서 web일 때 쿠키 처리해서 토큰없애기
로그인 전 실패 처리 authenticationEntryPoint
-  앱 웹 구분 없이 그냥 메세지보내고 이 메세지에 따라 동작하는건 client측에 맡긴다.

가장 중요
-클라이언트 웹 앱을 구별하는 이유는 성공 시 토큰처리 때문임. 웹은 쿠키로.. 앱은 json으로
- 토큰은 -1로 설정해서 브라우저 꺼졌을 때 사라짐.
   토큰 유효값은 서버가 설정한 값 (expiration time)

OAuth2 Request Repository 주의사항 (State 유지)
- InMemoryAuthorizationRequestRepository에서 removeAuthorizationRequest를 구현할 때,
  Map에서 바로 remove를 해버리면 SuccessHandler에서 target(app/web) 정보를 확인할 수 없게 됨.
- 따라서 remove 대신 get을 사용하여 정보를 유지해야 함. (삭제는 별도의 만료 시간(TTL) 로직으로 처리)
- 웹은 정보가 없으면 기본값(web)으로 동작해서 우연히 되지만, 앱은 target=app 정보가 필수이므로 반드시 유지되어야 함.


다중 서버 환경(Scale-out) 시 고려사항 (Redis 필요성)
- 현재 구현된 InMemoryAuthorizationRequestRepository는 서버 메모리(Map)에 데이터를 저장함.
- 단일 서버일 때는 문제없지만, 서버가 여러 대(L4/L7 로드밸런싱)일 경우 문제가 발생함.
  (예: 서버1에서 로그인 요청 -> 카카오 인증 -> 서버2로 리다이렉트 복귀 -> 서버2 메모리엔 정보가 없어서 실패)
- 이를 해결하기 위해 Redis와 같은 외부 공유 저장소를 사용해야 함.
  - 서버1이 Redis에 요청 정보 저장 (Key: state)
  - 서버2가 Redis에서 state로 조회 가능
- 따라서 실무/배포 환경에서 서버를 여러 대 띄운다면 Redis 기반의 Repository 구현이 필수적임.


지금 이 상태가 앱 웹 다 로그인되는데  앱의 경우 앱웹브라우저를 통해 oauth2로그인이 되도록 함.

## 앱 OAuth2 로그인 URL 관련 정리

### 카카오 (WebView 방식)
- 앱에서 WebView를 띄워서 OAuth2 로그인을 진행함
- WebView 내에서는 사실상 웹 브라우저와 동일하게 동작
- 따라서 `/custom-oauth2/login/app/kakao`로 요청해도 실제로는 **웹과 동일한 OAuth2 플로우**를 탐
- redirect-uri도 웹과 동일하게 서버 URL 사용 가능
- 카카오는 WebView에서 OAuth2 로그인을 허용하므로 문제없음
- 
### Google (Native 방식 필수)
- **Google은 WebView에서 OAuth2 로그인을 금지함** (403 disallowed_useragent 에러)
- 따라서 앱에서는 `google_sign_in` 패키지를 사용한 **네이티브 방식** 필수
- 네이티브 로그인 후 사용자 정보를 서버 `/api/oauth2/google/app`로 전송
- 서버에서 사용자 생성/조회 후 JWT 토큰 발급

### 정리
| Provider | 앱 로그인 방식 | 설명 |
|----------|--------------|------|
| 카카오 | Native SDK | `kakao_flutter_sdk` 패키지 사용 후 서버에 토큰 전송 |
| Google | Native SDK | WebView 금지, `google_sign_in` 패키지 사용 후 서버에 토큰 전송 |

### 결론
- **카카오, Google 모두 네이티브 SDK 방식으로 통일**
- 앱에서 네이티브 로그인 후 사용자 정보를 서버 `/api/oauth2/{provider}/app`로 전송
- 서버의 `AppOAuth2Controller`에서 JWT 발급





