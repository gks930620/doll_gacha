package com.doll.gacha.review;

import com.doll.gacha.dollshop.DollShop;
import com.doll.gacha.dollshop.DollShopDTO;
import com.doll.gacha.dollshop.DollShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final DollShopRepository dollShopRepository;
    /**
     * 특정 가게의 리뷰 목록 조회 (전체 - 기존 메서드)
     */
    public List<ReviewDTO> getReviewsByDollShopId(Long dollShopId) {
        return reviewRepository.findByDollShopIdAndIsDeletedFalseOrderByCreatedAtDesc(dollShopId)
                .stream()
                .map(ReviewDTO::from)
                .toList();
    }

    /**
     * 특정 가게의 리뷰 목록 조회 - 페이징
     */
    public Page<ReviewDTO> getReviewsByDollShopIdPaged(Long dollShopId, Pageable pageable) {
        return reviewRepository.findByDollShopIdAndIsDeletedFalse(dollShopId, pageable)
                .map(ReviewDTO::from);
    }

    /**
     * 특정 가게의 리뷰 통계 조회
     */
    public ReviewStatsDTO getReviewStats(Long dollShopId) {
        ReviewStatsDTO stats = reviewRepository.findStatsByDollShopId(dollShopId);

        // 리뷰가 없는 경우 기본값 반환
        if (stats == null || stats.getTotalReviews() == null || stats.getTotalReviews() == 0) {
            return ReviewStatsDTO.builder()
                    .totalReviews(0L)
                    .avgRating(0.0)
                    .avgMachineStrength(0.0)
                    .avgLargeDollCost(0.0)
                    .avgMediumDollCost(0.0)
                    .avgSmallDollCost(0.0)
                    .build();
        }

        return stats;
    }
}