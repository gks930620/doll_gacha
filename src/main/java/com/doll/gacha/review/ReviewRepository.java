package com.doll.gacha.review;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<ReviewEntity, Long> {

    // 특정 사용자의 리뷰 목록 조회 (삭제되지 않은 것만)
    List<ReviewEntity> findByUserIdAndIsDeletedFalseOrderByCreatedAtDesc(Long userId);

    // 특정 가게의 리뷰 목록 조회 (삭제되지 않은 것만)
    List<ReviewEntity> findByDollShopIdAndIsDeletedFalseOrderByCreatedAtDesc(Long dollShopId);

    // 특정 사용자의 특정 가게 리뷰 조회
    List<ReviewEntity> findByUserIdAndDollShopIdAndIsDeletedFalse(Long userId, Long dollShopId);
}

