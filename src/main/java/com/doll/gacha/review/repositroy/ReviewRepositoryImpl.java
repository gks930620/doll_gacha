package com.doll.gacha.review.repositroy;

import com.doll.gacha.common.entity.FileEntity;
import com.doll.gacha.common.entity.QFileEntity;
import com.doll.gacha.jwt.entity.QUserEntity;
import com.doll.gacha.review.QReviewEntity;
import com.doll.gacha.review.ReviewEntity;
import com.doll.gacha.review.dto.ReviewDTO;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class ReviewRepositoryImpl implements ReviewRepositoryCustom {

    private final JPAQueryFactory queryFactory;

    @Override
    public Page<ReviewDTO> findReviewsWithFilesByDollShopId(Long dollShopId, Pageable pageable) {
        QReviewEntity review = QReviewEntity.reviewEntity;
        QUserEntity user = QUserEntity.userEntity;
        QFileEntity file = QFileEntity.fileEntity;

        // 1. 전체 카운트 조회
        Long total = queryFactory
                .select(review.count())
                .from(review)
                .where(
                        review.dollShop.id.eq(dollShopId),
                        review.isDeleted.eq(false)
                )
                .fetchOne();

        if (total == null || total == 0) {
            return Page.empty(pageable);
        }

        // 2. 리뷰 Entity 목록 조회 (User Fetch Join)
        List<ReviewEntity> entities = queryFactory
                .selectFrom(review)
                .join(review.user, user).fetchJoin()
                .where(
                        review.dollShop.id.eq(dollShopId),
                        review.isDeleted.eq(false)
                )
                .orderBy(review.createdAt.desc())
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        // 3. ID 목록 추출
        List<Long> reviewIds = entities.stream()
                .map(ReviewEntity::getId)
                .toList();

        // 4. 파일 URL 조회 (IN 쿼리 사용 - 원칙 준수)
        Map<Long, List<String>> fileUrlsMap;
        if (reviewIds.isEmpty()) {
            fileUrlsMap = Collections.emptyMap();
        } else {
            List<FileEntity> files = queryFactory
                    .selectFrom(file)
                    .where(
                            file.refId.in(reviewIds),
                            file.refType.eq(FileEntity.RefType.REVIEW)
                    )
                    .fetch();

            fileUrlsMap = files.stream()
                    .collect(Collectors.groupingBy(
                            FileEntity::getRefId,
                            Collectors.mapping(
                                    f -> "/uploads/" + f.getStoredFileName(),
                                    Collectors.toList()
                            )
                    ));
        }

        // 5. DTO 변환 및 반환
        List<ReviewDTO> content = entities.stream()
                .map(entity -> ReviewDTO.from(
                        entity,
                        fileUrlsMap.getOrDefault(entity.getId(), List.of())
                ))
                .toList();

        return new PageImpl<>(content, pageable, total);
    }
}

