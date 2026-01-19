package com.doll.gacha.file.service;

import com.doll.gacha.file.entity.FileEntity;
import com.doll.gacha.file.repository.FileRepository;
import com.doll.gacha.file.util.FileUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
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
                .toList();
    }

    /**
     * 파일 정보 DB 저장 (물리적 저장은 FileUtil에서 처리)
     * @param uploadResults FileUtil에서 저장한 파일 결과 리스트
     * @param refId 참조 ID
     * @param refType 참조 타입
     * @param usage 파일 용도
     * @return 저장된 파일 경로 리스트
     */
    @Transactional
    public List<String> saveFiles(List<FileUtil.FileUploadResult> uploadResults, Long refId,
                                   FileEntity.RefType refType, FileEntity.Usage usage) {
        return uploadResults.stream()
                .map(result -> {
                    FileEntity fileEntity = FileEntity.builder()
                            .originalFileName(result.getOriginalFilename())
                            .storedFileName(result.getStoredFilename())
                            .filePath(result.getFilePath())
                            .fileSize(result.getFileSize())
                            .contentType(result.getContentType())
                            .refId(refId)
                            .refType(refType)
                            .fileUsage(usage)
                            .build();

                    fileRepository.save(fileEntity);

                    log.info("파일 정보 DB 저장 완료 - refId: {}, refType: {}, 파일명: {}",
                            refId, refType, result.getStoredFilename());

                    return "/uploads/" + result.getStoredFilename();
                })
                .toList();
    }

    /**
     * 파일 ID로 파일 정보 조회 (다운로드용)
     * @param fileId 파일 ID
     * @return 파일 엔티티
     */
    public FileEntity getFileById(Long fileId) {
        return fileRepository.findById(fileId).orElse(null);
    }

    /**
     * 파일 삭제 (DB에서만 삭제, 물리 파일은 배치로 처리)
     * @param fileId 삭제할 파일 ID
     */
    @Transactional
    public void deleteFile(Long fileId) {
        FileEntity fileEntity = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("파일을 찾을 수 없습니다: " + fileId));

        fileRepository.delete(fileEntity);
        log.info("파일 삭제 완료 - fileId: {}, 파일명: {}", fileId, fileEntity.getOriginalFileName());
    }
}
