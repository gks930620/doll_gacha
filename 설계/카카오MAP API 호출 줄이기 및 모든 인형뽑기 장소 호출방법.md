# 카카오MAP API 호출 줄이기 및 모든 인형뽑기 장소 호출방법

## 📋 개요

현재 방식은 사용자가 지도를 요청할 때마다 카카오맵 API를 실시간으로 호출하여 인형뽑기방 데이터를 가져옵니다.
이를 **자체 DB에 저장하는 방식**으로 전환하여 API 호출을 줄이고, 개수 제한 없이 모든 데이터를 표시할 수 있도록 개선합니다.

---

## 🔄 현재 방식 vs 개선 방식

### 현재 방식 (Real-time API Call)

```
사용자 요청 → 카카오맵 API 호출 (실시간) → 결과 반환 → 지도 표시
```

**문제점:**
- ❌ 페이지 로드 시 10~20초 대기
- ❌ 사용자마다 매번 API 호출 (비효율)
- ❌ 카카오 API 제한으로 최대 45개/지역만 검색 가능
- ❌ 전체 2,368개 중 일부만 표시 가능
- ❌ API 호출 제한에 걸릴 위험

### 개선 방식 (DB Cache)

```
[배치 작업 (1일/1주)]
카카오맵 API 호출 → 모든 데이터 수집 → DB 저장

[사용자 요청]
사용자 요청 → 자체 서버 DB 조회 → 결과 반환 → 지도 표시 (1~2초)
```

**장점:**
- ✅ **즉시 로딩** (1~2초 이내)
- ✅ **모든 데이터 표시** (2,368개 전체)
- ✅ 카카오 API 호출 최소화
- ✅ 커스텀 필터/정렬 가능
- ✅ 추가 정보 저장 가능 (리뷰, 평점 등)

**단점:**
- ⚠️ 카카오맵 변경사항 즉시 반영 안 됨 → 1일/1주 단위 업데이트

---

## 🗄️ DB 설계

### 테이블: `arcade` (인형뽑기방)

```sql
CREATE TABLE arcade (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kakao_place_id VARCHAR(50) UNIQUE NOT NULL COMMENT '카카오 Place ID',
    place_name VARCHAR(200) NOT NULL COMMENT '가게명',
    category_name VARCHAR(100) COMMENT '카테고리',
    address_name VARCHAR(300) COMMENT '지번 주소',
    road_address_name VARCHAR(300) COMMENT '도로명 주소',
    phone VARCHAR(20) COMMENT '전화번호',
    place_url VARCHAR(500) COMMENT '카카오맵 URL',
    latitude DECIMAL(10, 8) NOT NULL COMMENT '위도',
    longitude DECIMAL(11, 8) NOT NULL COMMENT '경도',
    sido VARCHAR(50) COMMENT '시도 (서울특별시, 부산광역시 등)',
    sigungu VARCHAR(50) COMMENT '시군구 (강남구, 해운대구 등)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_synced_at TIMESTAMP COMMENT '마지막 카카오 API 동기화 시간',
    is_active BOOLEAN DEFAULT TRUE COMMENT '영업 중 여부',
    INDEX idx_sido (sido),
    INDEX idx_location (latitude, longitude),
    INDEX idx_kakao_place_id (kakao_place_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 🔧 구현 단계

### 1단계: Entity 및 Repository 생성

#### ArcadeEntity.java

```java
@Entity
@Table(name = "arcade")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Arcade {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "kakao_place_id", unique = true, nullable = false)
    private String kakaoPlaceId;

    @Column(name = "place_name", nullable = false)
    private String placeName;

    @Column(name = "category_name")
    private String categoryName;

    @Column(name = "address_name")
    private String addressName;

    @Column(name = "road_address_name")
    private String roadAddressName;

    @Column(name = "phone")
    private String phone;

    @Column(name = "place_url")
    private String placeUrl;

    @Column(name = "latitude", nullable = false)
    private Double latitude;

    @Column(name = "longitude", nullable = false)
    private Double longitude;

    @Column(name = "sido")
    private String sido;

    @Column(name = "sigungu")
    private String sigungu;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "last_synced_at")
    private LocalDateTime lastSyncedAt;

    @Column(name = "is_active")
    private Boolean isActive = true;
}
```

#### ArcadeRepository.java

```java
@Repository
public interface ArcadeRepository extends JpaRepository<Arcade, Long> {
    
    // 시도별 조회
    List<Arcade> findBySido(String sido);
    
    // 활성화된 가게만 조회
    List<Arcade> findByIsActiveTrue();
    
    // 시도별 활성화된 가게 조회
    List<Arcade> findBySidoAndIsActiveTrue(String sido);
    
    // 시도 + 시군구별 활성화된 가게 조회
    List<Arcade> findBySidoAndSigunguAndIsActiveTrue(String sido, String sigungu);
    
    // 카카오 Place ID로 조회 (중복 체크)
    Optional<Arcade> findByKakaoPlaceId(String kakaoPlaceId);
    
    // 특정 범위 내 가게 조회 (위도/경도 범위)
    @Query("SELECT a FROM Arcade a WHERE a.isActive = true " +
           "AND a.latitude BETWEEN :minLat AND :maxLat " +
           "AND a.longitude BETWEEN :minLng AND :maxLng")
    List<Arcade> findByLocationRange(
        @Param("minLat") Double minLat,
        @Param("maxLat") Double maxLat,
        @Param("minLng") Double minLng,
        @Param("maxLng") Double maxLng
    );
}
```

---

### 2단계: 카카오맵 API 동기화 서비스

#### KakaoMapSyncService.java

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class KakaoMapSyncService {
    
    private final ArcadeRepository arcadeRepository;
    
    @Value("${kakao.api.key}")
    private String kakaoApiKey;
    
    private static final String KAKAO_API_URL = "https://dapi.kakao.com/v2/local/search/keyword.json";
    
    /**
     * 전국 인형뽑기방 데이터 동기화
     */
    public void syncAllArcades() {
        log.info("🔄 전국 인형뽑기방 데이터 동기화 시작");
        
        List<RegionSearchPoint> searchPoints = getSearchPoints();
        int totalFound = 0;
        int newAdded = 0;
        int updated = 0;
        
        for (RegionSearchPoint point : searchPoints) {
            try {
                List<KakaoPlace> places = searchKakaoPlaces(point);
                
                for (KakaoPlace place : places) {
                    Optional<Arcade> existing = arcadeRepository.findByKakaoPlaceId(place.getId());
                    
                    if (existing.isPresent()) {
                        // 기존 데이터 업데이트
                        Arcade arcade = existing.get();
                        updateArcadeFromKakaoPlace(arcade, place);
                        arcadeRepository.save(arcade);
                        updated++;
                    } else {
                        // 새 데이터 추가
                        Arcade arcade = convertToArcade(place);
                        arcadeRepository.save(arcade);
                        newAdded++;
                    }
                    totalFound++;
                }
                
                // API 호출 제한 방지 (100ms 대기)
                Thread.sleep(100);
                
            } catch (Exception e) {
                log.error("❌ 지역 {} 검색 실패: {}", point.getName(), e.getMessage());
            }
        }
        
        log.info("✅ 동기화 완료 - 총: {}개, 신규: {}개, 업데이트: {}개", 
                 totalFound, newAdded, updated);
    }
    
    /**
     * 카카오맵 API 호출하여 인형뽑기방 검색
     */
    private List<KakaoPlace> searchKakaoPlaces(RegionSearchPoint point) {
        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "KakaoAK " + kakaoApiKey);
        
        List<KakaoPlace> allPlaces = new ArrayList<>();
        
        // 페이지네이션 (최대 3페이지, 45개)
        for (int page = 1; page <= 3; page++) {
            String url = String.format(
                "%s?query=인형뽑기&x=%f&y=%f&radius=10000&page=%d&size=15",
                KAKAO_API_URL, point.getLng(), point.getLat(), page
            );
            
            HttpEntity<String> entity = new HttpEntity<>(headers);
            ResponseEntity<KakaoSearchResponse> response = 
                restTemplate.exchange(url, HttpMethod.GET, entity, KakaoSearchResponse.class);
            
            if (response.getBody() != null && response.getBody().getDocuments() != null) {
                allPlaces.addAll(response.getBody().getDocuments());
                
                // 마지막 페이지면 중단
                if (!response.getBody().getMeta().getIsEnd()) {
                    break;
                }
            }
        }
        
        return allPlaces;
    }
    
    /**
     * 카카오 Place 데이터를 Arcade Entity로 변환
     */
    private Arcade convertToArcade(KakaoPlace place) {
        Arcade arcade = new Arcade();
        arcade.setKakaoPlaceId(place.getId());
        arcade.setPlaceName(place.getPlaceName());
        arcade.setCategoryName(place.getCategoryName());
        arcade.setAddressName(place.getAddressName());
        arcade.setRoadAddressName(place.getRoadAddressName());
        arcade.setPhone(place.getPhone());
        arcade.setPlaceUrl(place.getPlaceUrl());
        arcade.setLatitude(Double.parseDouble(place.getY()));
        arcade.setLongitude(Double.parseDouble(place.getX()));
        arcade.setSido(extractSido(place.getAddressName()));
        arcade.setLastSyncedAt(LocalDateTime.now());
        arcade.setIsActive(true);
        return arcade;
    }
    
    /**
     * 주소에서 시도 추출
     */
    private String extractSido(String address) {
        if (address == null) return null;
        String[] parts = address.split(" ");
        return parts.length > 0 ? parts[0] : null;
    }
    
    /**
     * 검색할 지역 좌표 목록
     */
    private List<RegionSearchPoint> getSearchPoints() {
        // 여기에 map.html의 regionSearchPoints와 동일한 데이터 사용
        // 또는 DB에 별도로 관리
        return Arrays.asList(
            new RegionSearchPoint("서울-강남1", 37.4979, 127.0276),
            new RegionSearchPoint("서울-강남2", 37.5172, 127.0473),
            // ... 나머지 지점들
        );
    }
}

// DTO 클래스들
@Data
class RegionSearchPoint {
    private String name;
    private Double lat;
    private Double lng;
}

@Data
class KakaoSearchResponse {
    private List<KakaoPlace> documents;
    private KakaoMeta meta;
}

@Data
class KakaoPlace {
    private String id;
    private String place_name;
    private String category_name;
    private String address_name;
    private String road_address_name;
    private String phone;
    private String place_url;
    private String x; // 경도
    private String y; // 위도
}

@Data
class KakaoMeta {
    private Boolean is_end;
    private Integer total_count;
}
```

---

### 3단계: 스케줄러 설정 (자동 동기화)

#### SchedulerConfig.java

```java
@Configuration
@EnableScheduling
public class SchedulerConfig {
}
```

#### ArcadeSyncScheduler.java

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class ArcadeSyncScheduler {
    
    private final KakaoMapSyncService kakaoMapSyncService;
    
    /**
     * 매일 새벽 3시에 자동 동기화
     */
    @Scheduled(cron = "0 0 3 * * *")
    public void scheduleDailySync() {
        log.info("⏰ 일일 자동 동기화 시작");
        kakaoMapSyncService.syncAllArcades();
    }
    
    /**
     * 매주 일요일 새벽 3시에 전체 동기화 (선택적)
     */
    @Scheduled(cron = "0 0 3 * * SUN")
    public void scheduleWeeklySync() {
        log.info("⏰ 주간 전체 동기화 시작");
        kakaoMapSyncService.syncAllArcades();
    }
}
```

**Cron 표현식 설명:**
- `0 0 3 * * *`: 매일 새벽 3시
- `0 0 3 * * SUN`: 매주 일요일 새벽 3시

---

### 4단계: REST API 구현

#### ArcadeController.java

```java
@RestController
@RequestMapping("/api/arcades")
@RequiredArgsConstructor
public class ArcadeController {
    
    private final ArcadeService arcadeService;
    
    /**
     * 전체 인형뽑기방 조회
     */
    @GetMapping
    public ResponseEntity<List<ArcadeDto>> getAllArcades() {
        List<ArcadeDto> arcades = arcadeService.getAllActiveArcades();
        return ResponseEntity.ok(arcades);
    }
    
    /**
     * 시도별 인형뽑기방 조회
     */
    @GetMapping("/sido/{sido}")
    public ResponseEntity<List<ArcadeDto>> getArcadesBySido(@PathVariable String sido) {
        List<ArcadeDto> arcades = arcadeService.getArcadesBySido(sido);
        return ResponseEntity.ok(arcades);
    }
    
    /**
     * 시도 + 시군구별 인형뽑기방 조회
     */
    @GetMapping("/sido/{sido}/sigungu/{sigungu}")
    public ResponseEntity<List<ArcadeDto>> getArcadesBySidoAndSigungu(
        @PathVariable String sido,
        @PathVariable String sigungu
    ) {
        List<ArcadeDto> arcades = arcadeService.getArcadesBySidoAndSigungu(sido, sigungu);
        return ResponseEntity.ok(arcades);
    }
    
    /**
     * 지도 범위 내 인형뽑기방 조회 (지도 이동 시)
     */
    @GetMapping("/bounds")
    public ResponseEntity<List<ArcadeDto>> getArcadesByBounds(
        @RequestParam Double minLat,
        @RequestParam Double maxLat,
        @RequestParam Double minLng,
        @RequestParam Double maxLng
    ) {
        List<ArcadeDto> arcades = arcadeService.getArcadesByLocationRange(
            minLat, maxLat, minLng, maxLng
        );
        return ResponseEntity.ok(arcades);
    }
    
    /**
     * 수동 동기화 트리거 (관리자용)
     */
    @PostMapping("/sync")
    public ResponseEntity<String> triggerSync() {
        // TODO: 관리자 권한 체크 필요
        arcadeService.syncFromKakao();
        return ResponseEntity.ok("동기화 시작됨");
    }
}
```

#### ArcadeService.java

```java
@Service
@RequiredArgsConstructor
public class ArcadeService {
    
    private final ArcadeRepository arcadeRepository;
    private final KakaoMapSyncService kakaoMapSyncService;
    
    public List<ArcadeDto> getAllActiveArcades() {
        return arcadeRepository.findByIsActiveTrue()
            .stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<ArcadeDto> getArcadesBySido(String sido) {
        return arcadeRepository.findBySidoAndIsActiveTrue(sido)
            .stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<ArcadeDto> getArcadesBySidoAndSigungu(String sido, String sigungu) {
        return arcadeRepository.findBySidoAndSigunguAndIsActiveTrue(sido, sigungu)
            .stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<ArcadeDto> getArcadesByLocationRange(
        Double minLat, Double maxLat, Double minLng, Double maxLng
    ) {
        return arcadeRepository.findByLocationRange(minLat, maxLat, minLng, maxLng)
            .stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public void syncFromKakao() {
        kakaoMapSyncService.syncAllArcades();
    }
    
    private ArcadeDto convertToDto(Arcade arcade) {
        return ArcadeDto.builder()
            .id(arcade.getId())
            .kakaoPlaceId(arcade.getKakaoPlaceId())
            .placeName(arcade.getPlaceName())
            .categoryName(arcade.getCategoryName())
            .addressName(arcade.getAddressName())
            .roadAddressName(arcade.getRoadAddressName())
            .phone(arcade.getPhone())
            .placeUrl(arcade.getPlaceUrl())
            .latitude(arcade.getLatitude())
            .longitude(arcade.getLongitude())
            .sido(arcade.getSido())
            .build();
    }
}
```

#### ArcadeDto.java

```java
@Data
@Builder
public class ArcadeDto {
    private Long id;
    private String kakaoPlaceId;
    private String placeName;
    private String categoryName;
    private String addressName;
    private String roadAddressName;
    private String phone;
    private String placeUrl;
    private Double latitude;
    private Double longitude;
    private String sido;
}
```

---

### 5단계: 프론트엔드 수정 (map.html)

```javascript
// 기존: 카카오맵 API 직접 호출
// 변경: 자체 서버 API 호출

// 인형뽑기 가게 검색 (지역별)
async function searchDollCatcherShops(region) {
    currentRegion = region;
    document.getElementById('shopCount').textContent = `${region} 인형뽑기방 조회 중...`;

    // 기존 마커 제거
    clusterer.clear();
    markers = [];
    allShops = [];

    try {
        // 자체 서버 API 호출
        const response = await fetch(`/api/arcades/sido/${encodeURIComponent(region)}`);
        
        if (!response.ok) {
            throw new Error('서버 응답 실패');
        }
        
        const arcades = await response.json();
        
        // 지도 중심 이동
        const center = regionCenters[region];
        if (center) {
            map.setCenter(new kakao.maps.LatLng(center.lat, center.lng));
            map.setLevel(center.level);
        }
        
        // 마커 생성
        arcades.forEach(arcade => {
            allShops.push(arcade);
            
            const position = new kakao.maps.LatLng(arcade.latitude, arcade.longitude);
            const marker = new kakao.maps.Marker({
                position: position,
                title: arcade.placeName
            });
            
            // 마커 클릭 이벤트
            kakao.maps.event.addListener(marker, 'click', function() {
                displayArcadeInfo(arcade, marker);
            });
            
            markers.push(marker);
        });
        
        // 클러스터에 마커 추가
        clusterer.addMarkers(markers);
        
        // 카운트 업데이트
        updateShopCount();
        
        console.log(`✅ ${region} 조회 완료: ${arcades.length}개`);
        
    } catch (error) {
        console.error('❌ 데이터 조회 실패:', error);
        document.getElementById('shopCount').textContent = '데이터 조회 실패';
    }
}

// 장소 정보 표시
function displayArcadeInfo(arcade, marker) {
    const content = `
        <div class="custom-infowindow">
            <div class="infowindow-header">
                <div>
                    <div class="infowindow-title">${arcade.placeName}</div>
                    <div class="infowindow-rating" style="color: #757575; font-size: 13px;">
                        ${arcade.categoryName || ''}
                    </div>
                </div>
                <button class="infowindow-close" onclick="closeInfowindow()">
                    <span class="material-icons">close</span>
                </button>
            </div>
            <div class="infowindow-body">
                <p>
                    <span class="material-icons">location_on</span>
                    ${arcade.addressName || arcade.roadAddressName}
                </p>
                ${arcade.phone ? `
                <p>
                    <span class="material-icons">phone</span>
                    ${arcade.phone}
                </p>
                ` : ''}
            </div>
            <div class="infowindow-footer">
                <button class="infowindow-btn infowindow-btn-primary" onclick="openKakaoPlace('${arcade.placeUrl}')">
                    <span class="material-icons">info</span>
                    상세보기
                </button>
                <button class="infowindow-btn infowindow-btn-secondary" onclick="getDirections(${arcade.latitude}, ${arcade.longitude})">
                    <span class="material-icons">directions</span>
                    길찾기
                </button>
            </div>
        </div>
    `;

    infowindow.setContent(content);
    infowindow.open(map, marker);
}
```

---

## 📝 application.yml 설정

```yaml
kakao:
  api:
    key: 719ae502dd3351fab0a5fa57689ef5cd

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/doll_gacha?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
    username: root
    password: your_password
    driver-class-name: com.mysql.cj.jdbc.Driver
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        dialect: org.hibernate.dialect.MySQL8Dialect
```

---

## 🚀 배포 및 실행 순서

### 1. 초기 데이터 수집

```bash
# 애플리케이션 실행
./gradlew bootRun

# 수동 동기화 API 호출 (첫 실행 시)
curl -X POST http://localhost:8080/api/arcades/sync
```

### 2. 자동 동기화 확인

- 매일 새벽 3시에 자동으로 카카오맵 API 호출하여 DB 업데이트
- 로그 확인: `log.info("🔄 전국 인형뽑기방 데이터 동기화 시작")`

### 3. 프론트엔드 테스트

- `/map` 접속
- 지역 선택 시 즉시 로딩 확인 (1~2초)
- 모든 데이터 표시 확인

---

## 📊 기대 효과

| 항목 | 현재 방식 | 개선 방식 | 개선율 |
|------|----------|----------|--------|
| **로딩 속도** | 10~20초 | 1~2초 | **90% 개선** |
| **표시 가능 개수** | ~500개 (제한적) | 2,368개 (전체) | **400% 증가** |
| **카카오 API 호출** | 사용자마다 | 1일 1회 | **99% 감소** |
| **사용자 경험** | 느림 😞 | 빠름 😊 | ⭐⭐⭐⭐⭐ |

---

## ⚠️ 주의사항

1. **카카오 API 키 보안**
   - application.yml에 있는 API 키는 환경변수로 관리
   - `.gitignore`에 추가하여 커밋 방지

2. **데이터 동기화 시간**
   - 새벽 3시 배치 작업이 부담되면 주 1회로 조정 가능
   - Cron: `0 0 3 * * SUN` (일요일 새벽 3시)

3. **DB 백업**
   - 정기적으로 arcade 테이블 백업
   - 동기화 실패 시 롤백 가능하도록

4. **API 제한**
   - 카카오맵 API는 하루 30만 건 제한
   - 90개 지점 × 45개 × 1일 1회 = 약 4,050건 (여유 있음)

---

## 🎯 다음 단계 (추가 개선)

1. **리뷰 기능 추가**
   - `arcade_review` 테이블 추가
   - 사용자 평점 및 후기

2. **즐겨찾기 기능**
   - `user_favorite` 테이블 추가
   - 사용자별 즐겨찾는 인형뽑기방

3. **통계 및 순위**
   - 인기 인형뽑기방 TOP 10
   - 지역별 인형뽑기방 수

4. **관리자 페이지**
   - 수동 동기화 버튼
   - 동기화 로그 확인
   - 개별 가게 활성화/비활성화

---

## 📚 참고 자료


- [카카오맵 API 문서](https://developers.kakao.com/docs/latest/ko/local/dev-guide)
- [Spring Batch 스케줄링](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#scheduling)
- [JPA Best Practices](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)

---

**작성일:** 2025-01-19  
**버전:** 1.0  
**작성자:** AI Assistant

