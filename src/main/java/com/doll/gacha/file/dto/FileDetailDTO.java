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
    private String downloadUrl;  // CDN URL 또는 /uploads/xxx (다운로드용)
    private String previewUrl;   // CDN URL 또는 /uploads/xxx (미리보기용)

    public static FileDetailDTO from(FileEntity entity) {
        // filePath가 CDN URL이면 그대로 사용, 아니면 로컬 경로
        String fileUrl = entity.getFilePath();

        // CDN URL인지 확인 (https://로 시작하면 Supabase)
        boolean isCdnUrl = fileUrl != null && fileUrl.startsWith("http");

        return FileDetailDTO.builder()
                .fileId(entity.getId())
                .originalFileName(entity.getOriginalFileName())
                .storedFileName(entity.getStoredFileName())
                .fileSize(entity.getFileSize())
                // CDN URL이면 그대로 사용, 아니면 기존 서버 API 사용
                .downloadUrl(isCdnUrl ? fileUrl : "/api/files/download/" + entity.getId())
                .previewUrl(isCdnUrl ? fileUrl : "/uploads/" + entity.getStoredFileName())
                .build();
    }
}

