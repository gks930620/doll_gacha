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
                    "/css/**", "/js/**", "/images/**", "/favicon.ico",
                    // h2-console
                    "/h2-console/**",
                    // 페이지 URL (CSR이므로 페이지 자체는 모두 허용)
                    "/", "/map", "/login", "/signup", "/community/**", "/doll/**", "/mypage", "/review/**",
                    // 인증 관련 API
                    "/api/login", "/api/join", "/api/refresh/reissue",
                    // OAuth2
                    "/custom-oauth2/login/**",
                    // 공개 API
                    "/api/dollshop/**"
                ).permitAll()

                // 2. 인증이 필요한 API
                .requestMatchers(
                    "/api/logout",  // 로그아웃은 로그인한 사용자만 가능
                    "/api/my/info"
                    // TODO: 향후 추가될 인증필요 API (ex: /api/reviews, /api/comments 등)
                ).authenticated()

                // 3. 그 외 나머지 요청은 일단 모두 허용 (개발 편의성)
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
                .authenticationEntryPoint((request, response, authException) -> {
                    // 클라이언트 유형(웹/앱)에 관계없이 항상 JSON으로 에러 응답을 보냅니다.
                    // 클라이언트 측에서 이 응답을 받고 로그인 페이지로 리디렉션할지 결정해야 합니다.
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json;charset=UTF-8");

                    String errorCause = request.getAttribute("ERROR_CAUSE") != null ? (String) request.getAttribute("ERROR_CAUSE") : "NOT_AUTHENTICATED";
                    String errorMessage = "인증이 필요합니다.";

                    if ("토큰만료".equals(errorCause)) {
                        errorMessage = "Access Token expired";
                    } else if ("로그인실패".equals(errorCause)) {
                        errorMessage = "아이디 또는 비밀번호가 일치하지 않습니다.";
                    }

                    response.getWriter().write(String.format("{\"error\": \"%s\", \"cause\": \"%s\"}", errorMessage, errorCause));
                })
            );
        return http.build();
    }


}

