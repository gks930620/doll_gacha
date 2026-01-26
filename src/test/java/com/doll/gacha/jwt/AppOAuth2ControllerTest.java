package com.doll.gacha.jwt;

import com.doll.gacha.jwt.entity.UserEntity;
import com.doll.gacha.jwt.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * AppOAuth2Controller 테스트
 * 앱에서 네이티브 SDK로 OAuth 로그인 후 사용자 정보를 서버로 전송하여 JWT를 발급받는 API 테스트
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AppOAuth2ControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    // ==================== Google 로그인 테스트 ====================

    @Test
    @DisplayName("Google 앱 로그인 성공 - 신규 사용자 생성")
    void googleAppLogin_NewUser_Success() throws Exception {
        // given
        Map<String, String> request = Map.of(
            "id", "123456789",
            "email", "test@gmail.com",
            "displayName", "테스트유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/google/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.access_token").exists())
            .andExpect(jsonPath("$.data.refresh_token").exists())
            .andDo(print());

        // DB 확인
        Optional<UserEntity> savedUser = userRepository.findByUsername("google123456789");
        assertThat(savedUser).isPresent();
        assertThat(savedUser.get().getEmail()).isEqualTo("test@gmail.com");
        assertThat(savedUser.get().getNickname()).isEqualTo("테스트유저");
        assertThat(savedUser.get().getProvider()).isEqualTo("google");
    }

    @Test
    @DisplayName("Google 앱 로그인 성공 - 기존 사용자 로그인 및 정보 업데이트")
    void googleAppLogin_ExistingUser_Success() throws Exception {
        // given - 기존 사용자 생성
        UserEntity existingUser = UserEntity.builder()
            .username("google123456789")
            .email("old@gmail.com")
            .nickname("기존유저")
            .password("{noop}oauth2user")
            .provider("google")
            .build();
        userRepository.save(existingUser);

        Map<String, String> request = Map.of(
            "id", "123456789",
            "email", "new@gmail.com",
            "displayName", "업데이트된유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/google/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.access_token").exists())
            .andDo(print());

        // DB 확인 - 정보가 업데이트 되었는지
        Optional<UserEntity> updatedUser = userRepository.findByUsername("google123456789");
        assertThat(updatedUser).isPresent();
        assertThat(updatedUser.get().getEmail()).isEqualTo("new@gmail.com");
        assertThat(updatedUser.get().getNickname()).isEqualTo("업데이트된유저");
    }

    @Test
    @DisplayName("Google 앱 로그인 실패 - ID 누락")
    void googleAppLogin_MissingId_Fail() throws Exception {
        // given - id가 없는 요청
        Map<String, String> request = Map.of(
            "email", "test@gmail.com",
            "displayName", "테스트유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/google/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").exists())
            .andDo(print());
    }

    @Test
    @DisplayName("Google 앱 로그인 성공 - 닉네임 없으면 기본값 사용")
    void googleAppLogin_NoNickname_UseDefault() throws Exception {
        // given - displayName 없는 요청
        Map<String, String> request = Map.of(
            "id", "987654321",
            "email", "test@gmail.com"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/google/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andDo(print());

        // DB 확인 - 기본 닉네임 사용
        Optional<UserEntity> savedUser = userRepository.findByUsername("google987654321");
        assertThat(savedUser).isPresent();
        assertThat(savedUser.get().getNickname()).isEqualTo("구글사용자");
    }

    // ==================== Kakao 로그인 테스트 ====================

    @Test
    @DisplayName("Kakao 앱 로그인 성공 - 신규 사용자 생성")
    void kakaoAppLogin_NewUser_Success() throws Exception {
        // given - 테스트용 고유 ID 사용 (기존 data-users.sql 데이터와 충돌 방지)
        Map<String, String> request = Map.of(
            "id", "9999999901",
            "email", "test@kakao.com",
            "nickname", "카카오유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/kakao/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.access_token").exists())
            .andExpect(jsonPath("$.data.refresh_token").exists())
            .andDo(print());

        // DB 확인
        Optional<UserEntity> savedUser = userRepository.findByUsername("kakao9999999901");
        assertThat(savedUser).isPresent();
        assertThat(savedUser.get().getEmail()).isEqualTo("test@kakao.com");
        assertThat(savedUser.get().getNickname()).isEqualTo("카카오유저");
        assertThat(savedUser.get().getProvider()).isEqualTo("kakao");
    }

    @Test
    @DisplayName("Kakao 앱 로그인 성공 - 기존 사용자 로그인")
    void kakaoAppLogin_ExistingUser_Success() throws Exception {
        // given - 테스트용 고유 ID로 기존 사용자 생성
        UserEntity existingUser = UserEntity.builder()
            .username("kakao9999999902")
            .email("old@kakao.com")
            .nickname("기존카카오유저")
            .password("{noop}oauth2user")
            .provider("kakao")
            .build();
        userRepository.save(existingUser);

        Map<String, String> request = Map.of(
            "id", "9999999902",
            "email", "new@kakao.com",
            "nickname", "업데이트카카오유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/kakao/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andDo(print());

        // DB 확인
        Optional<UserEntity> updatedUser = userRepository.findByUsername("kakao9999999902");
        assertThat(updatedUser).isPresent();
        assertThat(updatedUser.get().getEmail()).isEqualTo("new@kakao.com");
        assertThat(updatedUser.get().getNickname()).isEqualTo("업데이트카카오유저");
    }

    @Test
    @DisplayName("Kakao 앱 로그인 실패 - ID 누락")
    void kakaoAppLogin_MissingId_Fail() throws Exception {
        // given
        Map<String, String> request = Map.of(
            "email", "test@kakao.com",
            "nickname", "카카오유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/kakao/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andDo(print());
    }

    @Test
    @DisplayName("Kakao 앱 로그인 성공 - 이메일 없어도 성공")
    void kakaoAppLogin_NoEmail_Success() throws Exception {
        // given - 카카오는 이메일 동의 안 할 수 있음
        Map<String, String> request = Map.of(
            "id", "1111111111",
            "nickname", "이메일없는유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/kakao/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andDo(print());

        // DB 확인
        Optional<UserEntity> savedUser = userRepository.findByUsername("kakao1111111111");
        assertThat(savedUser).isPresent();
        assertThat(savedUser.get().getEmail()).isEqualTo("");  // 빈 문자열
        assertThat(savedUser.get().getNickname()).isEqualTo("이메일없는유저");
    }

    @Test
    @DisplayName("Kakao 앱 로그인 성공 - 닉네임 없으면 기본값 사용")
    void kakaoAppLogin_NoNickname_UseDefault() throws Exception {
        // given
        Map<String, String> request = Map.of(
            "id", "2222222222"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/kakao/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andDo(print());

        // DB 확인
        Optional<UserEntity> savedUser = userRepository.findByUsername("kakao2222222222");
        assertThat(savedUser).isPresent();
        assertThat(savedUser.get().getNickname()).isEqualTo("카카오사용자");
    }

    // ==================== 공통 테스트 ====================

    @Test
    @DisplayName("지원하지 않는 provider도 처리 가능")
    void unknownProvider_Success() throws Exception {
        // given - 미지원 provider도 일단 처리됨 (확장성)
        Map<String, String> request = Map.of(
            "id", "12345",
            "email", "test@naver.com",
            "nickname", "네이버유저"
        );

        // when
        ResultActions result = mockMvc.perform(post("/api/oauth2/naver/app")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)));

        // then - 현재 구현상 성공함 (나중에 제한하려면 validation 추가)
        result.andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andDo(print());

        // DB 확인
        Optional<UserEntity> savedUser = userRepository.findByUsername("naver12345");
        assertThat(savedUser).isPresent();
        assertThat(savedUser.get().getProvider()).isEqualTo("naver");
    }
}

