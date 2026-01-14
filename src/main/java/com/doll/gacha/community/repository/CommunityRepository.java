package com.doll.gacha.community.repository;

import com.doll.gacha.community.CommunityEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommunityRepository extends JpaRepository<CommunityEntity, Long>, CommunityRepositoryCustom {

    // 게시글 단건 조회 - User fetch join (수정/삭제 시 사용)
    @Query("""
        SELECT c
        FROM CommunityEntity c
        JOIN FETCH c.user
        WHERE c.id = :communityId
    """)
    CommunityEntity findByIdWithUser(@Param("communityId") Long communityId);
}

