package com.doll.gacha.community.repository;

import com.doll.gacha.community.CommunityEntity;
import com.doll.gacha.community.QCommunityEntity;
import com.doll.gacha.jwt.entity.QUserEntity;
import com.querydsl.core.types.dsl.BooleanExpression;
import com.querydsl.jpa.impl.JPAQuery;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class CommunityRepositoryImpl implements CommunityRepositoryCustom {

    private final JPAQueryFactory queryFactory;

    @Override
    public Page<CommunityEntity> searchCommunity(String searchType, String keyword, Pageable pageable) {
        QCommunityEntity community = QCommunityEntity.communityEntity;
        QUserEntity user = QUserEntity.userEntity;

        // 전체 카운트 조회 (동적 조건 포함)
        long total = queryFactory
                .selectFrom(community)
                .where(
                        community.isDeleted.eq(false),
                        searchCondition(searchType, keyword) // keyword null이면 조건 무시
                )
                .fetch()
                .size();

        // 페이징 적용 및 결과 조회 (User fetch join)
        List<CommunityEntity> content = queryFactory
                .selectFrom(community)
                .join(community.user, user).fetchJoin()
                .where(
                        community.isDeleted.eq(false),
                        searchCondition(searchType, keyword) // keyword null이면 조건 무시
                )
                .orderBy(community.createdAt.desc()) // 최신순 정렬
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        return new PageImpl<>(content, pageable, total);
    }

    /**
     * 검색 조건 동적 생성
     * keyword가 null이면 null 반환 → where 조건에서 무시됨 (전체 조회)
     */
    private BooleanExpression searchCondition(String searchType, String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return null;
        }

        QCommunityEntity community = QCommunityEntity.communityEntity;
        QUserEntity user = QUserEntity.userEntity;

        String trimmedKeyword = keyword.trim();

        // 검색 타입에 따라 조건 분기
        return switch (searchType) {
            case "title" -> community.title.containsIgnoreCase(trimmedKeyword);
            case "nickname" -> user.nickname.containsIgnoreCase(trimmedKeyword);
            default -> null; // 잘못된 타입은 조건 없음
        };
    }
}

