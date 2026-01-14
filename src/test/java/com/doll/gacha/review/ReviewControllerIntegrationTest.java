package com.doll.gacha.review;

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
@DisplayName("Review Controller 통합 테스트")
class ReviewControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("특정 매장의 리뷰 목록 조회 (페이징)")
    void getReviewsByDollShop_success() throws Exception {
        // 실제 존재하는 매장 ID (예: 857)
        mockMvc.perform(get("/api/reviews/doll-shop/{dollShopId}", 857)
                        .param("page", "0")
                        .param("size", "10"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.pageable").exists())
                .andExpect(jsonPath("$.totalElements").exists());
    }

    @Test
    @DisplayName("특정 매장의 리뷰 통계 조회")
    void getReviewStats_success() throws Exception {
        // 실제 존재하는 매장 ID
        mockMvc.perform(get("/api/reviews/doll-shop/{dollShopId}/stats", 857))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalReviews").exists())
                .andExpect(jsonPath("$.avgRating").exists())
                .andExpect(jsonPath("$.avgMachineStrength").exists())
                .andExpect(jsonPath("$.avgLargeDollCost").exists())
                .andExpect(jsonPath("$.avgMediumDollCost").exists())
                .andExpect(jsonPath("$.avgSmallDollCost").exists());
    }


    @Test
    @DisplayName("존재하지 않는 매장의 리뷰 조회")
    void getReviewsByDollShop_notFound() throws Exception {
        mockMvc.perform(get("/api/reviews/doll-shop/{dollShopId}", 999999)
                        .param("page", "0")
                        .param("size", "10"))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isEmpty()); // 빈 배열 반환
    }
}

