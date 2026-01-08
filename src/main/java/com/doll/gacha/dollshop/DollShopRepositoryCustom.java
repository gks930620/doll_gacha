package com.doll.gacha.dollshop;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface DollShopRepositoryCustom {

    // QueryDSL 동적 쿼리로 검색 (페이징) - 썸네일 이미지 포함
    Page<DollShop> searchByConditions(DollShopSearchDTO searchDTO, Pageable pageable);

    // 지도용 - 이미지 제외, 페이징 없음
    List<DollShop> searchForMap(DollShopSearchDTO searchDTO);
}
