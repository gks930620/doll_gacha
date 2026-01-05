package com.doll.gacha.dollshop;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/doll-shops")
@RequiredArgsConstructor
public class DollShopController {

    private final DollShopRepository dollShopRepository;

    /**
     * 모든 인형뽑기 가게 조회
     */
    @GetMapping
    public ResponseEntity<List<DollShop>> getAllShops() {
        return ResponseEntity.ok(dollShopRepository.findAll());
    }

    /**
     * gubun1(시/도)으로 검색
     */
    @GetMapping("/by-gubun1")
    public ResponseEntity<List<DollShop>> getShopsByGubun1(@RequestParam String gubun1) {
        return ResponseEntity.ok(dollShopRepository.findByGubun1(gubun1));
    }

    /**
     * gubun1(시/도)과 gubun2(시/군/구)로 검색
     */
    @GetMapping("/by-region")
    public ResponseEntity<List<DollShop>> getShopsByRegion(
            @RequestParam String gubun1,
            @RequestParam String gubun2) {
        return ResponseEntity.ok(dollShopRepository.findByGubun1AndGubun2(gubun1, gubun2));
    }

    /**
     * 운영중인 가게만 조회
     */
    @GetMapping("/operating")
    public ResponseEntity<List<DollShop>> getOperatingShops() {
        return ResponseEntity.ok(dollShopRepository.findByIsOperating(true));
    }

    /**
     * ID로 특정 가게 조회
     */
    @GetMapping("/{id}")
    public ResponseEntity<DollShop> getShopById(@PathVariable Long id) {
        return dollShopRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}

