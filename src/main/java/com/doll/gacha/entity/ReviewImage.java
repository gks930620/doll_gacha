package com.doll.gacha.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "review_images")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 소속 리뷰 (N:1 - 여러 이미지는 한 리뷰에 속함)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "review_id", nullable = false)
    private Review review;

    // 이미지 URL
    @Column(nullable = false, length = 500)
    private String imageUrl;

    // 이미지 순서 (리뷰 내에서의 표시 순서)
    @Column(nullable = false)
    private Integer displayOrder;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}

