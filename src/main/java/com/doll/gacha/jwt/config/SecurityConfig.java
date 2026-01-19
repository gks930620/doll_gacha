package com.doll.gacha.jwt.config;

import com.doll.gacha.jwt.JwtUtil;
import com.doll.gacha.jwt.filter.JwtAccessTokenCheckAndSaveUserInfoFilter;
import com.doll.gacha.jwt.filter.JwtLoginFilter;
import com.doll.gacha.jwt.service.CustomOAuth2UserService;
import com.doll.gacha.jwt.service.CustomUserDetailsService;
import com.doll.gacha.jwt.service.RefreshService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.ResponseCookie;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.client.web.AuthorizationRequestRepository;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler;
import org.springframework.stereotype.Component;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtUtil jwtUtil;
    private final CustomUserDetailsService customUserDetailsService;  //내가 빈으로 등록한것들
    private final CustomOAuth2UserService customOAuth2UserService;

    private final AuthenticationConfiguration authenticationConfiguration;  //authenticationManger를 갖고있는 빈.

    private final RefreshService refreshService;
    private final AuthorizationRequestRepository authorizationRequestRepository;


    private final OAuth2LoginSuccessHandler oAuth2LoginSuccessHandler;
    private final CustomLogoutSuccessHandler customLogoutSuccessHandler;


    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }


    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http  //내부H2DB  확인용.  진짜 1도 안중요함.
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/h2-console/**").permitAll() // H2 콘솔 접근 허용
            )
            .csrf(csrf -> csrf.ignoringRequestMatchers("/h2-console/**")) // H2 콘솔 CSRF 비활성화
            .headers(
                headers -> headers.frameOptions(frame -> frame.disable())); // H2 콘솔을 iframe에서 허용

        http    //기본 session방식관련 다 X
            .csrf(csrf -> csrf.disable())
            .sessionManagement(
                session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .formLogin(form -> form.disable())
            .httpBasic(basic -> basic.disable());

        http.logout(logout -> logout
            .logoutUrl("/api/logout")
            .logoutSuccessHandler(customLogoutSuccessHandler)
        );

        http   //경로와 인증/인가 설정.
            .authorizeHttpRequests(auth -> auth
                // 1. 정적 리소스, 페이지 등 기본적으로 모두 허용
                .requestMatchers(
                    // 정적 리소스
                    "/css/**", "/js/**", "/images/**", "/favicon.ico", "/uploads/**",
                    // h2-console
                    "/h2-console/**",
                    // 페이지 URL (CSR이므로 페이지 자체는 모두 허용 - API에서 인증 체크)
                    "/", "/map", "/login", "/signup", "/mypage", "/community/**", "/doll/**", "/doll-shop/**",  "/review/**",
                    // 인증 관련 API
                    "/api/login", "/api/join", "/api/refresh/reissue",
                    // OAuth2
                    "/custom-oauth2/login/**",
                    // 공개 API
                    "/api/doll-shops/**",
                    "/api/reviews/doll-shop/**",  // 리뷰 조회는 공개
                    "/api/community",             // 커뮤니티 목록/검색 조회 공개
                    "/api/community/{id:[0-9]+}", // 커뮤니티 상세 조회 공개
                    "/api/files/download/**"      // 파일 다운로드 공개
                ).permitAll()

                // 2. 인증이 필요한 API
                .requestMatchers(
                    "/api/logout",  // 로그아웃은 로그인한 사용자만 가능
                    "/api/my/info",
                    "/api/files/upload"  // 파일 업로드는 인증 필요
                ).authenticated()

                // 3. 커뮤니티 작성/수정/삭제는 인증 필요
                .requestMatchers(
                    org.springframework.http.HttpMethod.POST, "/api/community", "/api/community/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.PUT, "/api/community/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.DELETE, "/api/community/**"
                ).authenticated()

                // 4. 리뷰 작성/수정/삭제는 인증 필요 (POST, PUT, PATCH, DELETE)
                .requestMatchers(
                    org.springframework.http.HttpMethod.POST, "/api/reviews/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.PUT, "/api/reviews/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.PATCH, "/api/reviews/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.DELETE, "/api/reviews/**"
                ).authenticated()

                // 5. 댓글 작성/수정/삭제는 인증 필요 (POST, PUT, DELETE)
                .requestMatchers(
                    org.springframework.http.HttpMethod.POST, "/api/comments/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.PUT, "/api/comments/**"
                ).authenticated()
                .requestMatchers(
                    org.springframework.http.HttpMethod.DELETE, "/api/comments/**"
                ).authenticated()

                // 6. 그 외 나머지 요청은 일단 모두 허용 (개발 편의성)
                // 운영 환경에서는 .anyRequest().denyAll() 또는 .anyRequest().authenticated() 등으로 변경 고려
                .anyRequest().permitAll()
            );


        http.oauth2Login(oauth2 -> oauth2
            .authorizationEndpoint(authEndpoint -> authEndpoint
                .authorizationRequestRepository(authorizationRequestRepository)) // ✅ 직접 구현한 저장소 적용
            .userInfoEndpoint(userInfo -> userInfo.userService(customOAuth2UserService))
            .successHandler(oAuth2LoginSuccessHandler) // ✅ 로그인 성공 시 JWT 발급
             // 이 부분이  jwt방식이냐   session방식이냐를 가른다!
            .failureHandler((request, response, exception) -> {
                exception.printStackTrace();
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            })  // ✅ 실패 시 로그 찍기
        );


        http          //필터
            .userDetailsService(customUserDetailsService)
            .addFilterAt(
                new JwtLoginFilter(authenticationConfiguration.getAuthenticationManager(), jwtUtil,
                    refreshService, "/api/login"),  //이 부분때문에 이 url일 때만 동작
                UsernamePasswordAuthenticationFilter.class)  //기존 세션방식의 로그인 검증필터 대체.
            .addFilterBefore(
                new JwtAccessTokenCheckAndSaveUserInfoFilter(jwtUtil, customUserDetailsService),
                UsernamePasswordAuthenticationFilter.class);

       
        http
            .exceptionHandling(ex -> ex
                  // 여기는 인증된 api요청에 토큰 없이 접근하려고 할 때
                 //JwtLoginFilter는 로그인 시도하려고 할 때.. 즉 id pw입력한거 비교할 때
                .authenticationEntryPoint((request, response, authException) -> {
                    // ErrorResponse 형식으로 통일된 응답
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json;charset=UTF-8");

                    String errorCause = request.getAttribute("ERROR_CAUSE") != null
                        ? (String) request.getAttribute("ERROR_CAUSE")
                        : "NOT_AUTHENTICATED";

                    String errorMessage;
                    String errorCode;

                    if ("토큰만료".equals(errorCause)) {
                        errorMessage = "Access Token이 만료되었습니다. 토큰을 재발급해주세요.";
                        errorCode = "TOKEN_EXPIRED";
                    } else if ("잘못된토큰".equals(errorCause)) {
                        errorMessage = "유효하지 않은 토큰입니다.";
                        errorCode = "INVALID_TOKEN";
                    } else {
                        errorMessage = "인증이 필요합니다.";
                        errorCode = "NOT_AUTHENTICATED";
                    }

                    // ErrorResponse 형식으로 응답
                    String jsonResponse = String.format(
                        "{\"success\":false,\"message\":\"%s\",\"errorCode\":\"%s\",\"timestamp\":\"%s\"}",
                        errorMessage, errorCode, java.time.LocalDateTime.now()
                    );
                    response.getWriter().write(jsonResponse);
                })
            );
        return http.build();
    }


}

