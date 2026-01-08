package com.doll.gacha.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 업로드된 이미지 파일을 제공하기 위한 설정
        // /uploads/** 요청이 들어오면 C:/workspace/simple_side/doll_gacha/uploads/ 폴더에서 파일을 찾음
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:///C:/workspace/simple_side/doll_gacha/uploads/");
    }
}

