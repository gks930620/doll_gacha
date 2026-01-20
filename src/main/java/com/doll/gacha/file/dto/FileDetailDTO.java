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
    private String downloadUrl;
    private String previewUrl;

    public static FileDetailDTO from(FileEntity entity) {
        return FileDetailDTO.builder()
                .fileId(entity.getId())
                .originalFileName(entity.getOriginalFileName())
                .storedFileName(entity.getStoredFileName())
                .fileSize(entity.getFileSize())
                .downloadUrl("/api/files/download/" + entity.getId())
                .previewUrl("/uploads/" + entity.getStoredFileName())
                .build();
    }
}

