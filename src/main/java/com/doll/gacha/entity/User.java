package com.doll.gacha.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(length = 50)
    private String name;

    @Column(length = 50)
    private String nickname;

    @Column(length = 500)
    private String profileImageUrl;

    // OAuth 제공자 (KAKAO, GOOGLE, LOCAL)
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private OAuthProvider provider;

    // OAuth 제공자의 사용자 ID
    @Column(length = 100)
    private String providerId;

    // 역할 (USER, ADMIN)
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private Role role;

    @Column(nullable = false)
    private Boolean isActive;

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

    public enum OAuthProvider {
        KAKAO, GOOGLE, LOCAL
    }

    public enum Role {
        USER, ADMIN
    }
}

