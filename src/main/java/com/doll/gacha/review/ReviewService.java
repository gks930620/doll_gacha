package com.doll.gacha.review;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewService {

    private final ReviewRepository reviewRepository;

    /**
     * 특정 사용자의 리뷰 목록 조회
     */
    public List<ReviewEntity> getMyReviews(Long userId) {
        return reviewRepository.findByUserIdAndIsDeletedFalseOrderByCreatedAtDesc(userId);
    }

    /**
     * 리뷰 상세 조회
     */
    public ReviewEntity getReview(Long reviewId) {
        return reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다."));
    }

    /**
     * 리뷰 작성
     */
    @Transactional
    public ReviewEntity createReview(ReviewEntity review) {
        return reviewRepository.save(review);
    }

    /**
     * 리뷰 수정
     */
    @Transactional
    public ReviewEntity updateReview(Long reviewId, ReviewEntity updateData) {
        ReviewEntity review = getReview(reviewId);

        // 수정 가능한 필드만 업데이트
        review.setContent(updateData.getContent());
        review.setRating(updateData.getRating());
        review.setMachineStrength(updateData.getMachineStrength());
        review.setLargeDollCost(updateData.getLargeDollCost());
        review.setMediumDollCost(updateData.getMediumDollCost());
        review.setSmallDollCost(updateData.getSmallDollCost());

        return review;
    }

    /**
     * 리뷰 삭제 (소프트 삭제)
     */
    @Transactional
    public void deleteReview(Long reviewId) {
        ReviewEntity review = getReview(reviewId);
        review.setIsDeleted(true);
    }

    /**
     * 특정 가게의 리뷰 목록 조회
     */
    public List<ReviewEntity> getShopReviews(Long dollShopId) {
        return reviewRepository.findByDollShopIdAndIsDeletedFalseOrderByCreatedAtDesc(dollShopId);
    }
}

