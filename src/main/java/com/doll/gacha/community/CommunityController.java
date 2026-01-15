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
     * 게시글 목록 조회 / 검색 (페이징)
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
     */
    @GetMapping("/{communityId}")
    public ResponseEntity<CommunityDTO> getCommunityDetail(@PathVariable Long communityId) {
        CommunityDTO community = communityService.getCommunityDetail(communityId);
        return ResponseEntity.ok(community);
    }

    /**
     * 게시글 작성 (로그인 필요)
     */
    @PostMapping
    public ResponseEntity<Long> createCommunity(
            @Valid @RequestBody CommunityCreateDTO createDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        Long communityId = communityService.createCommunity(createDTO, userAccount.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(communityId);
    }

    /**
     * 게시글 수정 (로그인 필요, 작성자만)
     */
    @PutMapping("/{communityId}")
    public ResponseEntity<Void> updateCommunity(
            @PathVariable Long communityId,
            @Valid @RequestBody CommunityUpdateDTO updateDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        communityService.updateCommunity(communityId, updateDTO, userAccount.getUsername());
        return ResponseEntity.noContent().build();
    }

    /**
     * 게시글 삭제 (로그인 필요, 작성자만, Soft Delete)
     */
    @DeleteMapping("/{communityId}")
    public ResponseEntity<Void> deleteCommunity(
            @PathVariable Long communityId,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        communityService.deleteCommunity(communityId, userAccount.getUsername());
        return ResponseEntity.noContent().build();
    }
}

