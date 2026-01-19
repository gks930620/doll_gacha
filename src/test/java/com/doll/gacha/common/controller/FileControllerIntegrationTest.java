package com.doll.gacha.common.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
@DisplayName("File Controller 통합 테스트")
class FileControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("파일 조회 - 썸네일만 조회")
    void getFiles_thumbnail() throws Exception {
        // 테스트 환경(H2)에서는 파일 데이터가 없을 수 있으므로 배열만 검사
        mockMvc.perform(get("/api/files")
                        .param("refId", "857")
                        .param("refType", "DOLL_SHOP")
                        .param("usage", "THUMBNAIL"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray()); // 배열 응답
    }

    @Test
    @DisplayName("파일 조회 - 모든 이미지 조회 (usage 없음)")
    void getFiles_allImages() throws Exception {
        mockMvc.perform(get("/api/files")
                        .param("refId", "857")
                        .param("refType", "DOLL_SHOP"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray()); // 배열 응답
    }

    @Test
    @DisplayName("파일 조회 - IMAGES만 조회")
    void getFiles_contentImages() throws Exception {
        mockMvc.perform(get("/api/files")
                        .param("refId", "857")
                        .param("refType", "DOLL_SHOP")
                        .param("usage", "IMAGES"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray()); // 배열 응답
    }

    @Test
    @DisplayName("파일 조회 - 존재하지 않는 refId")
    void getFiles_notFound() throws Exception {
        mockMvc.perform(get("/api/files")
                        .param("refId", "999999")
                        .param("refType", "DOLL_SHOP")
                        .param("usage", "THUMBNAIL"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty()); // 빈 배열 반환
    }

    @Test
    @DisplayName("파일 조회 - 잘못된 RefType")
    void getFiles_invalidRefType() throws Exception {
        mockMvc.perform(get("/api/files")
                        .param("refId", "857")
                        .param("refType", "INVALID_TYPE")
                        .param("usage", "THUMBNAIL"))
                .andDo(print())
                .andExpect(status().isBadRequest()); // 400 Bad Request 예상 (Enum 변환 실패)
    }

    @Test
    @DisplayName("파일 서빙 - 실제 이미지 파일")
    void serveFile_success() throws Exception {
        // 실제 존재하는 파일명으로 테스트 (dollshopImage.jpeg)
        mockMvc.perform(get("/images/dollshopImage.jpeg"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(header().exists("Content-Type"))
                .andExpect(content().contentTypeCompatibleWith("image/jpeg"));
    }

    @Test
    @DisplayName("파일 서빙 - 존재하지 않는 파일")
    void serveFile_notFound() throws Exception {
        mockMvc.perform(get("/images/notexist.jpeg"))
                .andDo(print())
                .andExpect(status().isNotFound());
    }
}

