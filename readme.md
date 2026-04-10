# 🚀 Flutter Optimization Build Script

Flutter 애플리케이션의 보안 강화, 성능 최적화 및 배포 자동화를 위한 전문적인 빌드 스크립트를 입니다.

---

## 🛠 주요 최적화 기술 (Optimization Features)
상용 배포 시 사용자 경험을 극대화하기 위해 다음과 같은 기술이 적용됩니다.

| 구분 | 기술 | 상세 내용 |
| :--- | :--- | :--- |
| **보안** | **Code Obfuscation** | Dart 코드를 난독화하여 로직 분석 및 역컴파일 방지 |
| **성능** | **AOT Compilation** | Ahead-Of-Time 컴파일을 통한 안정적인 FPS 유지 |
| **용량** | **Tree Shaking** | 미사용 아이콘 및 리소스 제거 (폰트 용량 99% 이상 절감) |
| **표준** | **Android App Bundle** | Google Play 권장 포맷(AAB)으로 기기별 맞춤 용량 제공 |

---

## 📋 실행 가이드 (Usage)
프로젝트 루트 디렉토리에서 아래 명령어를 실행하여 빌드를 시작할 수 있습니다.

### 1. 권한 부여 (최초 1회)
스크립트 파일에 실행 권한을 부여합니다.
```bash
chmod +x scripts/build.sh
```

### 2. 빌드 실행
환경 정비부터 Android/iOS 빌드까지 자동으로 진행됩니다.
```bash
./scripts/build.sh
```

---

## ⚠️ 주의사항 (Prerequisites)
* **Android:** 빌드 전 `android/key.properties` 파일에 사이닝 키 정보가 설정되어 있어야 합니다.
* **iOS:** Xcode 내에서 유효한 **Development Team** 및 **Bundle ID** 설정이 필수입니다.
* **심볼 파일 백업:** 난독화된 빌드의 크래시 분석을 위해 `build/app/outputs/symbols` 디렉토리에 생성된 심볼 파일을 배포 버전별로 반드시 백업하십시오.

---

## 📂 프로젝트 구조
```text
.
├── scripts
    └── build.sh  # 최적화 빌드 자동화 스크립트
