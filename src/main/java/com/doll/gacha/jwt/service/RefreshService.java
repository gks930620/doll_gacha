package com.doll.gacha.jwt.service;


import com.doll.gacha.jwt.JwtUtil;
import com.doll.gacha.jwt.entity.RefreshEntity;
import com.doll.gacha.jwt.repository.RefreshRepository;
import com.doll.gacha.jwt.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RefreshService {
    private  final RefreshRepository refreshRepository;
    private  final UserRepository userRepository;
    private  final JwtUtil jwtUtil;


    @Transactional(readOnly = false)
    public RefreshEntity getRefresh(String token){
        return refreshRepository.findByToken(token);
    }

    @Transactional(readOnly = false)
    public void saveRefresh(String token){
        String username = jwtUtil.extractUsername(token);
        refreshRepository.deleteByUserEntity_Username(username); // exists 체크 없이 바로 삭제 시도 (더 간결)

        RefreshEntity refreshEntity = new RefreshEntity();
        refreshEntity.setUserEntity(userRepository.findByUsername(username));
        refreshEntity.setToken(token);
        refreshRepository.save(refreshEntity);

    }
    @Transactional(readOnly = false)
    public void deleteRefresh(String token){
            refreshRepository.deleteByToken(token);
    }
}
