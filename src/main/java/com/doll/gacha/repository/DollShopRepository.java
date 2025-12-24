package com.doll.gacha.repository;

import com.doll.gacha.entity.DollShop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DollShopRepository extends JpaRepository<DollShop, Long> {

    List<DollShop> findByGubun1AndGubun2(String gubun1, String gubun2);

    List<DollShop> findByGubun1(String gubun1);

    List<DollShop> findByIsOperating(Boolean isOperating);
}

