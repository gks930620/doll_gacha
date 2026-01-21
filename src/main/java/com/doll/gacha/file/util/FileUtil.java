package com.doll.gacha.file.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

/**
 * 파일 물리적 저장 유틸리티
 * DB와 무관한 순수 파일 저장 로직
 */
@Component
@Slf4j
public class FileUtil {

    @Value("${file.upload-dir:./uploads/}")
    private String uploadDir;

    /**
     * 단일 파일 저장
     * @param file 업로드할 파일
     * @return 저장된 파일 정보 (FileUploadResult)
     */
    public FileUploadResult saveFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("파일이 비어있습니다");
        }

        // 업로드 디렉토리 생성
        ensureUploadDirectoryExists();

        try {
            // 고유한 파일명 생성
            String originalFilename = file.getOriginalFilename();
            String extension = extractExtension(originalFilename);
            String storedFilename = generateUniqueFilename(extension);

            // 파일 저장 - Paths.resolve()로 안전하게 경로 결합
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Path filePath = uploadPath.resolve(storedFilename);
            Files.write(filePath, file.getBytes());

            log.info("파일 저장 완료 - 원본: {}, 저장: {}, 경로: {}", originalFilename, storedFilename, filePath);

            // 저장된 파일 정보 반환
            return FileUploadResult.builder()
                    .originalFilename(originalFilename)
                    .storedFilename(storedFilename)
                    .filePath(filePath.toString())
                    .fileSize(file.getSize())
                    .contentType(file.getContentType())
                    .build();

        } catch (IOException e) {
            log.error("파일 저장 실패: {}", e.getMessage(), e);
            throw new RuntimeException("파일 저장 실패: " + file.getOriginalFilename(), e);
        }
    }

    /**
     * 업로드 디렉토리 존재 확인 및 생성
     */
    private void ensureUploadDirectoryExists() {
        try {
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                log.info("업로드 디렉토리 생성: {}", uploadPath);
            }
        } catch (IOException e) {
            throw new RuntimeException("업로드 디렉토리 생성 실패", e);
        }
    }

    /**
     * 파일 확장자 추출
     */
    private String extractExtension(String filename) {
        if (filename != null && filename.contains(".")) {
            return filename.substring(filename.lastIndexOf("."));
        }
        return "";
    }

    /**
     * 고유한 파일명 생성 (UUID + 확장자)
     */
    private String generateUniqueFilename(String extension) {
        return UUID.randomUUID() + extension;
    }

    /**
     * 업로드 디렉토리 경로 반환
     */
    public String getUploadDir() {
        return uploadDir;
    }

    /**
     * 파일 저장 결과 DTO
     */
    @lombok.Getter
    @lombok.Builder
    public static class FileUploadResult {
        private String originalFilename;
        private String storedFilename;
        private String filePath;
        private Long fileSize;
        private String contentType;
    }
}

