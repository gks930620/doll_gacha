package com.shop.jpa.start_test;

import jakarta.annotation.PostConstruct;
import jakarta.persistence.*;
import org.springframework.stereotype.Component;


/**
 * 여기는 spring을 배웠든 안 배웠든 처음 시작시 더미데이터 넣는 코드
 */
@Component
public class JPAInitializer {
    @PersistenceUnit
    private EntityManagerFactory emf;

    @PostConstruct
    public void init() {
        EntityManager em = emf.createEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            TestEntity test = new TestEntity("test");
            em.persist(test);
            tx.commit();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            em.close();
        }

    }
}
