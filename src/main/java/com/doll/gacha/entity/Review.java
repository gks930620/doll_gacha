package com.doll.gacha.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "reviews")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 리뷰 작성자 (N:1 - 여러 리뷰는 한 사용자에게 속함)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 리뷰 대상 매장 (N:1 - 여러 리뷰는 한 매장에 속함)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doll_shop_id", nullable = false)
    private DollShop dollShop;

    // 리뷰 내용
    @Column(nullable = false, length = 2000)
    private String content;

    // 전체 별점 (1~5)
    @Column(nullable = false)
    private Integer rating;

    // 기계 힘 평가 (1~5)
    @Column(nullable = false)
    private Integer machineStrength;

    // 인형 크기별 지출 금액
    @Column
    private Integer largeDollCost;  // 대형 인형 1개당 지출

    @Column
    private Integer mediumDollCost; // 중형 인형 1개당 지출

    @Column
    private Integer smallDollCost;  // 소형 인형 1개당 지출

    // 리뷰 이미지들 (1:N - 한 리뷰는 여러 이미지를 가질 수 있음)
    @OneToMany(mappedBy = "review", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<ReviewImage> images = new ArrayList<>();

    // 삭제 여부
    @Column(nullable = false)
    @Builder.Default
    private Boolean isDeleted = false;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // 편의 메서드: 이미지 추가
    public void addImage(ReviewImage image) {
        images.add(image);
        image.setReview(this);
    }

    // 편의 메서드: 이미지 제거
    public void removeImage(ReviewImage image) {
        images.remove(image);
        image.setReview(null);
    }
}

