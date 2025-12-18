package com.shop.jpa.start_test;

import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.PersistenceUnit;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;


/**
 * 여기는 spring을 배웠든 안 배웠든 처음 시작시 더미데이터 넣는 코드
 */
@Component
public class JPAInitializer2 {
    @Autowired
    private  TestEntityRepository testEntityRepository;
    @PostConstruct
    @Transactional(readOnly = false)
    public void init() {
            TestEntity test = new TestEntity("test2");
            testEntityRepository.save(test);
    }

    


}
