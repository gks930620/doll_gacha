package com.doll.gacha.service;

import com.doll.gacha.entity.DollShop;
import com.doll.gacha.entity.User;
import com.doll.gacha.repository.DollShopRepository;
import com.doll.gacha.repository.UserRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final DollShopRepository dollShopRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("===== 데이터 초기화 시작 =====");

        // User 테스트 데이터 추가
        if (userRepository.count() == 0) {
            initializeUsers();
        } else {
            log.info("User 데이터가 이미 존재합니다. 초기화를 건너뜁니다.");
        }

        // DollShop 데이터 추가
        if (dollShopRepository.count() == 0) {
            initializeDollShops();
        } else {
            log.info("DollShop 데이터가 이미 존재합니다. 초기화를 건너뜁니다.");
        }

        log.info("===== 데이터 초기화 완료 =====");
    }

    private void initializeUsers() {
        log.info("User 테스트 데이터 추가 중...");

        User kakaoUser = User.builder()
                .email("kakao_user@example.com")
                .name("카카오유저")
                .nickname("카톡러버")
                .profileImageUrl("https://example.com/profile1.jpg")
                .provider(User.OAuthProvider.KAKAO)
                .providerId("kakao_12345")
                .role(User.Role.USER)
                .isActive(true)
                .build();

        User googleUser = User.builder()
                .email("google_user@example.com")
                .name("구글유저")
                .nickname("구글러")
                .profileImageUrl("https://example.com/profile2.jpg")
                .provider(User.OAuthProvider.GOOGLE)
                .providerId("google_67890")
                .role(User.Role.USER)
                .isActive(true)
                .build();

        User adminUser = User.builder()
                .email("admin@dollcatch.com")
                .name("관리자")
                .nickname("돌캐치관리자")
                .profileImageUrl("https://example.com/admin.jpg")
                .provider(User.OAuthProvider.LOCAL)
                .providerId(null)
                .role(User.Role.ADMIN)
                .isActive(true)
                .build();

        userRepository.saveAll(List.of(kakaoUser, googleUser, adminUser));
        log.info("User 테스트 데이터 3개 추가 완료");
    }

    private void initializeDollShops() {
        log.info("DollShop 데이터 추가 중...");

        // 가게데이터 폴더 경로
        String basePath = "가게데이터";
        String[] jsonFiles = {
                "서울.json", "부산.json", "대구.json", "인천.json", "광주.json",
                "대전.json", "울산.json", "세종특별자치시.json", "경기도.json",
                "강원특별쟈치도.json", "충청북도.json", "충청남도.json",
                "전북특별자치도.json", "전라남도.json", "경상북도.json",
                "경상남도.json", "제주특별자치도.json"
        };

        int totalCount = 0;
        List<DollShop> allShops = new ArrayList<>();

        for (String fileName : jsonFiles) {
            try {
                File file = new File(basePath + File.separator + fileName);
                if (!file.exists()) {
                    log.warn("파일을 찾을 수 없습니다: {}", fileName);
                    continue;
                }

                List<Map<String, Object>> jsonData = objectMapper.readValue(
                        file,
                        new TypeReference<>() {}
                );

                for (Map<String, Object> data : jsonData) {
                    try {
                        DollShop shop = convertToDollShop(data);
                        allShops.add(shop);
                    } catch (Exception e) {
                        log.error("데이터 변환 실패: {}, 에러: {}", data, e.getMessage());
                    }
                }

                log.info("{} 파일 로드 완료: {}개", fileName, jsonData.size());
                totalCount += jsonData.size();

            } catch (IOException e) {
                log.error("파일 읽기 실패: {}", fileName, e);
            }
        }

        // 배치로 저장
        if (!allShops.isEmpty()) {
            dollShopRepository.saveAll(allShops);
            log.info("총 {}개의 DollShop 데이터 추가 완료", totalCount);
        }
    }

    private DollShop convertToDollShop(Map<String, Object> data) {
        String address = (String) data.get("address");
        String[] addressParts = parseAddress(address);

        return DollShop.builder()
                .id(((Number) data.get("id")).longValue())
                .businessName((String) data.get("businessName"))
                .longitude(((Number) data.get("longitude")).doubleValue())
                .latitude(((Number) data.get("latitude")).doubleValue())
                .address(address)
                .totalGameMachines(((Number) data.get("totalGameMachines")).intValue())
                .phone((String) data.get("phone"))
                .isOperating((Boolean) data.get("isOperating"))
                .approvalDate(LocalDate.parse((String) data.get("approvalDate")))
                .gubun1(addressParts[0])
                .gubun2(addressParts[1])
                .build();
    }

    /**
     * 주소에서 gubun1(시/도), gubun2(시/군/구)를 추출
     * 예: "서울특별시 강남구 테헤란로 123" -> ["서울특별시", "강남구"]
     * 예: "경기도 수원시 영통구 대학로 123" -> ["경기도", "수원시"]
     */
    private String[] parseAddress(String address) {
        String[] parts = address.split(" ");
        String gubun1 = parts[0]; // 서울특별시, 경기도 등
        String gubun2 = parts.length > 1 ? parts[1] : ""; // 강남구, 수원시 등

        return new String[]{gubun1, gubun2};
    }
}

