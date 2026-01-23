package com.doll.gacha.file.dto;

import com.doll.gacha.file.entity.FileEntity;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FileDetailDTO {
    private Long fileId;
    private String originalFileName;
    private String storedFileName;
    private Long fileSize;
    private String downloadUrl;  // 다운로드용 (원본 파일명 필요 → 서버 API 유지)
    private String previewUrl;   // 미리보기용 (CDN 직접 사용 가능)

    public static FileDetailDTO from(FileEntity entity) {
        String fileUrl = entity.getFilePath();

        // CDN URL인지 확인 (https://로 시작하면 Supabase)
        boolean isCdnUrl = fileUrl != null && fileUrl.startsWith("http");

        return FileDetailDTO.builder()
                .fileId(entity.getId())
                .originalFileName(entity.getOriginalFileName())
                .storedFileName(entity.getStoredFileName())
                .fileSize(entity.getFileSize())
                // 다운로드: 원본 파일명이 필요하므로 서버 API 유지 (CDN은 UUID로 다운됨)
                .downloadUrl("/api/files/download/" + entity.getId())
                // 미리보기(이미지): CDN URL이면 직접 사용 (빠름!)
                .previewUrl(isCdnUrl ? fileUrl : "/uploads/" + entity.getStoredFileName())
                .build();
    }
}

