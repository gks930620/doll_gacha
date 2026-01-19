package com.doll.gacha.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
     * CORS 설정
     * - 현재: 같은 도메인이라 불필요하지만 미리 적용
     * - 나중에: 프론트엔드 분리 시 (Nginx + Spring API) 필요
     */
    @Configuration
    public  class CorsConfig implements WebMvcConfigurer {
    
        @Override
        public void addCorsMappings(CorsRegistry registry) {
            registry.addMapping("/api/**")
                    .allowedOrigins(
                            "http://localhost:3000",   // React 개발 서버
                            "http://localhost:5173",   // Vite 개발 서버
                            "http://localhost:8080"    // 현재 (같은 도메인)
                            // TODO: 운영 도메인 추가 예정
                            // "https://your-domain.com"
                    )
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("*")
                    .exposedHeaders("Set-Cookie")      // 쿠키 응답 헤더 노출
                    .allowCredentials(true)            // 쿠키 허용 (JWT 쿠키용)
                    .maxAge(3600);                     // preflight 캐시 1시간
        }
    }