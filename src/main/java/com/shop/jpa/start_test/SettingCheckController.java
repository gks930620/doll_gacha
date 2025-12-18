package com.shop.jpa.start_test;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.PersistenceUnit;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class SettingCheckController {
    @PersistenceUnit
    private EntityManagerFactory emf;

    @Autowired
    private  TestEntityRepository testEntityRepository;


    @RequestMapping(value = {"/test"})
    public String home(Model model){
        EntityManager em = emf.createEntityManager();
        TestEntity test = em.find(TestEntity.class, "test");
        model.addAttribute("test",test);
        em.close();
        return "test";
    }

    @RequestMapping(value = {"/test2"})
    public String home2(Model model){
        TestEntity test2 = testEntityRepository.findById("test2").get();
        model.addAttribute("test2",test2);
        return "test2";
    }


}
