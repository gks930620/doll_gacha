package com.doll.gacha.common.repository;

import com.doll.gacha.common.entity.FileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FileRepository extends JpaRepository<FileEntity, Long>, FileRepositoryCustom {
    List<FileEntity> findByRefIdAndRefType(Long refId, FileEntity.RefType refType);

    // N+1 방지를 위한 IN 쿼리
    List<FileEntity> findByRefIdInAndRefType(List<Long> refIds, FileEntity.RefType refType);

    // fileUsage 조건 추가
    List<FileEntity> findByRefIdAndRefTypeAndFileUsage(Long refId, FileEntity.RefType refType, FileEntity.Usage fileUsage);

    // fileUsage 조건 + IN 쿼리 (N+1 방지)
    List<FileEntity> findByRefIdInAndRefTypeAndFileUsage(List<Long> refIds, FileEntity.RefType refType, FileEntity.Usage fileUsage);
}
