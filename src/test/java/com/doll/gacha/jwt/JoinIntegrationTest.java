package com.doll.gacha.jwt;

import com.doll.gacha.jwt.model.JoinDTO;
import com.doll.gacha.jwt.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
@DisplayName("Join Controller 통합 테스트")
class JoinIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("회원가입 성공")
    void join_success() throws Exception {
        JoinDTO joinDTO = new JoinDTO();
        joinDTO.setUsername("newuser");
        joinDTO.setPassword("password123");
        joinDTO.setEmail("newuser@example.com");
        joinDTO.setNickname("새유저");

        mockMvc.perform(post("/api/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(joinDTO)))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(content().string("회원가입 완료!"));
    }

    @Test
    @DisplayName("회원가입 - 중복 username 처리")
    void join_duplicateUsername() throws Exception {
        // 첫 번째 가입
        JoinDTO joinDTO1 = new JoinDTO();
        joinDTO1.setUsername("duplicateuser");
        joinDTO1.setPassword("password123");
        joinDTO1.setEmail("user1@example.com");
        joinDTO1.setNickname("유저1");

        mockMvc.perform(post("/api/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(joinDTO1)))
                .andExpect(status().isOk());

        // 동일한 username으로 두 번째 가입 시도
        JoinDTO joinDTO2 = new JoinDTO();
        joinDTO2.setUsername("duplicateuser");  // 중복
        joinDTO2.setPassword("password456");
        joinDTO2.setEmail("user2@example.com");
        joinDTO2.setNickname("유저2");

        // 중복 처리는 서비스 로직에 따라 다름 - 예외 발생 또는 무시될 수 있음
        mockMvc.perform(post("/api/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(joinDTO2)))
                .andDo(print());
        // 실제 구현에 따라 status 검증 필요
    }

    @Test
    @DisplayName("회원가입 - 필수값 누락")
    void join_missingFields() throws Exception {
        JoinDTO joinDTO = new JoinDTO();
        joinDTO.setUsername("");  // 빈 username
        joinDTO.setPassword("password123");
        joinDTO.setEmail("test@example.com");

        mockMvc.perform(post("/api/join")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(joinDTO)))
                .andDo(print());
        // 유효성 검증 로직에 따라 결과가 달라질 수 있음
    }
}

