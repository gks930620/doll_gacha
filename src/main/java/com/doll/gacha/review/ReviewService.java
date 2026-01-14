package com.doll.gacha.review;

import com.doll.gacha.common.entity.FileEntity;
import com.doll.gacha.common.repository.FileRepository;
import com.doll.gacha.dollshop.DollShop;
import com.doll.gacha.dollshop.repositroy.DollShopRepository;
import com.doll.gacha.jwt.entity.UserEntity;
import com.doll.gacha.jwt.repository.UserRepository;
import com.doll.gacha.review.dto.ReviewCreateDTO;
import com.doll.gacha.review.dto.ReviewDTO;
import com.doll.gacha.review.dto.ReviewStatsDTO;
import com.doll.gacha.review.repositroy.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final DollShopRepository dollShopRepository;
    private final UserRepository userRepository;
    private final FileRepository fileRepository;

    /**
     * 특정 가게의 리뷰 목록 조회 - 페이징 (N+1 해결)
     */
    public Page<ReviewDTO> getReviewsByDollShopIdPaged(Long dollShopId, Pageable pageable) {
        // 1. 리뷰 페이지 조회 (User fetch join, total 포함)
        Page<ReviewEntity> reviewPage = reviewRepository.findByDollShopIdWithUser(dollShopId, pageable);

        if (reviewPage.isEmpty()) {
            return new PageImpl<>(List.of(), pageable, 0);
        }

        // 2. 리뷰 ID 목록 추출
        List<Long> reviewIds = reviewPage.getContent().stream()
                .map(ReviewEntity::getId)
                .toList();

        // 3. 파일 정보 한번에 조회 (IN 쿼리 - N+1 방지)
        List<FileEntity> files = fileRepository.findByRefIdInAndRefType(reviewIds, FileEntity.RefType.REVIEW);

        // 4. 리뷰 ID별로 파일 URL 그룹화
        Map<Long, List<String>> fileUrlsByReviewId = files.stream()
                .collect(Collectors.groupingBy(
                        FileEntity::getRefId,
                        Collectors.mapping(
                                file -> "/uploads/" + file.getStoredFileName(),
                                Collectors.toList()
                        )
                ));

        // 5. DTO 변환 및 파일 URL 설정
        List<ReviewDTO> dtos = reviewPage.getContent().stream()
                .map(review -> ReviewDTO.from(
                        review,
                        fileUrlsByReviewId.getOrDefault(review.getId(), List.of())
                ))
                .toList();

        return new PageImpl<>(dtos, pageable, reviewPage.getTotalElements());
    }

    /**
     * 특정 가게의 리뷰 통계 조회
     */
    public ReviewStatsDTO getReviewStats(Long dollShopId) {
        ReviewStatsDTO stats = reviewRepository.findStatsByDollShopId(dollShopId);
        // 리뷰가 없는 경우 기본값 반환
        if (stats == null || stats.getTotalReviews() == null || stats.getTotalReviews() == 0) {
            return ReviewStatsDTO.empty();
        }
        return stats;
    }

    /**
     * 리뷰 작성
     */
    @Transactional
    public ReviewDTO createReview(String username, ReviewCreateDTO createDTO) {
        // 사용자 조회
        UserEntity user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 가게 조회
        DollShop dollShop = dollShopRepository.findById(createDTO.getDollShopId())
                .orElseThrow(() -> new IllegalArgumentException("가게를 찾을 수 없습니다: " + createDTO.getDollShopId()));

        // DTO -> Entity 변환 및 저장
        ReviewEntity savedReview = reviewRepository.save(createDTO.toEntity(user, dollShop));

        return ReviewDTO.from(savedReview);
    }

    /**
     * 리뷰 삭제 (Soft Delete)
     *
     * @param reviewId 삭제할 리뷰 ID
     * @param username 요청한 사용자명 (본인 확인용)
     * @throws IllegalArgumentException 리뷰를 찾을 수 없거나, 본인의 리뷰가 아니거나, 이미 삭제된 경우
     */
    @Transactional
    public void deleteReview(Long reviewId, String username) {
        // 리뷰 조회
        ReviewEntity review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다: " + reviewId));
        // 본인 확인
        if (!review.getUser().getUsername().equals(username)) {
            throw new IllegalArgumentException("본인의 리뷰만 삭제할 수 있습니다.");
        }
        // 이미 삭제된 리뷰인지 확인
        if (review.getIsDeleted()) {
            throw new IllegalArgumentException("이미 삭제된 리뷰입니다.");
        }

        review.setIsDeleted(true);
    }
}

