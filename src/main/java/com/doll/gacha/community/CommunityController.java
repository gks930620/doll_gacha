package com.doll.gacha.community;

import com.doll.gacha.community.dto.CommunityCreateDTO;
import com.doll.gacha.community.dto.CommunityDTO;
import com.doll.gacha.community.dto.CommunityUpdateDTO;
import com.doll.gacha.jwt.model.CustomUserAccount;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/community")
@RequiredArgsConstructor
public class CommunityController {

    private final CommunityService communityService;

    /**
     * 게시글 목록 조회 / 검색 - 페이징 (통합)
     *
     * @param searchType 검색 타입 ("title" 또는 "nickname") - 선택
     * @param keyword 검색 키워드 - 선택
     * @param pageable 페이징 정보 (Spring이 자동 변환)
     *                 - page: 페이지 번호 (0부터 시작, 기본값: 0)
     *                 - size: 페이지 크기 (기본값: 10)
     *                 - sort: 정렬 (예: createdAt,desc)
     * @return 페이징된 게시글 목록
     *
     * 사용 예시:
     * - 전체 목록: GET /api/community?page=0&size=10
     * - 검색: GET /api/community?searchType=title&keyword=인형&page=0&size=10
     */
    @GetMapping
    public ResponseEntity<Page<CommunityDTO>> getCommunityList(
            @RequestParam(required = false) String searchType,
            @RequestParam(required = false) String keyword,
            Pageable pageable) {
        Page<CommunityDTO> communities = communityService.getCommunityList(searchType, keyword, pageable);
        return ResponseEntity.ok(communities);
    }

    /**
     * 게시글 상세 조회 (조회수 증가)
     *
     * @param communityId 게시글 ID
     * @return 게시글 상세 정보 (이미지, 첨부파일 포함)
     */
    @GetMapping("/{communityId}")
    public ResponseEntity<CommunityDTO> getCommunityDetail(@PathVariable Long communityId) {
        CommunityDTO community = communityService.getCommunityDetail(communityId);
        return ResponseEntity.ok(community);
    }

    /**
     * 게시글 작성 (인증 필요)
     * SecurityConfig에서 POST /api/community/** 에 대해 authenticated() 설정 필요
     *
     * @param createDTO 게시글 작성 정보
     * @param userAccount 현재 로그인한 사용자 정보 (Spring Security가 자동 주입)
     * @return 생성된 게시글 ID
     */
    @PostMapping
    public ResponseEntity<Long> createCommunity(
            @Valid @RequestBody CommunityCreateDTO createDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        Long communityId = communityService.createCommunity(createDTO, userAccount.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(communityId);
    }

    /**
     * 게시글 수정 (인증 필요)
     *
     * @param communityId 수정할 게시글 ID
     * @param updateDTO 수정 정보
     * @param userAccount 현재 로그인한 사용자 정보
     * @return 성공 응답
     */
    @PutMapping("/{communityId}")
    public ResponseEntity<Void> updateCommunity(
            @PathVariable Long communityId,
            @Valid @RequestBody CommunityUpdateDTO updateDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        communityService.updateCommunity(communityId, updateDTO, userAccount.getUsername());
        return ResponseEntity.ok().build();
    }

    /**
     * 게시글 삭제 (인증 필요, Soft Delete)
     *
     * @param communityId 삭제할 게시글 ID
     * @param userAccount 현재 로그인한 사용자 정보
     * @return 성공 응답
     */
    @DeleteMapping("/{communityId}")
    public ResponseEntity<Void> deleteCommunity(
            @PathVariable Long communityId,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        communityService.deleteCommunity(communityId, userAccount.getUsername());
        return ResponseEntity.noContent().build();
    }
}

