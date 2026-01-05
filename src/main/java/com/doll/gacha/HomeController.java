package com.doll.gacha;

import com.doll.gacha.dollshop.DollShop;
import com.doll.gacha.dollshop.DollShopRepository;
import com.doll.gacha.jwt.JwtUtil;
import com.doll.gacha.jwt.entity.UserEntity;
import com.doll.gacha.jwt.model.UserDTO;
import com.doll.gacha.jwt.repository.RefreshRepository;
import com.doll.gacha.jwt.repository.UserRepository;
import com.doll.gacha.jwt.service.CustomUserDetailsService;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.ExpiredJwtException;
import jakarta.servlet.http.HttpServletRequest;
import java.io.File;
import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "index";
    }

    @GetMapping("/map")
    public String map() {
        return "map";
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/signup")
    public String signup() {
        return "signup";
    }

    @GetMapping("/mypage")
    public String mypage() {
        return "mypage";
    }

    @GetMapping("/custom-oauth2/login/success")
    public String oauth2LoginSuccess() {
        return "oauth2-redirect";
    }

    @GetMapping("/community")
    public String community() {
        return "community/list";
    }

    @GetMapping("/community/write")
    public String communityWrite() {
        return "community/write";
    }

    @GetMapping("/community/detail")
    public String communityDetail() {
        return "community/detail";
    }

    @GetMapping("/doll")
    public String doll() {
        return "doll/list";
    }

    @GetMapping("/doll/write")
    public String dollWrite() {
        return "doll/write";
    }

    @GetMapping("/doll/detail")
    public String dollDetail() {
        return "doll/detail";
    }

    @Slf4j
    @Component
    @RequiredArgsConstructor
    public static class DataInitializer {

        private final DollShopRepository dollShopRepository;
        private final UserRepository userRepository;
        private final ObjectMapper objectMapper;

        //@PostConstruct
        public void init() {
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

            // 카카오 사용자
            UserEntity kakaoUser = UserEntity.builder()
                    .provider("kakao")
                    .username("kakao_user1")
                    .email("kakao_user@example.com")
                    .nickname("카톡러버")
                    .roles(new ArrayList<>(List.of("ROLE_USER")))
                    .build();

            // 구글 사용자
            UserEntity googleUser = UserEntity.builder()
                    .provider("google")
                    .username("google_user1")
                    .email("google_user@example.com")
                    .nickname("구글러")
                    .roles(new ArrayList<>(List.of("ROLE_USER")))
                    .build();

            // 로컬 관리자
            UserEntity adminUser = UserEntity.builder()
                    .provider("local")
                    .username("admin")
                    .password("admin1234") // 실제로는 암호화 필요
                    .email("admin@dollcatch.com")
                    .nickname("돌캐치관리자")
                    .roles(new ArrayList<>(List.of("ROLE_ADMIN", "ROLE_USER")))
                    .build();

            userRepository.saveAll(Arrays.asList(kakaoUser, googleUser, adminUser));
            log.info("User 테스트 데이터 3개 추가 완료");
        }

        private void initializeDollShops() {
            log.info("DollShop 데이터 추가 중...");

            // 가게데이터 폴더 경로 (프로젝트 루트 기준)
            String basePath = "가게데이터";
            log.info("데이터 폴더 경로: {}", new File(basePath).getAbsolutePath());

            String[] jsonFiles = {
                    "서울.json", "부산.json", "대구.json", "인천.json", "광주.json",
                    "대전.json", "울산.json", "세종특별자치시.json", "경기도.json",
                    "강원특별쟈치도.json", "충청북도.json", "충청남도.json",
                    "전북특별자치도.json", "전라남도.json", "경상북도.json",
                    "경상남도.json", "제주특별자치도.json"
            };

            int totalCount = 0;
            int successCount = 0;
            int failCount = 0;
            List<DollShop> allShops = new ArrayList<>();

            for (String fileName : jsonFiles) {
                try {
                    File file = new File(basePath + File.separator + fileName);
                    log.info("파일 읽기 시도: {}", file.getAbsolutePath());

                    if (!file.exists()) {
                        log.warn("❌ 파일을 찾을 수 없습니다: {}", fileName);
                        failCount++;
                        continue;
                    }

                    List<Map<String, Object>> jsonData = objectMapper.readValue(
                            file,
                            objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class)
                    );

                    log.info("✅ {} 파일 읽기 완료: {}개의 데이터", fileName, jsonData.size());

                    for (Map<String, Object> data : jsonData) {
                        try {
                            DollShop shop = convertToDollShop(data);
                            allShops.add(shop);
                            successCount++;
                        } catch (Exception e) {
                            log.error("❌ 데이터 변환 실패: {}, 에러: {}", data.get("businessName"), e.getMessage());
                            failCount++;
                        }
                    }

                    totalCount += jsonData.size();

                } catch (IOException e) {
                    log.error("❌ 파일 읽기 실패: {}, 에러: {}", fileName, e.getMessage());
                    failCount++;
                }
            }

            // 배치로 저장
            if (!allShops.isEmpty()) {
                log.info("DB 저장 시작: {}개의 DollShop 데이터", allShops.size());
                dollShopRepository.saveAll(allShops);
                log.info("✅ DB 저장 완료!");
                log.info("===== DollShop 데이터 통계 =====");
                log.info("총 읽은 데이터: {}개", totalCount);
                log.info("성공: {}개", successCount);
                log.info("실패: {}개", failCount);
                log.info("DB 저장: {}개", allShops.size());
            } else {
                log.warn("⚠️ 저장할 DollShop 데이터가 없습니다!");
            }
        }

        private DollShop convertToDollShop(Map<String, Object> data) {
            try {
                String address = (String) data.get("address");
                if (address == null || address.trim().isEmpty()) {
                    throw new IllegalArgumentException("주소가 없습니다");
                }

                String[] addressParts = parseAddress(address);

                Long id = data.get("id") != null ? ((Number) data.get("id")).longValue() : null;
                String businessName = (String) data.get("businessName");
                Double longitude = data.get("longitude") != null ? ((Number) data.get("longitude")).doubleValue() : 0.0;
                Double latitude = data.get("latitude") != null ? ((Number) data.get("latitude")).doubleValue() : 0.0;
                Integer totalGameMachines = data.get("totalGameMachines") != null ? ((Number) data.get("totalGameMachines")).intValue() : 0;
                String phone = (String) data.get("phone");
                Boolean isOperating = data.get("isOperating") != null ? (Boolean) data.get("isOperating") : true;
                String approvalDateStr = (String) data.get("approvalDate");
                LocalDate approvalDate = approvalDateStr != null ? LocalDate.parse(approvalDateStr) : LocalDate.now();

                return DollShop.builder()
                        .id(id)
                        .businessName(businessName)
                        .longitude(longitude)
                        .latitude(latitude)
                        .address(address)
                        .totalGameMachines(totalGameMachines)
                        .phone(phone)
                        .isOperating(isOperating)
                        .approvalDate(approvalDate)
                        .gubun1(addressParts[0])
                        .gubun2(addressParts[1])
                        .build();
            } catch (Exception e) {
                log.error("❌ 데이터 변환 중 오류: {}", e.getMessage());
                throw e;
            }
        }

        /**
         * 주소에서 gubun1(시/도), gubun2(시/군/구)를 추출
         * 예: "서울특별시 강남구 테헤란로 123" -> ["서울특별시", "강남구"]
         * 예: "경기도 수원시 영통구 대학로 123" -> ["경기도", "수원시"]
         */
        private String[] parseAddress(String address) {
            if (address == null || address.trim().isEmpty()) {
                log.warn("⚠️ 주소가 비어있습니다");
                return new String[]{"", ""};
            }

            String[] parts = address.split(" ");
            String gubun1 = parts.length > 0 ? parts[0] : ""; // 서울특별시, 경기도 등
            String gubun2 = parts.length > 1 ? parts[1] : ""; // 강남구, 수원시 등

            log.debug("주소 파싱: {} -> gubun1={}, gubun2={}", address, gubun1, gubun2);

            return new String[]{gubun1, gubun2};
        }
    }
}
