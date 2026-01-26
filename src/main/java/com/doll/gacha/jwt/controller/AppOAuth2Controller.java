package com.doll.gacha.jwt.controller;

import com.doll.gacha.jwt.JwtUtil;
import com.doll.gacha.jwt.entity.UserEntity;
import com.doll.gacha.jwt.repository.UserRepository;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 앱 전용 OAuth2 로그인 컨트롤러
 * 앱에서 네이티브 SDK로 OAuth 로그인 후 사용자 정보를 서버로 전송하여 JWT를 발급받습니다.
 */
@Slf4j
@RestController
@RequestMapping("/api/oauth2")
@RequiredArgsConstructor
public class AppOAuth2Controller {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    /**
     * 앱에서 네이티브 OAuth 로그인 후 호출하는 공통 엔드포인트
     * @param provider google, kakao 등
     * @param request id, email, nickname(또는 displayName) 등 사용자 정보
     */
    @PostMapping("/{provider}/app")
    public ResponseEntity<Map<String, Object>> oauthAppLogin(
            @PathVariable("provider") String provider,
            @RequestBody Map<String, String> request) {
        try {
            String id = request.get("id");
            String email = request.get("email");
            // Google은 displayName, Kakao는 nickname 사용
            String nickname = request.get("nickname") != null
                    ? request.get("nickname")
                    : request.get("displayName");

            if (id == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", provider + " ID는 필수입니다."
                ));
            }

            // username은 provider + id 형식 (웹 OAuth2와 동일)
            String username = provider + id;

            // 기본 닉네임 설정
            String defaultNickname = "google".equalsIgnoreCase(provider) ? "구글사용자" : "카카오사용자";

            // 기존 사용자 조회 또는 신규 생성
            UserEntity user = userRepository.findByUsername(username).orElse(null);

            if (user == null) {
                // 신규 사용자 생성
                user = UserEntity.builder()
                    .username(username)
                    .email(email != null ? email : "")
                    .nickname(nickname != null ? nickname : defaultNickname)
                    .password("{noop}oauth2user")
                    .provider(provider.toLowerCase())
                    .roles(new ArrayList<>())
                    .isActive(true)
                    .build();
                user.getRoles().add("USER");
                userRepository.save(user);
                log.info("새 {} 사용자 생성: {}", provider, username);
            } else {
                // 기존 사용자 정보 업데이트
                if (email != null) {
                    user.setEmail(email);
                }
                if (nickname != null) {
                    user.setNickname(nickname);
                }
                userRepository.save(user);
                log.info("기존 {} 사용자 로그인: {}", provider, username);
            }

            // JWT 토큰 생성
            String accessToken = jwtUtil.createAccessToken(username);
            String refreshToken = jwtUtil.createRefreshToken(username);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", Map.of(
                "access_token", accessToken,
                "refresh_token", refreshToken
            ));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("{} 앱 로그인 오류", provider, e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "로그인 처리 중 오류가 발생했습니다: " + e.getMessage()
            ));
        }
    }
}

