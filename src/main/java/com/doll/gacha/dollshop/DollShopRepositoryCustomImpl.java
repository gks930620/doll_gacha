package com.doll.gacha.dollshop;

import static com.doll.gacha.dollshop.QDollShop.dollShop;
import static com.doll.gacha.common.entity.QFileEntity.fileEntity;

import com.doll.gacha.common.entity.FileEntity;
import com.querydsl.core.types.dsl.BooleanExpression;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RequiredArgsConstructor
public class DollShopRepositoryCustomImpl implements DollShopRepositoryCustom {
    private final JPAQueryFactory queryFactory;


    @Override
    public Page<DollShop> searchByConditions(DollShopSearchDTO searchDTO, Pageable pageable) {
        // 동적 쿼리 - 조건이 있으면 추가, 없으면 무시
        List<DollShop> content = queryFactory
            .selectFrom(dollShop)
            .where(
                eqGubun1(searchDTO.getGubun1()),
                eqGubun2(searchDTO.getGubun2()),
                eqIsOperating(searchDTO.getIsOperating()),
                containsKeyword(searchDTO.getKeyword())
            )
            .offset(pageable.getOffset())
            .limit(pageable.getPageSize())
            .orderBy(dollShop.id.desc())  // 기본 정렬: id 내림차순
            .fetch();

        // N+1 방지: 조회된 shop들의 썸네일 이미지를 한 번에 조회
        if (!content.isEmpty()) {
            List<Long> shopIds = content.stream()
                    .map(DollShop::getId)
                    .toList();

            // LEFT JOIN으로 썸네일 이미지 조회
            List<FileEntity> files = queryFactory
                    .selectFrom(fileEntity)
                    .where(
                            fileEntity.refId.in(shopIds),
                            fileEntity.refType.eq(FileEntity.RefType.DOLL_SHOP),
                            fileEntity.fileUsage.eq(FileEntity.Usage.THUMBNAIL)
                    )
                    .fetch();

            // Map으로 변환
            Map<Long, String> imagePathMap = files.stream()
                    .collect(Collectors.toMap(
                            FileEntity::getRefId,
                            file -> "/uploads/" + file.getStoredFileName(),
                            (existing, replacement) -> existing
                    ));

            // DollShop 엔티티에 imagePath 세팅
            content.forEach(shop -> {
                String imagePath = imagePathMap.get(shop.getId());
                if (imagePath != null) {
                    shop.setImagePath(imagePath);
                }
            });
        }

        // 전체 개수 조회
        Long total = queryFactory
            .select(dollShop.count())
            .from(dollShop)
            .where(
                eqGubun1(searchDTO.getGubun1()),
                eqGubun2(searchDTO.getGubun2()),
                eqIsOperating(searchDTO.getIsOperating()),
                containsKeyword(searchDTO.getKeyword())
            )
            .fetchOne();

        return new PageImpl<>(content, pageable, total != null ? total : 0L);
    }



    @Override
    public List<DollShop> searchForMap(DollShopSearchDTO searchDTO) {
        // 지도용 - 이미지 제외, 페이징 없음, 전체 조회
        return queryFactory
            .selectFrom(dollShop)
            .where(
                eqGubun1(searchDTO.getGubun1()),
                eqGubun2(searchDTO.getGubun2())
            )
            .orderBy(dollShop.id.desc())
            .fetch();
    }

    private BooleanExpression eqGubun1(String gubun1) {
        return gubun1 != null && !gubun1.isEmpty() ? dollShop.gubun1.eq(gubun1) : null;
    }

    private BooleanExpression eqGubun2(String gubun2) {
        return gubun2 != null && !gubun2.isEmpty() ? dollShop.gubun2.eq(gubun2) : null;
    }

    private BooleanExpression eqIsOperating(Boolean isOperating) {
        return isOperating != null ? dollShop.isOperating.eq(isOperating) : null;
    }

    private BooleanExpression containsKeyword(String keyword) {
        return keyword != null && !keyword.isEmpty() ?
            dollShop.businessName.containsIgnoreCase(keyword)
            .or(dollShop.address.containsIgnoreCase(keyword)) : null;
    }
}
