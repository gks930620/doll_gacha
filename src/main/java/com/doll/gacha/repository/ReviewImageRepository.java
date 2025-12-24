package com.doll.gacha.repository;

import com.doll.gacha.entity.ReviewImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewImageRepository extends JpaRepository<ReviewImage, Long> {

    // 특정 리뷰의 이미지 목록 조회
    List<ReviewImage> findByReviewIdOrderByDisplayOrderAsc(Long reviewId);
}

