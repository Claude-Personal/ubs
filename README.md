<div align="center">

<img src="https://raw.githubusercontent.com/kimdzhekhon/Flutter-Optimization-Build-Script/main/assets/icon.png" width="100" alt="Build Script Logo" onerror="this.style.display='none'"/>

# Flutter Optimization Build Script

Flutter 프로덕션 빌드 자동화 Bash 스크립트 — AAB · IPA · 난독화 · .env 주입

![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash)

![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=flat-square&logo=apple)
![Flutter](https://img.shields.io/badge/Flutter-지원-54C5F8?style=flat-square&logo=flutter)
![Android](https://img.shields.io/badge/Android-AAB-3DDC84?style=flat-square&logo=android)
![iOS](https://img.shields.io/badge/iOS-IPA-000000?style=flat-square&logo=apple)

[시작하기](#설치-및-실행) · [사용법](#데이터-흐름--사용법) · [기여하기](https://github.com/kimdzhekhon/Flutter-Optimization-Build-Script/issues)

</div>

---

## 목차

1. [소개](#소개)
2. [주요 기능](#주요-기능)
3. [기술 스택](#기술-스택)
4. [아키텍처](#아키텍처)
5. [데이터 흐름 / 사용법](#데이터-흐름--사용법)
6. [설치 및 실행](#설치-및-실행)
7. [빌드 & 배포](#빌드--배포)
8. [Roadmap](#roadmap)
9. [라이선스](#라이선스)

---

## 소개

Flutter Optimization Build Script는 Flutter 앱의 프로덕션 빌드 전 과정을 하나의 Bash 스크립트로 자동화합니다. Android AAB와 iOS IPA 빌드를 버전 자동 증가, 코드 난독화, 트리 쉐이킹, AOT 컴파일, `.env` 파일 주입과 함께 실행하며, 빌드 완료 시 macOS 시스템 알림을 전송합니다. 반복적이고 오류 발생 가능성 높은 수동 빌드 과정을 대화형 메뉴 하나로 단순화합니다.

> **"버전 증가부터 난독화, .env 주입까지 — Flutter 프로덕션 빌드의 모든 단계를 한 번에."**

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 버전 자동 증가 | Build Number / Patch / Minor / Major 4단계 선택 증가 |
| Android AAB 빌드 | `--obfuscate --split-debug-info --tree-shake-icons` 적용 릴리스 번들 |
| iOS IPA 빌드 | ExportOptions.plist 기반 자동 아카이브 및 IPA 내보내기 |
| .env 자동 주입 | `.env` 파일을 `--dart-define`으로 자동 변환하여 빌드에 주입 |
| 코드 난독화 | Dart 코드 난독화 및 디버그 심볼 분리 저장 |
| 트리 쉐이킹 | 미사용 아이콘 자동 제거로 앱 용량 최소화 |
| macOS 알림 | 빌드 완료/실패 시 시스템 알림 전송 |

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 기술 스택

| 레이어 | 기술 | 역할 |
|--------|------|------|
| 스크립트 | Bash | 빌드 자동화 전체 흐름 제어 |
| 빌드 도구 | Flutter CLI | AAB / IPA 빌드 명령 실행 |
| Android 빌드 | Gradle + flutter build appbundle | 릴리스 AAB 생성 |
| iOS 빌드 | Xcode + xcodebuild | 아카이브 및 IPA 내보내기 |
| 환경 변수 | .env → dart-define | 빌드 타임 환경 변수 주입 |
| 알림 | macOS osascript | 빌드 완료 시스템 알림 |

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 아키텍처

```
Flutter-Optimization-Build-Script/
├── build.sh                  # 메인 빌드 스크립트
├── ExportOptions.plist       # iOS IPA 내보내기 설정
├── .env.example              # 환경 변수 템플릿
└── README.md
```

**핵심 패턴**
- 대화형 메뉴로 버전 증가 방식 선택 후 `pubspec.yaml` 자동 패치
- `.env` 파일을 파싱하여 `--dart-define=KEY=VALUE` 형태로 자동 변환
- Android/iOS 빌드를 순차 실행하며 각 단계 실패 시 즉시 중단 및 알림

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 데이터 흐름 / 사용법

```
스크립트 실행 → 버전 증가 방식 선택 → pubspec.yaml 패치 → .env 파싱
     ↓
Android 빌드 (--obfuscate --split-debug-info --tree-shake-icons)
     ↓
iOS 빌드 (xcodebuild archive → xcodebuild -exportArchive)
     ↓
결과물 저장 → macOS 알림 전송
```

```bash
chmod +x build.sh
./build.sh
# 대화형 메뉴에서 버전 증가 방식 선택 (1: Build / 2: Patch / 3: Minor / 4: Major)
# 자동 빌드 시작
```

**빌드 결과물 경로**
- Android AAB: `build/app/outputs/bundle/release/`
- iOS IPA: `build/ios/ipa/`

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 설치 및 실행

**요구 사항**
- macOS (iOS 빌드 시)
- Flutter SDK 설치 및 PATH 설정
- Xcode (iOS 빌드 시)
- `.env` 파일 (선택 사항)

```bash
# 저장소 클론
git clone https://github.com/kimdzhekhon/Flutter-Optimization-Build-Script.git

# 실행 권한 부여
chmod +x build.sh

# .env 파일 설정 (선택 사항)
cp .env.example .env
# .env 파일에 환경 변수 입력

# 빌드 스크립트 실행
./build.sh
```

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 빌드 & 배포

스크립트가 빌드 및 배포 자동화를 담당합니다. 완성된 결과물은 아래 경로에 저장됩니다.

```bash
# Android AAB 경로
build/app/outputs/bundle/release/app-release.aab

# iOS IPA 경로
build/ios/ipa/*.ipa

# 난독화 디버그 심볼 경로
build/app/outputs/symbols/
```

Google Play Console 또는 App Store Connect에 결과물을 직접 업로드하여 배포하십시오.

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## Roadmap

- [x] 버전 자동 증가 (Build / Patch / Minor / Major)
- [x] Android AAB 빌드 (난독화 + 트리쉐이킹)
- [x] iOS IPA 빌드
- [x] 코드 난독화 및 디버그 심볼 분리
- [x] Tree-shaking 아이콘 최적화
- [x] .env → dart-define 자동 주입
- [x] macOS 빌드 완료 알림
- [ ] 빌드 시간 측정 및 리포트
- [ ] Slack / Discord 웹훅 알림
- [ ] CI/CD (GitHub Actions) 연동 가이드
- [ ] 멀티 환경 (dev / staging / prod) 지원

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 라이선스

MIT License — Copyright © 2024-2026 kimdzhekhon

이 소프트웨어는 MIT 라이선스 하에 자유롭게 사용, 복사, 수정, 배포할 수 있습니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하십시오.

<div align="right"><a href="#목차">↑ 맨 위로</a></div>
