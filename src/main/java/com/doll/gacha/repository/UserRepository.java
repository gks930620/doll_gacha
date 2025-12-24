package com.doll.gacha.repository;

import com.doll.gacha.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByProviderAndProviderId(User.OAuthProvider provider, String providerId);

    boolean existsByEmail(String email);
}

