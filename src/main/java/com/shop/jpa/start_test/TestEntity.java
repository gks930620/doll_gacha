package com.shop.jpa.start_test;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.*;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class TestEntity {
    @Id
    private  String id;


}
