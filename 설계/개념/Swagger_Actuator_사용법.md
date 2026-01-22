# Swagger & Actuator 사용법
## 📘 Swagger (API 문서화)
### 접속 방법
```
http://localhost:8080/swagger-ui.html
```


### 주요 기능
| 기능 | 설명 |
|------|------|
| API 목록 보기 | 모든 API 엔드포인트 자동 문서화 |
| API 테스트 | 브라우저에서 바로 API 호출 테스트 |
| 요청/응답 예시 | 파라미터, 응답 형식 확인 |
| 인증 설정 | JWT 토큰 설정 후 인증 필요 API 테스트 |

### 사용법
#### 1. API 확인
- 브라우저에서 `http://localhost:8080/swagger-ui.html` 접속
- 컨트롤러별로 API가 그룹화되어 표시됨
- 각 API 클릭하면 상세 정보 확인 가능


#### 2. API 테스트 (공개 API)
1. 테스트할 API 클릭
2. "Try it out" 버튼 클릭
3. 필요한 파라미터 입력
4. "Execute" 버튼 클릭
5. 응답 확인

#### 3. 인증 필요 API 테스트
1. 먼저 로그인 API (`/api/login`) 호출하여 토큰 획득
2. 우측 상단 "Authorize" 버튼 클릭
3. `Bearer {access_token}` 형식으로 입력
4. 이후 인증 필요 API 테스트 가능

### 컨트롤러에 설명 추가 (선택)
```java
@Tag(name = "커뮤니티", description = "게시글 CRUD API")
@RestController
@RequestMapping("/api/community")
public class CommunityController {

    @Operation(summary = "게시글 목록 조회", description = "페이징 처리된 게시글 목록을 조회합니다")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<CommunityDTO>>> getList(...) {
        ...
    }
}
```

---

## 📊 Actuator (서버 모니터링)
### 접속 방법
```
http://localhost:8080/actuator
```

### 주요 엔드포인트

| 엔드포인트 | URL | 설명 |
|-----------|-----|------|
| **health** | `/actuator/health` | 서버 상태 (UP/DOWN) |
| **info** | `/actuator/info` | 앱 정보 |
| **metrics** | `/actuator/metrics` | 메트릭 목록 |
| **loggers** | `/actuator/loggers` | 로그 레벨 확인/변경 |

### 사용 예시

#### 1. 서버 상태 확인 (가장 많이 사용) ⭐
```bash
curl http://localhost:8080/actuator/health
```
응답:
```json
{"status":"UP"}
```

#### 2. 메모리 사용량 확인
```bash
curl http://localhost:8080/actuator/metrics/jvm.memory.used
```

#### 3. HTTP 요청 통계
```bash
curl http://localhost:8080/actuator/metrics/http.server.requests
```

#### 4. 런타임 로그 레벨 변경
```bash
# 현재 로그 레벨 확인
curl http://localhost:8080/actuator/loggers/com.doll.gacha

# DEBUG로 변경
curl -X POST http://localhost:8080/actuator/loggers/com.doll.gacha \
  -H "Content-Type: application/json" \
  -d '{"configuredLevel": "DEBUG"}'
```

### 실제 활용 시나리오

| 시나리오 | 사용 방법 |
|---------|----------|
| **배포 후 헬스체크** | 로드밸런서가 `/actuator/health` 체크 |
| **장애 발생 시** | 메트릭 확인하여 원인 분석 |
| **디버깅** | 런타임에 로그 레벨 변경 |
| **모니터링 대시보드** | Prometheus + Grafana와 연동 |

### 보안 설정 (운영 환경)

```yaml
# application-prod.yml
management:
  endpoints:
    web:
      exposure:
        include: health, info  # 필요한 것만 노출
  endpoint:
    health:
      show-details: never  # 상세 정보 숨김
```

---

## 💡 요약
| 도구 | 용도 | 필수 여부 |
|------|------|----------|
| **Swagger** | API 문서화, 테스트 | 개발 시 매우 유용 |
| **Actuator** | 서버 상태 모니터링 | 배포 시 필수 (헬스체크) |
- **Swagger**: 개발/테스트할 때 API 확인하고 테스트하는 용도
- **Actuator**: 배포 후 서버가 살아있는지 체크하는 용도 (`/actuator/health`)

