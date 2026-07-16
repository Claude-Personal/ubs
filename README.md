<div align="center">

# Universal Build Script

프로젝트 타입(Flutter / Tauri)을 자동 감지해서 알맞은 프로덕션 빌드를 실행하는 Bash 스크립트 모음 — AAB · IPA · macOS .pkg · 난독화 · .env 주입

![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash)

![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=flat-square&logo=apple)
![Flutter](https://img.shields.io/badge/Flutter-지원-54C5F8?style=flat-square&logo=flutter)
![Tauri](https://img.shields.io/badge/Tauri-2.0-FFC131?style=flat-square&logo=tauri)
![Android](https://img.shields.io/badge/Android-AAB-3DDC84?style=flat-square&logo=android)
![iOS](https://img.shields.io/badge/iOS-IPA-000000?style=flat-square&logo=apple)

[시작하기](#설치-및-실행) · [자동 감지](#자동-감지) · [기여하기](https://github.com/kimdzhekhon/Universal-Build-Script/issues)

</div>

---

## 목차

1. [소개](#소개)
2. [자동 감지](#자동-감지)
3. [주요 기능](#주요-기능)
4. [아키텍처](#아키텍처)
5. [설치 및 실행](#설치-및-실행)
6. [Flutter 빌드](#flutter-빌드)
7. [Tauri macOS 빌드](#tauri-macos-빌드)
8. [Flutter vs Tauri: 난독화/env/압축 비교](#flutter-vs-tauri-난독화env압축-비교)
9. [Roadmap](#roadmap)
10. [라이선스](#라이선스)

---

## 소개

Universal Build Script는 프로젝트 루트에서 `bash build.sh` 하나만 실행하면, 프로젝트 타입을 스스로 감지해 Flutter(Android AAB/iOS IPA) 또는 Tauri(macOS .pkg) 빌드 파이프라인 중 알맞은 쪽으로 넘겨주는 디스패처 + 각 플랫폼별 빌드 스크립트 모음입니다. 버전 자동 증가, 코드 난독화, `.env` 주입, 코드사이닝, 완료 알림까지 반복적이고 실수하기 쉬운 수동 빌드 과정을 대화형 메뉴 하나로 단순화합니다.

> **"프로젝트가 뭔지는 스크립트가 알아서 판단한다 — `bash build.sh` 하나로 끝."**

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 자동 감지

`build.sh`는 실행 시 현재 디렉토리를 보고 다음 순서로 판단합니다.

| 감지 기준 | 판단 | 실행되는 스크립트 |
|---|---|---|
| `pubspec.yaml` 존재 | Flutter 프로젝트 | `scripts/build-flutter.sh` |
| `src-tauri/tauri.conf.json` 존재 | Tauri 2.0 프로젝트 | `scripts/build-tauri-macos.sh` |
| 둘 다 없음 | 감지 실패 | 에러 메시지 후 종료 |

파일 확장자나 문법(Dart AST, Rust 문법 등)을 직접 파싱하지는 않습니다 — 각 생태계가 이미 표준으로 갖고 있는 매니페스트 파일(`pubspec.yaml`, `tauri.conf.json`) 존재 여부로 판단하는 방식이라, 오탐 없이 가볍고 빠릅니다.

```bash
bash build.sh   # 프로젝트 종류 상관없이 이 명령 하나로 통일
```

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 주요 기능

| 기능 | Flutter | Tauri(macOS) |
|------|:---:|:---:|
| 버전 자동 증가 (Patch/Minor/Major) | ✅ | ✅ |
| 대화형 취소 | ✅ | ✅ |
| 릴리스 빌드 자동화 | ✅ AAB + IPA | ✅ .app → .pkg |
| 코드 난독화 | ✅ `--obfuscate` (Dart AOT) | ⚙️ 옵션 (`javascript-obfuscator`) |
| .env 자동 주입 | ✅ `--dart-define-from-file` | ✅ Vite 기본 내장 (`VITE_*`) |
| 코드사이닝 | ✅ Xcode 자동 서명 | ✅ codesign + productbuild |
| 트리 쉐이킹 | ✅ 아이콘 트리쉐이킹 | ✅ Vite 번들 트리쉐이킹(기본) |
| 완료 알림 + 소요시간 | ✅ | ✅ |
| 스크립트 자가 업데이트 | ✅ | ✅ |
| 프로젝트 자동 감지 | ✅ (`build.sh` 디스패처 공통) | ✅ |

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 아키텍처

```
Universal-Build-Script/
├── build.sh                         # 자동 감지 디스패처 (프로젝트 루트에서 실행)
├── install.sh                       # 원라인 설치 스크립트 (타입 자동 감지 설치)
├── scripts/
│   ├── build-flutter.sh             # Flutter 빌드 (AAB + IPA)
│   ├── build-tauri-macos.sh         # Tauri macOS 빌드 + 서명 + .pkg
│   ├── FLUTTER_VERSION              # build-flutter.sh 자가 업데이트 버전
│   └── TAURI_VERSION                # build-tauri-macos.sh 자가 업데이트 버전
├── ios/
│   └── ExportOptions.plist          # iOS IPA 내보내기 설정 (Flutter 설치 시 생성)
├── .env.example                     # Flutter 환경 변수 템플릿
├── .env.macos.example               # Tauri macOS 서명 identity 템플릿
└── README.md
```

**핵심 패턴**
- `build.sh`는 매니페스트 파일 유무만으로 타입을 감지해 `exec`로 해당 스크립트에 그대로 넘김 (프로세스 대체, 서브셸 오버헤드 없음)
- 각 빌드 스크립트는 독립 실행도 가능 (`bash scripts/build-tauri-macos.sh` 직접 호출)
- 각 스크립트는 실행 시 GitHub의 자기 버전 파일(`FLUTTER_VERSION`/`TAURI_VERSION`)을 확인해 최신 버전이면 자동으로 받아 교체 후 재실행

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 설치 및 실행

프로젝트 루트(Flutter는 `pubspec.yaml`이 있는 곳, Tauri는 `src-tauri/`가 있는 곳)에서 아래 명령 한 줄로 설치합니다. 프로젝트 타입을 자동 감지해서 필요한 파일만 받아옵니다.

```bash
curl -fsSL https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main/install.sh | bash
```

설치 후 빌드는 항상 동일한 명령입니다.

```bash
bash build.sh
```

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## Flutter 빌드

**요구 사항**
- macOS (iOS 빌드 시)
- Flutter SDK 설치 및 PATH 설정
- Xcode (iOS 빌드 시)
- `.env` 파일 (선택 사항)

**동작 순서**: Build Number/Patch/Minor/Major 버전 선택 → `pubspec.yaml` 자동 패치 → 플랫폼(Android/iOS/둘 다) 선택 → `.env`를 `--dart-define-from-file`로 주입 → `--obfuscate --split-debug-info --tree-shake-icons` 릴리스 빌드 → 완료 알림 + 결과 폴더 열기.

**빌드 결과물 경로**
- Android AAB: `build/app/outputs/bundle/release/app-release.aab`
- iOS IPA: `build/ios/ipa/*.ipa`
- 디버그 심볼: `build/app/outputs/symbols/`

Google Play Console 또는 App Store Connect에 결과물을 직접 업로드하여 배포하십시오.

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## Tauri macOS 빌드

Rust/Tauri 2.0 데스크톱 앱(예: 메뉴바 앱)을 App Store Connect 제출용 `.pkg`로 빌드·서명하는 스크립트입니다. `npm run tauri build` → codesign(Apple Distribution) → `productbuild`(3rd Party Mac Developer Installer) 까지 한 번에 처리합니다.

**요구 사항**
- Tauri 2.0 프로젝트 (`src-tauri/tauri.conf.json` 존재)
- Apple Distribution 인증서 + 3rd Party Mac Developer Installer 인증서 (Keychain)
- macOS용 Provisioning Profile — `signing/*.provisionprofile`
- Entitlements 파일 — `signing/*.entitlements`

`.env.macos` 예시:

```bash
TAURI_SIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)"
TAURI_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)"
```

**동작 순서**: Patch/Minor/Major 버전 선택 → `tauri.conf.json` 자동 패치 → (`TAURI_OBFUSCATE_JS=true`면 JS 난독화 단계 추가) → `npm run tauri build` → provisioning profile 삽입 + codesign → `productbuild`로 `signing/build/<앱이름>.pkg` 생성 → Finder로 결과 폴더 열기 + macOS 알림.

결과물(`.pkg`)은 Transporter 앱으로 App Store Connect에 업로드하면 됩니다.

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## Flutter vs Tauri: 난독화/env/압축 비교

Flutter의 `--obfuscate`, `--dart-define-from-file` 과 완전히 동일한 개념이 Tauri에도 있는지 자주 묻는 질문이라 정리합니다.

**난독화**
- Flutter는 Dart 코드가 AOT로 네이티브 바이너리로 컴파일되고, `--obfuscate`가 심볼 이름까지 랜덤화합니다.
- Tauri는 Rust(`src-tauri/`)와 프런트엔드(JS/TS, `src/`) 두 부분으로 나뉩니다.
  - **Rust**: 이미 네이티브 컴파일 바이너리라 소스가 노출되지 않습니다. `Cargo.toml`에 `[profile.release] strip = true` 를 추가하면 디버그 심볼까지 제거되어 더 작아지고 리버싱이 더 어려워집니다 (이 리포는 자동으로 건드리지 않음 — 프로젝트마다 직접 추가 권장).
  - **프런트엔드**: Vite가 기본으로 minify(변수명 축약)는 하지만 진짜 난독화(제어 흐름 변형, 문자열 암호화)는 아닙니다. `TAURI_OBFUSCATE_JS=true` 로 실행하면 `javascript-obfuscator`가 `dist/`를 한 번 더 난독화한 뒤, `tauri build --config`로 `beforeBuildCommand`를 비워서 그 결과가 덮어써지지 않게 하고 빌드합니다.

**.env 주입**
- Flutter는 `--dart-define-from-file`로 명시적으로 넘겨야 합니다.
- Tauri 프런트엔드는 Vite 빌드라서 `.env`/`.env.production`을 별도 플래그 없이 자동으로 읽어 `VITE_` 접두사 붙은 값을 `import.meta.env.VITE_*`로 주입합니다 — 이미 기본 내장 기능이라 스크립트가 따로 할 일은 없고, 감지해서 안내만 합니다.

**압축**
- Flutter는 AAB(이미 압축 포맷)와 IPA(zip 기반)를 생성합니다.
- Tauri macOS는 `.dmg`/`.pkg` 모두 이미 압축된 배포 포맷이라 별도 압축 단계가 필요 없습니다. 바이너리 크기를 더 줄이고 싶으면 `Cargo.toml`의 `strip = true`, `lto = true`, `opt-level = "z"` 조합을 권장합니다 (프로젝트별 트레이드오프라 리포에서 강제하지 않음).

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## Roadmap

- [x] 버전 자동 증가 (Build / Patch / Minor / Major)
- [x] 대화형 취소
- [x] Android AAB 빌드 (난독화 + 트리쉐이킹)
- [x] iOS IPA 빌드
- [x] .env → dart-define 자동 주입
- [x] macOS 빌드 완료 알림
- [x] 빌드 시간 측정 및 리포트
- [x] Android/iOS 동시 빌드 옵션
- [x] 스크립트 자가 업데이트
- [x] Tauri 2.0 macOS 빌드 + 서명 + .pkg 패키징 스크립트
- [x] 프로젝트 타입 자동 감지 디스패처 (`build.sh`)
- [x] Tauri 프런트엔드 JS 난독화 옵션
- [ ] Tauri Windows/Linux 빌드 지원
- [ ] 프로젝트 타입 자동 감지에 Xcode-only(iOS 네이티브), Android 네이티브 프로젝트 추가

<div align="right"><a href="#목차">↑ 맨 위로</a></div>

---

## 라이선스

MIT License — Copyright © 2024-2026 kimdzhekhon

이 소프트웨어는 MIT 라이선스 하에 자유롭게 사용, 복사, 수정, 배포할 수 있습니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하십시오.

<div align="right"><a href="#목차">↑ 맨 위로</a></div>
