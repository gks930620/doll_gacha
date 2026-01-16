package com.doll.gacha.jwt;

import com.doll.gacha.jwt.entity.UserEntity;
import com.doll.gacha.jwt.repository.UserRepository;
import com.doll.gacha.jwt.service.RefreshService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@DisplayName("Refresh Controller 통합 테스트")
class RefreshIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private RefreshService refreshService;

    private String validRefreshToken;

    @BeforeEach
    void setUp() {
        // 테스트 유저 생성
        UserEntity user = UserEntity.builder()
                .username("testuser")
                .password(passwordEncoder.encode("password123"))
                .email("test@example.com")
                .nickname("테스터")
                .build();
        userRepository.save(user);

        // 유효한 refresh 토큰 생성 및 저장
        validRefreshToken = jwtUtil.createRefreshToken("testuser");
        refreshService.saveRefresh(validRefreshToken);
    }

    @Test
    @DisplayName("토큰 재발급 성공")
    void reissue_success() throws Exception {
        mockMvc.perform(post("/api/refresh/reissue")
                        .header("Authorization", "Bearer " + validRefreshToken))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.access_token").exists())
                .andExpect(jsonPath("$.refresh_token").exists());
    }

    @Test
    @DisplayName("토큰 재발급 실패 - 유효하지 않은 토큰")
    void reissue_invalidToken() throws Exception {
        mockMvc.perform(post("/api/refresh/reissue")
                        .header("Authorization", "Bearer invalid_token_string"))
                .andDo(print())
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("토큰 재발급 실패 - 폐기된 토큰")
    void reissue_discardedToken() throws Exception {
        // 토큰 폐기
        refreshService.deleteRefresh(validRefreshToken);

        mockMvc.perform(post("/api/refresh/reissue")
                        .header("Authorization", "Bearer " + validRefreshToken))
                .andDo(print())
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Refresh Token discarded"));
    }

    @Test
    @DisplayName("토큰 재발급 실패 - Authorization 헤더 누락")
    void reissue_noHeader() throws Exception {
        mockMvc.perform(post("/api/refresh/reissue"))
                .andDo(print())
                .andExpect(status().isBadRequest());
    }
}

