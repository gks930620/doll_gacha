package com.doll.gacha.jwt.config;

import com.doll.gacha.jwt.JwtUtil;
import com.doll.gacha.jwt.config.InMemoryAuthorizationRequestRepository;
import com.doll.gacha.jwt.entity.RefreshEntity;
import com.doll.gacha.jwt.model.CustomUserAccount;
import com.doll.gacha.jwt.repository.RefreshRepository;
import com.doll.gacha.jwt.service.RefreshService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
@RequiredArgsConstructor
public class OAuth2LoginSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final JwtUtil jwtUtil;

    private final RefreshService refreshService;

    private final InMemoryAuthorizationRequestRepository authorizationRequestRepository; // 추가
    private final ObjectMapper objectMapper = new ObjectMapper(); // JSON 응답용

    // OAuth2 인증 필터(OAuth2LoginAuthenticationFilter)가 인증을 완료한 후 호출됨
    // (removeAuthorizationRequest는 이보다 앞선 필터 단계에서 이미 실행되었음)
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
        Authentication authentication) throws IOException, ServletException {

        CustomUserAccount customUserAccount = (CustomUserAccount) authentication.getPrincipal();
        String username = customUserAccount.getUsername();

        // 1. 토큰 생성
        String accessToken = jwtUtil.createAccessToken(username);
        String refreshToken = jwtUtil.createRefreshToken(username);
        // 2. Refresh 토큰 저장 (DB)
        refreshService.saveRefresh(refreshToken);

        // 3. 시작 시 저장했던 target(web/app) 정보 가져오기
        var authRequest = authorizationRequestRepository.loadAuthorizationRequest(request);
        String target = (authRequest != null) ? (String) authRequest.getAttribute("target") : "web";

        // 4. 응답 분기 처리
        if ("app".equals(target)) {
            // ✅ 앱: 리다이렉트 방식으로 변경
            // 커스텀 스킴(dollgacha://) 대신 표준 URL 형식을 사용하여 WebView가 확실하게 가로챌 수 있도록 함
            // 실제로는 이 주소로 이동하지 않고 앱이 중간에 가로채서 창을 닫음
            // (localhost여도 가로채기 때문에 상관없지만, 명확성을 위해 에뮬레이터 IP인 10.0.2.2 사용)
            String targetUrl = UriComponentsBuilder.fromUriString("http://10.0.2.2:8080/login/success")
                .queryParam("access_token", accessToken)
                .queryParam("refresh_token", refreshToken)
                .build().toUriString();

            getRedirectStrategy().sendRedirect(request, response, targetUrl);
        } else {
            // ✅ 웹: 쿠키 설정 + 리다이렉트
            // 브라우저 종료 시 로그아웃 되도록 세션 쿠키(-1)로 설정
            // (브라우저가 켜져있는 동안의 보안은 JWT 토큰 자체의 만료 시간으로 검증됨)
            addCookie(response, "access_token", accessToken, -1);
            addCookie(response, "refresh_token", refreshToken, -1);

            getRedirectStrategy().sendRedirect(request, response, "/map");
        }

        // 5. 사용 완료된 요청 정보 명시적 삭제 (메모리 절약)
        // (InMemoryAuthorizationRequestRepository에서 remove를 get으로 변경했으므로, 여기서 수동으로 지워줌)
        String state = request.getParameter("state");
        if (state != null) {
            authorizationRequestRepository.deleteAuthorizationRequest(state);
        }
    }

    private void addCookie(HttpServletResponse response, String name, String value, int maxAge) {
        ResponseCookie.ResponseCookieBuilder cookieBuilder = ResponseCookie.from(name, value)
            .httpOnly(true)
            .secure(false) // 운영 환경(HTTPS)에서는 true 권장
            .sameSite("Lax")
            .path("/");

        if (maxAge > 0) {
            cookieBuilder.maxAge(maxAge);
        }

        response.addHeader("Set-Cookie", cookieBuilder.build().toString());
    }
}