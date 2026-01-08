package com.doll.gacha.review;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<ReviewEntity, Long> {

    // 특정 사용자의 리뷰 목록 조회 (삭제되지 않은 것만)
    List<ReviewEntity> findByUserIdAndIsDeletedFalseOrderByCreatedAtDesc(Long userId);

    // 특정 가게의 리뷰 목록 조회 (삭제되지 않은 것만)
    List<ReviewEntity> findByDollShopIdAndIsDeletedFalseOrderByCreatedAtDesc(Long dollShopId);

    // 특정 가게의 리뷰 목록 조회 - 페이징 (삭제되지 않은 것만)
    Page<ReviewEntity> findByDollShopIdAndIsDeletedFalse(Long dollShopId, Pageable pageable);

    // 특정 사용자의 특정 가게 리뷰 조회
    List<ReviewEntity> findByUserIdAndDollShopIdAndIsDeletedFalse(Long userId, Long dollShopId);

    // 특정 가게의 리뷰 통계 조회
    @Query("""
        SELECT new com.doll.gacha.review.ReviewStatsDTO(
            COUNT(r),
            AVG(r.rating),
            AVG(r.machineStrength),
            AVG(r.largeDollCost),
            AVG(r.mediumDollCost),
            AVG(r.smallDollCost)
        )
        FROM ReviewEntity r
        WHERE r.dollShop.id = :dollShopId
        AND r.isDeleted = false
    """)
    ReviewStatsDTO findStatsByDollShopId(@Param("dollShopId") Long dollShopId);
}

