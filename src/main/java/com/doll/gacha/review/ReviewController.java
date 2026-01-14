package com.doll.gacha.review;

import com.doll.gacha.jwt.model.CustomUserAccount;
import com.doll.gacha.review.dto.ReviewCreateDTO;
import com.doll.gacha.review.dto.ReviewDTO;
import com.doll.gacha.review.dto.ReviewStatsDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    /**
     * 특정 가게의 리뷰 목록 조회 - 페이징
     *
     * @param dollShopId 가게 ID
     * @param pageable 페이징 정보 (Spring이 자동 변환)
     *                 - page: 페이지 번호 (0부터 시작, 기본값: 0)
     *                 - size: 페이지 크기 (기본값: 10)
     *                 - sort: 정렬 (예: createdAt,desc)
     * @return 페이징된 리뷰 목록
     */
    @GetMapping("/doll-shop/{dollShopId}")
    public ResponseEntity<Page<ReviewDTO>> getShopReviews(
            @PathVariable Long dollShopId,
            Pageable pageable) {
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

    /**
     * 리뷰 작성 (인증 필요)
     * SecurityConfig에서 POST /api/reviews/** 에 대해 authenticated() 설정됨
     *
     * @param createDTO 리뷰 작성 정보
     * @param userAccount 현재 로그인한 사용자 정보 (Spring Security가 자동 주입)
     * @return 생성된 리뷰 정보
     */
    @PostMapping
    public ResponseEntity<ReviewDTO> createReview(
            @Valid @RequestBody ReviewCreateDTO createDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {
        String username = userAccount.getUsername();
        ReviewDTO createdReview = reviewService.createReview(username, createDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdReview);
    }

    /**
     * 리뷰 삭제 (인증 필요)
     * SecurityConfig에서 DELETE /api/reviews/** 에 대해 authenticated() 설정됨
     *
     * @param reviewId 삭제할 리뷰 ID
     * @param userAccount 현재 로그인한 사용자 정보 (Spring Security가 자동 주입)
     * @return 삭제 성공 응답 (204 No Content)
     */
    @DeleteMapping("/{reviewId}")
    public ResponseEntity<Void> deleteReview(
            @PathVariable Long reviewId,
            @AuthenticationPrincipal CustomUserAccount userAccount) {
        String username = userAccount.getUsername();
        reviewService.deleteReview(reviewId, username);
        return ResponseEntity.noContent().build();
    }
}
