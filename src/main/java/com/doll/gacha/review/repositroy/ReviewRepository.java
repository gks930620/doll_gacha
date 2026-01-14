package com.doll.gacha.review.repositroy;

import com.doll.gacha.review.ReviewEntity;
import com.doll.gacha.review.dto.ReviewStatsDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ReviewRepository extends JpaRepository<ReviewEntity, Long> {

    // 특정 가게의 리뷰 목록 조회 - 페이징, User fetch join
    @Query(value = """
        SELECT r
        FROM ReviewEntity r
        JOIN FETCH r.user
        WHERE r.dollShop.id = :dollShopId
        AND r.isDeleted = false
        ORDER BY r.createdAt DESC
    """,
    countQuery = """
        SELECT COUNT(r)
        FROM ReviewEntity r
        WHERE r.dollShop.id = :dollShopId
        AND r.isDeleted = false
    """)
    Page<ReviewEntity> findByDollShopIdWithUser(@Param("dollShopId") Long dollShopId, Pageable pageable);

    // 특정 가게의 리뷰 통계 조회
    @Query("""
        SELECT new com.doll.gacha.review.dto.ReviewStatsDTO(
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

