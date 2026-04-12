# 🚀 Flutter Optimization Build Script

Flutter 애플리케이션의 보안 강화, 성능 최적화 및 배포 자동화를 위한 전문적인 빌드 스크립트입니다.

---

## 🛠 주요 최적화 기술 (Optimization Features)

상용 배포 시 사용자 경험을 극대화하기 위해 다음과 같은 기술이 적용됩니다.

| 구분 | 기술 | 상세 내용 |
| :--- | :--- | :--- |
| **보안** | **Code Obfuscation** | Dart 코드를 난독화하여 로직 분석 및 역컴파일 방지 |
| **성능** | **AOT Compilation** | Ahead-Of-Time 컴파일을 통한 안정적인 FPS 유지 |
| **용량** | **Tree Shaking** | 미사용 아이콘 및 리소스 제거 (폰트 용량 **99.4% 절감**, 1.6MB → 9KB) |
| **표준** | **Android App Bundle** | Google Play 권장 포맷(AAB)으로 기기별 맞춤 용량 제공 |
| **자동화** | **Auto Version Bump** | 빌드 전 Major / Minor / Patch / Build Number 선택 업데이트 |
| **알림** | **Build Notification** | 빌드 완료 시 사운드, 음성, 시스템 알림 + 출력 폴더 자동 열기 |

---

## 📋 실행 가이드 (Usage)

### Step 1. 권한 부여 (최초 1회)

```bash
chmod +x scripts/build.sh
```

### Step 2. 빌드 실행

```bash
./scripts/build.sh
```

### Step 3. 버전 선택 (빌드 시작 전 자동 프롬프트)

스크립트 실행 시 현재 버전을 자동으로 읽고, 업데이트 방식을 선택할 수 있습니다.

```
📦 현재 버전: 1.2.3+4
어떤 버전을 올릴까요?
  1) Build Number만 올리기  → 1.2.3+5
  2) Patch 버전 올리기      → 1.2.4+5
  3) Minor 버전 올리기      → 1.3.0+5
  4) Major 버전 올리기      → 2.0.0+5
  5) 버전 유지
선택 (1-5):
```

---

## ✅ 빌드 결과 (Output)

빌드 성공 시 아래 경로에 배포용 파일이 생성됩니다.

| 플랫폼 | 포맷 | 출력 경로 |
| :--- | :--- | :--- |
| **Android** | `.aab` | `build/app/outputs/bundle/release/app-release.aab` |
| **iOS** | `.app` | `build/ios/iphoneos/Runner.app` |
| **Android 심볼** | `.symbols` | `build/app/outputs/symbols/` |
| **iOS 심볼** | `.symbols` | `build/ios/outputs/symbols/` |

빌드 완료 후 출력 폴더가 자동으로 열립니다.

| OS | 알림 방식 |
| :--- | :--- |
| **macOS** | 사운드 + 음성 + 시스템 배너 + Finder 자동 열기 |
| **Linux** | 출력 폴더 자동 열기 (`xdg-open`) |
| **Windows** | 출력 폴더 자동 열기 (Explorer) |

### 📊 실제 빌드 결과 예시

```
------------------------------------------------------------
✅ ALL BUILDS COMPLETED SUCCESSFULLY!
🏷️  Version     : 1.0.1+2
📍 Android AAB  : build/app/outputs/bundle/release/app-release.aab (47.7MB)
📍 iOS Runner   : build/ios/iphoneos/Runner.app
------------------------------------------------------------
```

### 🗜 Tree Shaking 절감 효과

| 리소스 | 원본 크기 | 최적화 후 | 절감률 |
| :--- | ---: | ---: | ---: |
| MaterialIcons-Regular.otf | 1,645,184 bytes (1.6MB) | 9,232 bytes (9KB) | **99.4%** |

> 앱에서 실제로 사용하는 아이콘만 번들에 포함되어 최종 앱 용량이 크게 줄어듭니다.

---

## ⚙️ 코드 생성 라이브러리 사용 시 (Freezed / Riverpod 등)

`build_runner`로 코드를 생성하는 패키지를 사용하는 경우, `scripts/build.sh` 내 아래 주석을 해제하세요.

```bash
# echo -e "${BLUE}⚙️ [2/4] Generating Codes (build_runner)...${NC}"
# dart run build_runner build --delete-conflicting-outputs
```

활성화하면 빌드 전 자동으로 코드 생성 단계가 실행됩니다.

---

## ⚠️ 주의사항 (Prerequisites)

* **Android:** 빌드 전 `android/key.properties` 파일에 사이닝 키 정보가 설정되어 있어야 합니다.
* **iOS:** Xcode 내에서 유효한 **Development Team** 및 **Bundle ID** 설정이 필수입니다.
* **iOS 코드 사이닝 오류:** 인증서가 없을 경우 iOS 빌드는 실패하지만, Android 빌드 및 이후 과정은 정상적으로 계속 진행됩니다.
* **심볼 파일 백업:** 난독화된 빌드의 크래시 분석을 위해 `build/app/outputs/symbols` 디렉토리에 생성된 심볼 파일을 배포 버전별로 반드시 백업하십시오.

---

## 📂 프로젝트 구조

```text
.
├── scripts
│   └── build.sh     # 최적화 빌드 자동화 스크립트
└── pubspec.yaml     # 버전 정보 자동 관리 (version: x.x.x+n)
```
