package com.doll.gacha.review;

import com.doll.gacha.dollshop.DollShopRepository;
import com.doll.gacha.jwt.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reviews")
@RequiredArgsConstructor
@Slf4j
public class ReviewController {

    private final ReviewService reviewService;

    /**
     * 특정 가게의 리뷰 목록 조회 - 페이징
     * @param dollShopId 가게 ID
     * @param page 페이지 번호 (0부터 시작)
     * @param size 페이지 크기 (기본값: 10)
     * @return 페이징된 리뷰 목록
     */
    @GetMapping("/doll-shop/{dollShopId}")
    public ResponseEntity<Page<ReviewDTO>> getShopReviews(
        @PathVariable Long dollShopId,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size) {

        // 최신순으로 정렬 (createdAt 내림차순)
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<ReviewDTO> reviews = reviewService.getReviewsByDollShopIdPaged(dollShopId, pageable);

        return ResponseEntity.ok(reviews);
    }

    /**
     * 특정 가게의 리뷰 통계 조회
     * @param dollShopId 가게 ID
     * @return 리뷰 통계 (평균 별점, 기계 힘, 비용 등)
     */
    @GetMapping("/doll-shop/{dollShopId}/stats")
    public ResponseEntity<ReviewStatsDTO> getShopReviewStats(@PathVariable Long dollShopId) {
        ReviewStatsDTO stats = reviewService.getReviewStats(dollShopId);
        return ResponseEntity.ok(stats);
    }
}
