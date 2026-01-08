package com.doll.gacha.dollshop;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/doll-shops")
@RequiredArgsConstructor
@Slf4j
public class DollShopController {
    private final DollShopService dollShopService;

    /**
     * 지도용 - 전체 매장 목록 조회 (gubun1, gubun2로 필터링 가능)
     * MapDTO로 필요한 데이터만 반환 (N+1 방지)
     */
    @GetMapping("/map")
    public ResponseEntity<List<DollShopMapDTO>> getShopsForMap(
            @RequestParam(required = false) String gubun1,
            @RequestParam(required = false) String gubun2) {

        log.info("지도용 매장 조회 - gubun1: {}, gubun2: {}", gubun1, gubun2);

        // SearchDTO 생성
        DollShopSearchDTO searchDTO = DollShopSearchDTO.builder()
                .gubun1(gubun1)
                .gubun2(gubun2)
                .build();

        // MapDTO List 반환
        List<DollShopMapDTO> list = dollShopService.searchShopsForMap(searchDTO);
        return ResponseEntity.ok(list);
    }

    /**
     * 게시판용 - 매장 목록 페이징 조회 (모든 검색 조건 지원)
     * @param searchDTO 검색 조건 (gubun1, gubun2, isOperating, keyword)
     * @param page 페이지 번호 (0부터 시작)
     * @param size 페이지 크기 (기본값: 10)
     * @param sortBy 정렬 기준 (기본값: id)
     * @param direction 정렬 방향 (기본값: DESC)
     * @return 페이징된 매장 목록
     */
    @GetMapping("/search")
    public ResponseEntity<Page<DollShopDTO>> searchShops(
            @ModelAttribute DollShopSearchDTO searchDTO,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "DESC") String direction) {

        Sort.Direction sortDirection = Sort.Direction.fromString(direction);
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sortBy));

        Page<DollShopDTO> shops = dollShopService.searchShopsPaged(searchDTO, pageable);
        return ResponseEntity.ok(shops);
    }

    /**
     * ID로 특정 가게 조회
     * 이미지는 클라이언트에서 /api/files/thumbnail?refType=DOLL_SHOP&refId={id} 로 별도 요청
     */
    @GetMapping("/{id}")
    public ResponseEntity<DollShopDTO> getShopById(@PathVariable Long id) {
        log.info("매장 상세 조회 - id: {}", id);
        return ResponseEntity.ok(dollShopService.getById(id));
    }
}
