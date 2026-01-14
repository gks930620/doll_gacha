package com.doll.gacha.community;

import com.doll.gacha.common.entity.FileEntity;
import com.doll.gacha.common.repository.FileRepository;
import com.doll.gacha.community.dto.CommunityCreateDTO;
import com.doll.gacha.community.dto.CommunityDTO;
import com.doll.gacha.community.dto.CommunityUpdateDTO;
import com.doll.gacha.community.repository.CommunityRepository;
import com.doll.gacha.jwt.entity.UserEntity;
import com.doll.gacha.jwt.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommunityService {

    private final CommunityRepository communityRepository;
    private final UserRepository userRepository;
    private final FileRepository fileRepository;

    /**
     * 게시글 작성
     */
    @Transactional
    public Long createCommunity(CommunityCreateDTO createDTO, String username) {
        UserEntity user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + username));

        CommunityEntity community = createDTO.toEntity(user);
        CommunityEntity savedCommunity = communityRepository.save(community);

        return savedCommunity.getId();
    }

    /**
     * 게시글 목록 조회 / 검색 - 페이징 (통합)
     * @param searchType 검색 타입 (null이면 전체 조회)
     * @param keyword 검색 키워드 (null이면 전체 조회)
     * @param pageable 페이징 정보
     * @return 페이징된 게시글 목록
     */
    public Page<CommunityDTO> getCommunityList(String searchType, String keyword, Pageable pageable) {
        // QueryDSL 동적 쿼리 - keyword가 null이면 전체 조회, 있으면 검색
        Page<CommunityEntity> communityPage = communityRepository.searchCommunity(searchType, keyword, pageable);

        if (communityPage.isEmpty()) {
            return new PageImpl<>(List.of(), pageable, 0);
        }

        // DTO 변환 (파일 정보 없이)
        List<CommunityDTO> dtos = communityPage.getContent().stream()
                .map(community -> CommunityDTO.from(
                        community,
                        List.of(), // imageUrls - 목록에서는 불필요
                        List.of()  // attachments - 목록에서는 불필요
                ))
                .toList();

        return new PageImpl<>(dtos, pageable, communityPage.getTotalElements());
    }

    /**
     * 게시글 상세 조회 (조회수 증가)
     */
    @Transactional
    public CommunityDTO getCommunityDetail(Long communityId) {
        // 1. 게시글 조회 (User fetch join)
        CommunityEntity community = communityRepository.findByIdWithUser(communityId);
        if (community == null || community.getIsDeleted()) {
            throw new IllegalArgumentException("게시글을 찾을 수 없습니다: " + communityId);
        }

        // 2. 조회수 증가
        community.incrementViewCount();

        // 3. 파일 조회
        List<FileEntity> files = fileRepository.findByRefIdInAndRefType(List.of(communityId), FileEntity.RefType.COMMUNITY);

        // 4. 이미지와 첨부파일 분리
        List<String> imageUrls = files.stream()
                .filter(file -> file.getFileUsage() == FileEntity.Usage.IMAGES)
                .map(file -> "/uploads/" + file.getStoredFileName())
                .toList();

        List<CommunityDTO.FileInfoDTO> attachments = files.stream()
                .filter(file -> file.getFileUsage() == FileEntity.Usage.ATTACHMENT)
                .map(file -> CommunityDTO.FileInfoDTO.builder()
                        .fileId(file.getId())
                        .originalFileName(file.getOriginalFileName())
                        .fileSize(file.getFileSize())
                        .downloadUrl("/api/files/download/" + file.getId())
                        .build())
                .toList();

        return CommunityDTO.from(community, imageUrls, attachments);
    }

    /**
     * 게시글 수정
     */
    @Transactional
    public void updateCommunity(Long communityId, CommunityUpdateDTO updateDTO, String username) {
        // 게시글 조회 (User fetch join으로 N+1 방지)
        CommunityEntity community = communityRepository.findByIdWithUser(communityId);
        if (community == null || community.getIsDeleted()) {
            throw new IllegalArgumentException("게시글을 찾을 수 없습니다: " + communityId);
        }

        // 본인 확인
        if (!community.isWrittenBy(username)) {
            throw new IllegalArgumentException("본인의 게시글만 수정할 수 있습니다.");
        }

        // 수정 (Dirty Checking으로 자동 UPDATE)
        community.update(updateDTO.getTitle(), updateDTO.getContent());
    }

    /**
     * 게시글 삭제 (Soft Delete)
     * 파일은 프론트에서 별도 API로 삭제 (일관성)
     */
    @Transactional
    public void deleteCommunity(Long communityId, String username) {
        // 게시글 조회 (User fetch join으로 N+1 방지)
        CommunityEntity community = communityRepository.findByIdWithUser(communityId);
        if (community == null) {
            throw new IllegalArgumentException("게시글을 찾을 수 없습니다: " + communityId);
        }

        // 본인 확인
        if (!community.isWrittenBy(username)) {
            throw new IllegalArgumentException("본인의 게시글만 삭제할 수 있습니다.");
        }

        // Soft Delete (Dirty Checking으로 자동 UPDATE)
        community.softDelete();

        // 파일은 프론트에서 DELETE /api/files/{fileId} 별도 호출
        // orphan 파일은 배치로 정리
    }
}

