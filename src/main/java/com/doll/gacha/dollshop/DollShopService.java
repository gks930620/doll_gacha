package com.doll.gacha.dollshop;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DollShopService {

    private final DollShopRepository dollShopRepository;

    /**
     * 시도와 시군구로 가게 검색
     */
    public List<DollShop> findByGubun1AndGubun2(String gubun1, String gubun2) {
        return dollShopRepository.findByGubun1AndGubun2(gubun1, gubun2);
    }

    /**
     * 시도로만 가게 검색
     */
    public List<DollShop> findByGubun1(String gubun1) {
        return dollShopRepository.findByGubun1(gubun1);
    }

    /**
     * 운영중인 가게만 검색
     */
    public List<DollShop> findOperatingShops() {
        return dollShopRepository.findByIsOperating(true);
    }

    /**
     * 모든 가게 검색
     */
    public List<DollShop> findAll() {
        return dollShopRepository.findAll();
    }
}

