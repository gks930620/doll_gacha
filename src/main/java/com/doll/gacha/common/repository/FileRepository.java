package com.doll.gacha.common.repository;

import com.doll.gacha.common.entity.FileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FileRepository extends JpaRepository<FileEntity, Long>, FileRepositoryCustom {
    // N+1 방지를 위한 IN 쿼리
    List<FileEntity> findByRefIdInAndRefType(List<Long> refIds, FileEntity.RefType refType);

}
