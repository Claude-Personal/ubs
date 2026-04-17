<div align="center">

# ⚡ Flutter Optimization Build Script

**Flutter 프로덕션 최적화 빌드 자동화 스크립트** — Android AAB + iOS IPA를 한 번에 빌드하는 완전 자동화 Bash 스크립트

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android_AAB-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS_IPA-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)

</div>

---

## 🌟 개요

Flutter 앱을 프로덕션 배포 수준으로 최적화하여 Android AAB와 iOS IPA를 동시에 빌드하는 자동화 스크립트입니다. 버전 자동 증가, 코드 난독화, Tree-shaking, AOT 컴파일까지 한 번에 처리합니다.

## 🛠 기술 스택 / 주요 기능

| 기능 | 설명 |
|------|------|
| **버전 자동 증가** | Build Number / Patch / Minor / Major 선택형 자동 bump |
| **Android 빌드** | `--obfuscate --split-debug-info` 포함 AAB 생성 |
| **iOS 빌드** | ExportOptions.plist 기반 IPA 생성 |
| **Tree-shaking** | `--tree-shake-icons` 미사용 아이콘 제거 |
| **AOT 컴파일** | 릴리즈 모드 Ahead-Of-Time 네이티브 컴파일 |
| **알림** | macOS 시스템 알림으로 빌드 완료 감지 |
| **환경 변수** | `.env` 파일 기반 Dart define 자동 주입 |

## 📋 사용법

```bash
# 스크립트 권한 부여
chmod +x build.sh

# 실행
./build.sh
```

실행 후 버전 증가 방식을 선택하면:
1. `pubspec.yaml` 버전 자동 업데이트
2. Android AAB 빌드 (`build/app/outputs/bundle/release/`)
3. iOS IPA 빌드 (`build/ios/ipa/`)

## 🔍 핵심 기술 상세

### 버전 자동 관리
`pubspec.yaml`의 `version: X.Y.Z+N` 형식을 파싱하여 선택한 레벨만 증가시키고 파일을 자동 수정합니다.

### 코드 난독화 (Android)
```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --tree-shake-icons
```
`split-debug-info`로 심볼 파일을 분리하여 역난독화 가능한 디버그 심볼을 보관합니다.

### iOS ExportOptions
`ios/ExportOptions.plist`를 참조하여 배포 방식(App Store / Ad Hoc)을 자동 선택합니다.