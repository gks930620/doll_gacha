package com.doll.gacha.file.controller;

import com.doll.gacha.common.dto.ApiResponse;
import com.doll.gacha.file.dto.FileDetailDTO;
import com.doll.gacha.file.entity.FileEntity;
import com.doll.gacha.file.service.FileService;
import com.doll.gacha.file.util.FileUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
public class FileController {
    private final FileService fileService;
    private final FileUtil fileUtil;

    /**
     * 이미지 파일 서빙 (HTML img 태그에서 호출)
     */
    @GetMapping("/images/{filename:.+}")
    public ResponseEntity<Resource> serveFile(@PathVariable String filename) {
        try {
            Path file = Paths.get(fileUtil.getUploadDir()).resolve(filename);
            Resource resource = new UrlResource(file.toUri());

            if (resource.exists() || resource.isReadable()) {
                String contentType = "image/jpeg"; // 기본값
                if (filename.toLowerCase().endsWith(".png")) contentType = "image/png";
                else if (filename.toLowerCase().endsWith(".gif")) contentType = "image/gif";

                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (MalformedURLException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * 파일 검색 API (통합)
     * @param refId 참조 ID
     * @param refType DOLL_SHOP, COMMUNITY, REVIEW, DOLL
     * @param usage THUMBNAIL, IMAGES, ATTACHMENT (선택)
     * @return 파일 경로 리스트
     */
    @GetMapping("/api/files")
    public ResponseEntity<List<String>> getFiles(
            @RequestParam Long refId,
            @RequestParam String refType,
            @RequestParam(required = false) String usage) {


        try {
            List<String> filePaths = fileService.getFilePaths(refId, refType, usage);
            return ResponseEntity.ok(filePaths);
        } catch (IllegalArgumentException e) {
            log.error("잘못된 파라미터: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * 파일 업로드 API (공통)
     * @param files 업로드할 파일들
     * @param refId 참조 ID (리뷰 ID, 가게 ID 등)
     * @param refType DOLL_SHOP, COMMUNITY, REVIEW, DOLL
     * @param usage THUMBNAIL, IMAGES, ATTACHMENT
     * @return 업로드된 파일 경로 리스트
     */
    @PostMapping("/api/files/upload")
    public ResponseEntity<ApiResponse<List<String>>> uploadFiles(
            @RequestParam("files") List<MultipartFile> files,
            @RequestParam Long refId,
            @RequestParam FileEntity.RefType refType,
            @RequestParam FileEntity.Usage usage) {

        try {
            // 1. FileUtil로 물리적 파일 저장
            List<FileUtil.FileUploadResult> uploadResults = files.stream()
                    .filter(file -> !file.isEmpty())
                    .map(fileUtil::saveFile)
                    .toList();

            log.info("파일 물리적 저장 완료 - 파일 수: {}", uploadResults.size());

            // 2. FileService로 DB에 파일 정보 저장
            List<String> savedPaths = fileService.saveFiles(uploadResults, refId, refType, usage);

            log.info("파일 업로드 완료 - refId: {}, refType: {}, 파일 수: {}", refId, refType, savedPaths.size());

            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success("파일 업로드 성공", savedPaths));

        } catch (IllegalArgumentException e) {
            log.error("잘못된 파라미터: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            log.error("파일 업로드 실패: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 첨부파일 상세 정보 조회 API (원본 파일명 포함)
     * @param refId 참조 ID
     * @param refType DOLL_SHOP, COMMUNITY, REVIEW, DOLL
     * @param usage THUMBNAIL, IMAGES, ATTACHMENT (선택)
     * @return 파일 상세 정보 리스트
     */
    @GetMapping("/api/files/detail")
    public ResponseEntity<ApiResponse<List<FileDetailDTO>>> getFileDetails(
            @RequestParam Long refId,
            @RequestParam String refType,
            @RequestParam(required = false) String usage) {
        try {
            List<FileDetailDTO> fileDetails = fileService.getFileDetails(refId, refType, usage);
            return ResponseEntity.ok(ApiResponse.success("파일 조회 성공", fileDetails));
        } catch (IllegalArgumentException e) {
            log.error("잘못된 파라미터: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * 첨부파일 다운로드 API
     * @param fileId 파일 ID
     * @return 파일 리소스 (원본 파일명으로 다운로드)
     */
    @GetMapping("/api/files/download/{fileId}")
    public ResponseEntity<Resource> downloadFile(@PathVariable Long fileId) {
        try {
            // 1. DB에서 파일 정보 조회
            FileEntity fileEntity = fileService.getFileById(fileId);
            if (fileEntity == null) {
                return ResponseEntity.notFound().build();
            }

            // 2. 물리적 파일 로드
            Path file = Paths.get(fileUtil.getUploadDir()).resolve(fileEntity.getStoredFileName());
            Resource resource = new UrlResource(file.toUri());

            if (!resource.exists() || !resource.isReadable()) {
                log.error("파일을 찾을 수 없습니다: {}", fileEntity.getStoredFileName());
                return ResponseEntity.notFound().build();
            }

            // 3. 원본 파일명 인코딩 (한글 파일명 지원)
            String encodedFileName = URLEncoder.encode(fileEntity.getOriginalFileName(), StandardCharsets.UTF_8)
                    .replaceAll("\\+", "%20");

            // 4. 다운로드 응답 헤더 설정
            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + encodedFileName + "\"")
                    .body(resource);

        } catch (MalformedURLException e) {
            log.error("파일 경로 오류: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            log.error("파일 다운로드 실패: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 파일 삭제 API
     * @param fileId 삭제할 파일 ID
     * @return 성공 시 삭제 완료 메시지
     */
    @DeleteMapping("/api/files/{fileId}")
    public ResponseEntity<ApiResponse<Void>> deleteFile(@PathVariable Long fileId) {
        try {
            log.info("파일 삭제 요청: fileId={}", fileId);
            fileService.deleteFile(fileId);
            return ResponseEntity.ok(ApiResponse.success("파일이 삭제되었습니다"));
        } catch (IllegalArgumentException e) {
            log.error("파일 삭제 실패: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("파일 삭제 에러: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
