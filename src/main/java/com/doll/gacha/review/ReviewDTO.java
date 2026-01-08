package com.doll.gacha.review;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewDTO {
    private Long id;
    private Long userId;
    private String username;
    private Long dollShopId;
    private String content;
    private Integer rating;
    private Integer machineStrength;
    private Integer largeDollCost;
    private Integer mediumDollCost;
    private Integer smallDollCost;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static ReviewDTO from(ReviewEntity entity) {
        if (entity == null) {
            return null;
        }
        return ReviewDTO.builder()
                .id(entity.getId())
                .userId(entity.getUser().getId())
                .username(entity.getUser().getUsername())
                .dollShopId(entity.getDollShop().getId())
                .content(entity.getContent())
                .rating(entity.getRating())
                .machineStrength(entity.getMachineStrength())
                .largeDollCost(entity.getLargeDollCost())
                .mediumDollCost(entity.getMediumDollCost())
                .smallDollCost(entity.getSmallDollCost())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}

