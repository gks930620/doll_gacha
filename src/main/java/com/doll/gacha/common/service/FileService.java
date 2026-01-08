package com.doll.gacha.common.service;

import com.doll.gacha.common.entity.FileEntity;
import com.doll.gacha.common.repository.FileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FileService {

    private final FileRepository fileRepository;

    /**
     * 파일 경로 조회 (통합 검색 - QueryDSL 동적 쿼리)
     * @param refId 참조 ID
     * @param refType DOLL_SHOP, COMMUNITY, REVIEW, DOLL
     * @param usage THUMBNAIL, IMAGES, ATTACHMENT (선택, null 가능)
     * @return 파일 경로 리스트
     */
    public List<String> getFilePaths(Long refId, String refType, String usage) {
        FileEntity.RefType type = FileEntity.RefType.valueOf(refType);
        FileEntity.Usage usageType = usage != null && !usage.isEmpty()
                ? FileEntity.Usage.valueOf(usage)
                : null;

        // QueryDSL 동적 쿼리 실행
        List<FileEntity> files = fileRepository.searchFiles(refId, type, usageType);

        // 파일 경로 변환
        return files.stream()
                .map(file -> "/uploads/" + file.getStoredFileName())
                .collect(Collectors.toList());
    }
}
