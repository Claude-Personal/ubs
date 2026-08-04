# Message catalog data for scripts/lib/i18n.sh. Sourced only from there.
#
# One variable per key per language: UBS_MSG_<ko|en|ja|zh>_<KEY>="...".
# Use %s placeholders for values interpolated via ubs_msg's printf-args.
# Keep ANSI color codes and emoji OUT of these strings — call sites wrap them.

# --- build.sh / bootstrap-update.sh / build-node.sh / build-gradle.sh / build-rust-helper.sh / lib/node-package-manager.sh ---

UBS_MSG_ko_BUILD_NEED_PYTHON3="ERROR: Universal Build Script에는 Python 3가 필요합니다."
UBS_MSG_en_BUILD_NEED_PYTHON3="ERROR: Universal Build Script requires Python 3."
UBS_MSG_ja_BUILD_NEED_PYTHON3="ERROR: Universal Build Script には Python 3 が必要です。"
UBS_MSG_zh_BUILD_NEED_PYTHON3="ERROR: Universal Build Script 需要 Python 3。"

UBS_MSG_ko_BUILD_CORE_NOT_FOUND="ERROR: Python 코어를 찾을 수 없습니다: %s"
UBS_MSG_en_BUILD_CORE_NOT_FOUND="ERROR: Python core not found: %s"
UBS_MSG_ja_BUILD_CORE_NOT_FOUND="ERROR: Python コアが見つかりません: %s"
UBS_MSG_zh_BUILD_CORE_NOT_FOUND="ERROR: 找不到 Python 核心: %s"

UBS_MSG_ko_BUILD_REINSTALL_HINT="설치기를 다시 실행하여 관리 런타임을 복구하세요."
UBS_MSG_en_BUILD_REINSTALL_HINT="Re-run the installer to repair the managed runtime."
UBS_MSG_ja_BUILD_REINSTALL_HINT="インストーラーを再実行して管理ランタイムを復旧してください。"
UBS_MSG_zh_BUILD_REINSTALL_HINT="请重新运行安装程序以修复受管运行时。"

UBS_MSG_ko_BOOTSTRAP_UPDATE_LIB_NOT_FOUND="업데이트 모듈을 찾을 수 없습니다: %s"
UBS_MSG_en_BOOTSTRAP_UPDATE_LIB_NOT_FOUND="Update module not found: %s"
UBS_MSG_ja_BOOTSTRAP_UPDATE_LIB_NOT_FOUND="更新モジュールが見つかりません: %s"
UBS_MSG_zh_BOOTSTRAP_UPDATE_LIB_NOT_FOUND="找不到更新模块: %s"

UBS_MSG_ko_BOOTSTRAP_PRUNE_DAYS_REQUIRED="--prune-backups 일수가 필요합니다."
UBS_MSG_en_BOOTSTRAP_PRUNE_DAYS_REQUIRED="--prune-backups requires a day count."
UBS_MSG_ja_BOOTSTRAP_PRUNE_DAYS_REQUIRED="--prune-backups には日数の指定が必要です。"
UBS_MSG_zh_BOOTSTRAP_PRUNE_DAYS_REQUIRED="--prune-backups 需要天数参数。"

UBS_MSG_ko_BOOTSTRAP_UPDATE_UNSUPPORTED_ARG="update에서 지원하지 않는 옵션 또는 인자입니다: %s"
UBS_MSG_en_BOOTSTRAP_UPDATE_UNSUPPORTED_ARG="Unsupported option or argument for update: %s"
UBS_MSG_ja_BOOTSTRAP_UPDATE_UNSUPPORTED_ARG="update でサポートされていないオプションまたは引数です: %s"
UBS_MSG_zh_BOOTSTRAP_UPDATE_UNSUPPORTED_ARG="update 不支持的选项或参数: %s"

UBS_MSG_ko_BOOTSTRAP_PRUNE_NEEDS_CHECK_OR_DRYRUN="--prune-backups는 --check/--dry-run과 함께 사용할 수 없습니다."
UBS_MSG_en_BOOTSTRAP_PRUNE_NEEDS_CHECK_OR_DRYRUN="--prune-backups cannot be used together with --check/--dry-run."
UBS_MSG_ja_BOOTSTRAP_PRUNE_NEEDS_CHECK_OR_DRYRUN="--prune-backups は --check/--dry-run と併用できません。"
UBS_MSG_zh_BOOTSTRAP_PRUNE_NEEDS_CHECK_OR_DRYRUN="--prune-backups 不能与 --check/--dry-run 同时使用。"

UBS_MSG_ko_ADAPTER_CORE_NOT_FOUND="Python core를 찾을 수 없습니다: %s"
UBS_MSG_en_ADAPTER_CORE_NOT_FOUND="Python core not found: %s"
UBS_MSG_ja_ADAPTER_CORE_NOT_FOUND="Python core が見つかりません: %s"
UBS_MSG_zh_ADAPTER_CORE_NOT_FOUND="找不到 Python core: %s"

UBS_MSG_ko_RUST_HELPER_NEED_CARGO="Rust helper 빌드에는 cargo가 필요합니다."
UBS_MSG_en_RUST_HELPER_NEED_CARGO="Building the Rust helper requires cargo."
UBS_MSG_ja_RUST_HELPER_NEED_CARGO="Rust helper のビルドには cargo が必要です。"
UBS_MSG_zh_RUST_HELPER_NEED_CARGO="构建 Rust helper 需要 cargo。"

UBS_MSG_ko_RUST_HELPER_SYMLINK_PATH="Rust helper 경로가 심볼릭 링크입니다: %s"
UBS_MSG_en_RUST_HELPER_SYMLINK_PATH="Rust helper path is a symlink: %s"
UBS_MSG_ja_RUST_HELPER_SYMLINK_PATH="Rust helper のパスがシンボリックリンクです: %s"
UBS_MSG_zh_RUST_HELPER_SYMLINK_PATH="Rust helper 路径是符号链接: %s"

UBS_MSG_ko_RUST_HELPER_HOST_TARGET_UNKNOWN="Rust host target을 확인할 수 없습니다."
UBS_MSG_en_RUST_HELPER_HOST_TARGET_UNKNOWN="Unable to determine the Rust host target."
UBS_MSG_ja_RUST_HELPER_HOST_TARGET_UNKNOWN="Rust host target を確認できません。"
UBS_MSG_zh_RUST_HELPER_HOST_TARGET_UNKNOWN="无法确定 Rust host target。"

UBS_MSG_ko_RUST_HELPER_ARTIFACT_NOT_FOUND="Rust helper 산출물을 찾을 수 없습니다: %s"
UBS_MSG_en_RUST_HELPER_ARTIFACT_NOT_FOUND="Rust helper build artifact not found: %s"
UBS_MSG_ja_RUST_HELPER_ARTIFACT_NOT_FOUND="Rust helper のビルド成果物が見つかりません: %s"
UBS_MSG_zh_RUST_HELPER_ARTIFACT_NOT_FOUND="找不到 Rust helper 构建产物: %s"

UBS_MSG_ko_RUST_HELPER_INSTALL_DONE="Rust helper 설치 완료: %s"
UBS_MSG_en_RUST_HELPER_INSTALL_DONE="Rust helper installed: %s"
UBS_MSG_ja_RUST_HELPER_INSTALL_DONE="Rust helper のインストールが完了しました: %s"
UBS_MSG_zh_RUST_HELPER_INSTALL_DONE="Rust helper 安装完成: %s"

UBS_MSG_ko_NODE_PM_REQUIRED="%s 패키지 매니저가 필요합니다."
UBS_MSG_en_NODE_PM_REQUIRED="The %s package manager is required."
UBS_MSG_ja_NODE_PM_REQUIRED="%s パッケージマネージャーが必要です。"
UBS_MSG_zh_NODE_PM_REQUIRED="需要 %s 包管理器。"

UBS_MSG_ko_NODE_PM_SKIP_INSTALL="의존성 입력이 변경되지 않아 %s install을 생략합니다."
UBS_MSG_en_NODE_PM_SKIP_INSTALL="Dependency inputs unchanged; skipping %s install."
UBS_MSG_ja_NODE_PM_SKIP_INSTALL="依存関係の入力が変更されていないため、%s install をスキップします。"
UBS_MSG_zh_NODE_PM_SKIP_INSTALL="依赖输入未变化，跳过 %s install。"

# --- scripts/build-tauri-macos.sh ---

UBS_MSG_ko_SELF_UPDATE_DEPRECATED="UBS_ALLOW_SELF_UPDATE는 폐기됐습니다. 검증된 중앙 명령을 사용하세요: ./build.sh update"
UBS_MSG_en_SELF_UPDATE_DEPRECATED="UBS_ALLOW_SELF_UPDATE is deprecated. Use the verified central command: ./build.sh update"
UBS_MSG_ja_SELF_UPDATE_DEPRECATED="UBS_ALLOW_SELF_UPDATE は廃止されました。検証済みの中央コマンドを使用してください: ./build.sh update"
UBS_MSG_zh_SELF_UPDATE_DEPRECATED="UBS_ALLOW_SELF_UPDATE 已废弃。请使用经过验证的中央命令: ./build.sh update"

UBS_MSG_ko_TAURI_CONF_NOT_FOUND="src-tauri/tauri.conf.json 을 찾을 수 없습니다."
UBS_MSG_en_TAURI_CONF_NOT_FOUND="Cannot find src-tauri/tauri.conf.json."
UBS_MSG_ja_TAURI_CONF_NOT_FOUND="src-tauri/tauri.conf.json が見つかりません。"
UBS_MSG_zh_TAURI_CONF_NOT_FOUND="未找到 src-tauri/tauri.conf.json。"

UBS_MSG_ko_TAURI_CONF_RUN_FROM_ROOT="Tauri 프로젝트 루트에서 실행하세요."
UBS_MSG_en_TAURI_CONF_RUN_FROM_ROOT="Run this from the Tauri project root."
UBS_MSG_ja_TAURI_CONF_RUN_FROM_ROOT="Tauri プロジェクトのルートで実行してください。"
UBS_MSG_zh_TAURI_CONF_RUN_FROM_ROOT="请在 Tauri 项目根目录下运行。"

UBS_MSG_ko_PYTHON3_REQUIRED="python3 이 필요합니다."
UBS_MSG_en_PYTHON3_REQUIRED="python3 is required."
UBS_MSG_ja_PYTHON3_REQUIRED="python3 が必要です。"
UBS_MSG_zh_PYTHON3_REQUIRED="需要 python3。"

UBS_MSG_ko_APP_INFO="앱: %s  |  현재 버전: %s"
UBS_MSG_en_APP_INFO="App: %s  |  Current version: %s"
UBS_MSG_ja_APP_INFO="アプリ: %s  |  現在のバージョン: %s"
UBS_MSG_zh_APP_INFO="应用: %s  |  当前版本: %s"

UBS_MSG_ko_VERSION_RESTORED_INCOMPLETE="빌드가 완료되지 않아 버전을 %s 으로 복원했습니다."
UBS_MSG_en_VERSION_RESTORED_INCOMPLETE="Build did not complete, restored version to %s."
UBS_MSG_ja_VERSION_RESTORED_INCOMPLETE="ビルドが完了しなかったため、バージョンを %s に復元しました。"
UBS_MSG_zh_VERSION_RESTORED_INCOMPLETE="构建未完成，版本已恢复为 %s。"

UBS_MSG_ko_VERSION_BUMP_UNSUPPORTED="지원하지 않는 UBS_VERSION_BUMP 값입니다."
UBS_MSG_en_VERSION_BUMP_UNSUPPORTED="Unsupported UBS_VERSION_BUMP value."
UBS_MSG_ja_VERSION_BUMP_UNSUPPORTED="サポートされていない UBS_VERSION_BUMP の値です。"
UBS_MSG_zh_VERSION_BUMP_UNSUPPORTED="不支持的 UBS_VERSION_BUMP 值。"

UBS_MSG_ko_VERSION_POLICY_NONINTERACTIVE="비대화형 버전 정책: %s"
UBS_MSG_en_VERSION_POLICY_NONINTERACTIVE="Non-interactive version policy: %s"
UBS_MSG_ja_VERSION_POLICY_NONINTERACTIVE="非対話型バージョンポリシー: %s"
UBS_MSG_zh_VERSION_POLICY_NONINTERACTIVE="非交互式版本策略: %s"

UBS_MSG_ko_TAURI_MENU_OPT_PATCH_BUMP="1) Patch 버전 올리기"
UBS_MSG_en_TAURI_MENU_OPT_PATCH_BUMP="1) Bump patch version"
UBS_MSG_ja_TAURI_MENU_OPT_PATCH_BUMP="1) パッチバージョンを上げる"
UBS_MSG_zh_TAURI_MENU_OPT_PATCH_BUMP="1) 升级补丁版本"

UBS_MSG_ko_TAURI_MENU_OPT_MINOR_BUMP="2) Minor 버전 올리기"
UBS_MSG_en_TAURI_MENU_OPT_MINOR_BUMP="2) Bump minor version"
UBS_MSG_ja_TAURI_MENU_OPT_MINOR_BUMP="2) マイナーバージョンを上げる"
UBS_MSG_zh_TAURI_MENU_OPT_MINOR_BUMP="2) 升级次要版本"

UBS_MSG_ko_TAURI_MENU_OPT_MAJOR_BUMP="3) Major 버전 올리기"
UBS_MSG_en_TAURI_MENU_OPT_MAJOR_BUMP="3) Bump major version"
UBS_MSG_ja_TAURI_MENU_OPT_MAJOR_BUMP="3) メジャーバージョンを上げる"
UBS_MSG_zh_TAURI_MENU_OPT_MAJOR_BUMP="3) 升级主要版本"

UBS_MSG_ko_MENU_OPT_KEEP_VERSION="4) 버전 유지"
UBS_MSG_en_MENU_OPT_KEEP_VERSION="4) Keep current version"
UBS_MSG_ja_MENU_OPT_KEEP_VERSION="4) バージョンを維持"
UBS_MSG_zh_MENU_OPT_KEEP_VERSION="4) 保持版本不变"

UBS_MSG_ko_MENU_OPT_CANCEL="5) 취소"
UBS_MSG_en_MENU_OPT_CANCEL="5) Cancel"
UBS_MSG_ja_MENU_OPT_CANCEL="5) キャンセル"
UBS_MSG_zh_MENU_OPT_CANCEL="5) 取消"

UBS_MSG_ko_VERSION_KEPT="버전 유지: %s"
UBS_MSG_en_VERSION_KEPT="Version kept: %s"
UBS_MSG_ja_VERSION_KEPT="バージョンを維持: %s"
UBS_MSG_zh_VERSION_KEPT="版本保持不变: %s"

UBS_MSG_ko_VERSION_INVALID_CHOICE="잘못된 선택입니다. 버전을 유지합니다."
UBS_MSG_en_VERSION_INVALID_CHOICE="Invalid choice. Keeping the current version."
UBS_MSG_ja_VERSION_INVALID_CHOICE="無効な選択です。バージョンを維持します。"
UBS_MSG_zh_VERSION_INVALID_CHOICE="选择无效。保持当前版本。"

UBS_MSG_ko_PKG_MODE_AUTO_NON_MACOS="%s에서는 Tauri 기본 번들을 생성합니다. Apple .pkg 서명은 macOS 전용입니다."
UBS_MSG_en_PKG_MODE_AUTO_NON_MACOS="On %s, only the default Tauri bundle is created. Apple .pkg signing is macOS-only."
UBS_MSG_ja_PKG_MODE_AUTO_NON_MACOS="%s では Tauri のデフォルトバンドルのみ生成します。Apple .pkg 署名は macOS 専用です。"
UBS_MSG_zh_PKG_MODE_AUTO_NON_MACOS="在 %s 上仅生成 Tauri 默认捆绑包。Apple .pkg 签名仅支持 macOS。"

UBS_MSG_ko_PKG_MODE_AUTO_SIGNING_INCOMPLETE="Apple 서명 설정이 불완전하여 기본 Tauri .app 빌드만 생성합니다."
UBS_MSG_en_PKG_MODE_AUTO_SIGNING_INCOMPLETE="Apple signing configuration is incomplete, so only the default Tauri .app build is created."
UBS_MSG_ja_PKG_MODE_AUTO_SIGNING_INCOMPLETE="Apple 署名設定が不完全なため、デフォルトの Tauri .app ビルドのみ生成します。"
UBS_MSG_zh_PKG_MODE_AUTO_SIGNING_INCOMPLETE="Apple 签名配置不完整，仅生成默认的 Tauri .app 构建。"

UBS_MSG_ko_PKG_MODE_SIGNED_MACOS_ONLY="signed 모드의 Apple .pkg 생성은 macOS에서만 지원합니다."
UBS_MSG_en_PKG_MODE_SIGNED_MACOS_ONLY="Apple .pkg creation in signed mode is only supported on macOS."
UBS_MSG_ja_PKG_MODE_SIGNED_MACOS_ONLY="signed モードでの Apple .pkg 生成は macOS でのみサポートされます。"
UBS_MSG_zh_PKG_MODE_SIGNED_MACOS_ONLY="signed 模式下的 Apple .pkg 生成仅支持 macOS。"

UBS_MSG_ko_PKG_MODE_SIGNED_REQUIREMENTS="signed 모드에는 서명 identity, provisioning profile, entitlements가 모두 필요합니다."
UBS_MSG_en_PKG_MODE_SIGNED_REQUIREMENTS="signed mode requires a signing identity, provisioning profile, and entitlements — all of them."
UBS_MSG_ja_PKG_MODE_SIGNED_REQUIREMENTS="signed モードには署名 identity、provisioning profile、entitlements がすべて必要です。"
UBS_MSG_zh_PKG_MODE_SIGNED_REQUIREMENTS="signed 模式需要签名 identity、provisioning profile 和 entitlements，三者缺一不可。"

UBS_MSG_ko_PKG_MODE_INVALID="UBS_TAURI_PACKAGE_MODE는 auto, signed, unsigned 중 하나여야 합니다."
UBS_MSG_en_PKG_MODE_INVALID="UBS_TAURI_PACKAGE_MODE must be one of auto, signed, unsigned."
UBS_MSG_ja_PKG_MODE_INVALID="UBS_TAURI_PACKAGE_MODE は auto、signed、unsigned のいずれかである必要があります。"
UBS_MSG_zh_PKG_MODE_INVALID="UBS_TAURI_PACKAGE_MODE 必须是 auto、signed、unsigned 之一。"

UBS_MSG_ko_SIGN_IDENTITY_LABEL="서명 ID: %s"
UBS_MSG_en_SIGN_IDENTITY_LABEL="Signing ID: %s"
UBS_MSG_ja_SIGN_IDENTITY_LABEL="署名 ID: %s"
UBS_MSG_zh_SIGN_IDENTITY_LABEL="签名 ID: %s"

UBS_MSG_ko_PROVISION_PROFILE_LABEL="Provisioning Profile: %s"
UBS_MSG_en_PROVISION_PROFILE_LABEL="Provisioning Profile: %s"
UBS_MSG_ja_PROVISION_PROFILE_LABEL="Provisioning Profile: %s"
UBS_MSG_zh_PROVISION_PROFILE_LABEL="Provisioning Profile: %s"

UBS_MSG_ko_FRONTEND_ENV_DETECTED="프런트엔드 .env 감지됨 — Vite가 빌드 시 자동 주입합니다."
UBS_MSG_en_FRONTEND_ENV_DETECTED="Frontend .env detected — Vite will auto-inject it during the build."
UBS_MSG_ja_FRONTEND_ENV_DETECTED="フロントエンドの .env を検出しました — Vite がビルド時に自動的に注入します。"
UBS_MSG_zh_FRONTEND_ENV_DETECTED="检测到前端 .env — Vite 会在构建时自动注入。"

UBS_MSG_ko_UNIVERSAL_BUILD_ENABLED="macOS 유니버설 바이너리(Apple Silicon + Intel)로 빌드합니다. 끄려면: TAURI_UNIVERSAL_MACOS=false"
UBS_MSG_en_UNIVERSAL_BUILD_ENABLED="Building a macOS universal binary (Apple Silicon + Intel). To disable: TAURI_UNIVERSAL_MACOS=false"
UBS_MSG_ja_UNIVERSAL_BUILD_ENABLED="macOS ユニバーサルバイナリ (Apple Silicon + Intel) でビルドします。無効にするには: TAURI_UNIVERSAL_MACOS=false"
UBS_MSG_zh_UNIVERSAL_BUILD_ENABLED="将构建 macOS 通用二进制文件 (Apple Silicon + Intel)。禁用方法: TAURI_UNIVERSAL_MACOS=false"

UBS_MSG_ko_UNIVERSAL_BUILD_NO_RUSTUP="rustup이 없어 유니버설 빌드를 건너뜁니다. 현재 아키텍처로만 빌드합니다."
UBS_MSG_en_UNIVERSAL_BUILD_NO_RUSTUP="rustup not found, skipping universal build. Building for the current architecture only."
UBS_MSG_ja_UNIVERSAL_BUILD_NO_RUSTUP="rustup が見つからないためユニバーサルビルドをスキップします。現在のアーキテクチャのみでビルドします。"
UBS_MSG_zh_UNIVERSAL_BUILD_NO_RUSTUP="未找到 rustup，跳过通用构建。仅为当前架构构建。"

UBS_MSG_ko_NODE_INSTALL_RUNNING="%s install..."
UBS_MSG_en_NODE_INSTALL_RUNNING="%s install..."
UBS_MSG_ja_NODE_INSTALL_RUNNING="%s install..."
UBS_MSG_zh_NODE_INSTALL_RUNNING="%s install..."

UBS_MSG_ko_SKIP_INSTALL_ENABLED="UBS_SKIP_INSTALL=true — 의존성 설치를 건너뜁니다."
UBS_MSG_en_SKIP_INSTALL_ENABLED="UBS_SKIP_INSTALL=true — skipping dependency installation."
UBS_MSG_ja_SKIP_INSTALL_ENABLED="UBS_SKIP_INSTALL=true — 依存関係のインストールをスキップします。"
UBS_MSG_zh_SKIP_INSTALL_ENABLED="UBS_SKIP_INSTALL=true — 跳过依赖安装。"

UBS_MSG_ko_STEP_FRONTEND_BUILD_1OF4="[1/4] 프런트엔드 빌드..."
UBS_MSG_en_STEP_FRONTEND_BUILD_1OF4="[1/4] Building frontend..."
UBS_MSG_ja_STEP_FRONTEND_BUILD_1OF4="[1/4] フロントエンドをビルド中..."
UBS_MSG_zh_STEP_FRONTEND_BUILD_1OF4="[1/4] 正在构建前端..."

UBS_MSG_ko_STEP_JS_OBFUSCATE_2OF4="[2/4] JS 난독화 (lockfile에 고정된 javascript-obfuscator)..."
UBS_MSG_en_STEP_JS_OBFUSCATE_2OF4="[2/4] Obfuscating JS (javascript-obfuscator pinned in lockfile)..."
UBS_MSG_ja_STEP_JS_OBFUSCATE_2OF4="[2/4] JS 難読化中 (lockfile に固定された javascript-obfuscator)..."
UBS_MSG_zh_STEP_JS_OBFUSCATE_2OF4="[2/4] 正在混淆 JS (lockfile 中锁定的 javascript-obfuscator)..."

UBS_MSG_ko_OBFUSCATOR_NOT_FOUND="javascript-obfuscator를 로컬 dependency에서 찾을 수 없습니다."
UBS_MSG_en_OBFUSCATOR_NOT_FOUND="Could not find javascript-obfuscator in local dependencies."
UBS_MSG_ja_OBFUSCATOR_NOT_FOUND="ローカルの dependency に javascript-obfuscator が見つかりません。"
UBS_MSG_zh_OBFUSCATOR_NOT_FOUND="在本地依赖中找不到 javascript-obfuscator。"

UBS_MSG_ko_OBFUSCATOR_PIN_HINT="devDependency와 lockfile에 고정한 뒤 다시 설치하세요."
UBS_MSG_en_OBFUSCATOR_PIN_HINT="Pin it as a devDependency and in the lockfile, then reinstall."
UBS_MSG_ja_OBFUSCATOR_PIN_HINT="devDependency と lockfile に固定してから再インストールしてください。"
UBS_MSG_zh_OBFUSCATOR_PIN_HINT="请将其固定为 devDependency 并写入 lockfile，然后重新安装。"

UBS_MSG_ko_OBFUSCATOR_RUN_FAILED="javascript-obfuscator 실행 실패 — 난독화 안 된 결과가 패키징되지 않도록 중단합니다."
UBS_MSG_en_OBFUSCATOR_RUN_FAILED="javascript-obfuscator failed — aborting so the unobfuscated output doesn't get packaged."
UBS_MSG_ja_OBFUSCATOR_RUN_FAILED="javascript-obfuscator の実行に失敗しました — 難読化されていない結果がパッケージされないよう中止します。"
UBS_MSG_zh_OBFUSCATOR_RUN_FAILED="javascript-obfuscator 执行失败 — 中止以防未混淆的结果被打包。"

UBS_MSG_ko_STEP_TAURI_BUILD_3OF4="[3/4] tauri build (프런트엔드 재빌드 스킵)..."
UBS_MSG_en_STEP_TAURI_BUILD_3OF4="[3/4] Running tauri build (skipping frontend rebuild)..."
UBS_MSG_ja_STEP_TAURI_BUILD_3OF4="[3/4] tauri build を実行中 (フロントエンド再ビルドをスキップ)..."
UBS_MSG_zh_STEP_TAURI_BUILD_3OF4="[3/4] 正在运行 tauri build (跳过前端重新构建)..."

UBS_MSG_ko_STEP_TAURI_BUILD_1OF3="[1/3] tauri build..."
UBS_MSG_en_STEP_TAURI_BUILD_1OF3="[1/3] Running tauri build..."
UBS_MSG_ja_STEP_TAURI_BUILD_1OF3="[1/3] tauri build を実行中..."
UBS_MSG_zh_STEP_TAURI_BUILD_1OF3="[1/3] 正在运行 tauri build..."

UBS_MSG_ko_JS_OBFUSCATE_DISABLED_HINT="JS 난독화는 기본 꺼져있음 — 켜려면: ./build.sh --obfuscate-js"
UBS_MSG_en_JS_OBFUSCATE_DISABLED_HINT="JS obfuscation is off by default — to enable: ./build.sh --obfuscate-js"
UBS_MSG_ja_JS_OBFUSCATE_DISABLED_HINT="JS 難読化はデフォルトで無効です — 有効にするには: ./build.sh --obfuscate-js"
UBS_MSG_zh_JS_OBFUSCATE_DISABLED_HINT="JS 混淆默认关闭 — 启用方法: ./build.sh --obfuscate-js"

UBS_MSG_ko_BUNDLE_APP_NOT_FOUND="빌드 결과 .app 을 찾을 수 없습니다: %s"
UBS_MSG_en_BUNDLE_APP_NOT_FOUND="Could not find the built .app: %s"
UBS_MSG_ja_BUNDLE_APP_NOT_FOUND="ビルド結果の .app が見つかりません: %s"
UBS_MSG_zh_BUNDLE_APP_NOT_FOUND="找不到构建产物 .app: %s"

UBS_MSG_ko_BUNDLE_ARTIFACT_NOT_FOUND="Tauri 번들 산출물을 찾을 수 없습니다: src-tauri/target/release/bundle"
UBS_MSG_en_BUNDLE_ARTIFACT_NOT_FOUND="Could not find the Tauri bundle artifact: src-tauri/target/release/bundle"
UBS_MSG_ja_BUNDLE_ARTIFACT_NOT_FOUND="Tauri バンドルの成果物が見つかりません: src-tauri/target/release/bundle"
UBS_MSG_zh_BUNDLE_ARTIFACT_NOT_FOUND="找不到 Tauri 捆绑包产物: src-tauri/target/release/bundle"

UBS_MSG_ko_CODESIGNING_START="Codesigning (Apple Distribution)..."
UBS_MSG_en_CODESIGNING_START="Codesigning (Apple Distribution)..."
UBS_MSG_ja_CODESIGNING_START="Codesigning 実行中 (Apple Distribution)..."
UBS_MSG_zh_CODESIGNING_START="正在进行 Codesigning (Apple Distribution)..."

UBS_MSG_ko_XATTR_CLEAR="Provisioning profile 및 앱 번들의 확장 속성을 제거합니다..."
UBS_MSG_en_XATTR_CLEAR="Removing extended attributes from the provisioning profile and app bundle..."
UBS_MSG_ja_XATTR_CLEAR="Provisioning profile とアプリバンドルの拡張属性を削除しています..."
UBS_MSG_zh_XATTR_CLEAR="正在移除 provisioning profile 和应用包的扩展属性..."

UBS_MSG_ko_BUILDING_SIGNED_PKG="Building signed installer package (.pkg)..."
UBS_MSG_en_BUILDING_SIGNED_PKG="Building signed installer package (.pkg)..."
UBS_MSG_ja_BUILDING_SIGNED_PKG="署名済みインストーラーパッケージ (.pkg) をビルド中..."
UBS_MSG_zh_BUILDING_SIGNED_PKG="正在构建已签名的安装包 (.pkg)..."

UBS_MSG_ko_BUILD_SUCCESS_BANNER="BUILD COMPLETED SUCCESSFULLY!"
UBS_MSG_en_BUILD_SUCCESS_BANNER="BUILD COMPLETED SUCCESSFULLY!"
UBS_MSG_ja_BUILD_SUCCESS_BANNER="ビルドが正常に完了しました!"
UBS_MSG_zh_BUILD_SUCCESS_BANNER="构建成功完成!"

UBS_MSG_ko_SUMMARY_VERSION="Version : %s"
UBS_MSG_en_SUMMARY_VERSION="Version : %s"
UBS_MSG_ja_SUMMARY_VERSION="バージョン: %s"
UBS_MSG_zh_SUMMARY_VERSION="版本: %s"

UBS_MSG_ko_SUMMARY_ARTIFACT="Artifact : %s"
UBS_MSG_en_SUMMARY_ARTIFACT="Artifact : %s"
UBS_MSG_ja_SUMMARY_ARTIFACT="アーティファクト: %s"
UBS_MSG_zh_SUMMARY_ARTIFACT="产物: %s"

UBS_MSG_ko_SUMMARY_BUILD_TIME="빌드 시간 : %s"
UBS_MSG_en_SUMMARY_BUILD_TIME="Build time : %s"
UBS_MSG_ja_SUMMARY_BUILD_TIME="ビルド時間: %s"
UBS_MSG_zh_SUMMARY_BUILD_TIME="构建时间: %s"

UBS_MSG_ko_TRANSPORTER_UPLOAD_HINT="Transporter 앱으로 %s 를 업로드하면 App Store Connect 에 반영됩니다."
UBS_MSG_en_TRANSPORTER_UPLOAD_HINT="Upload %s with the Transporter app to reflect it in App Store Connect."
UBS_MSG_ja_TRANSPORTER_UPLOAD_HINT="Transporter アプリで %s をアップロードすると App Store Connect に反映されます。"
UBS_MSG_zh_TRANSPORTER_UPLOAD_HINT="使用 Transporter 应用上传 %s，即可同步到 App Store Connect。"

# --- scripts/lib/update.sh ---

UBS_MSG_ko_UPDATE_OPENSSL_REQUIRED="manifest 서명 검증에는 openssl이 필요합니다."
UBS_MSG_en_UPDATE_OPENSSL_REQUIRED="manifest signature verification requires openssl."
UBS_MSG_ja_UPDATE_OPENSSL_REQUIRED="manifest の署名検証には openssl が必要です。"
UBS_MSG_zh_UPDATE_OPENSSL_REQUIRED="manifest 签名验证需要 openssl。"

UBS_MSG_ko_UPDATE_SIGNATURE_INVALID="manifest 서명 검증 실패 — 다운로드 채널이 침해됐을 수 있습니다."
UBS_MSG_en_UPDATE_SIGNATURE_INVALID="manifest signature verification failed — the download channel may be compromised."
UBS_MSG_ja_UPDATE_SIGNATURE_INVALID="manifest の署名検証に失敗しました — ダウンロード経路が侵害されている可能性があります。"
UBS_MSG_zh_UPDATE_SIGNATURE_INVALID="manifest 签名验证失败 —— 下载渠道可能已被攻破。"

UBS_MSG_ko_UPDATE_RETENTION_DAYS_INVALID="보존 일수는 0 이상의 정수여야 합니다: %s"
UBS_MSG_en_UPDATE_RETENTION_DAYS_INVALID="Retention days must be a non-negative integer: %s"
UBS_MSG_ja_UPDATE_RETENTION_DAYS_INVALID="保持日数は0以上の整数である必要があります: %s"
UBS_MSG_zh_UPDATE_RETENTION_DAYS_INVALID="保留天数必须是非负整数: %s"

UBS_MSG_ko_UPDATE_BACKUP_SYMLINK_SKIP="심볼릭 링크 백업 경로는 정리하지 않습니다: %s"
UBS_MSG_en_UPDATE_BACKUP_SYMLINK_SKIP="Skipping cleanup of symlinked backup path: %s"
UBS_MSG_ja_UPDATE_BACKUP_SYMLINK_SKIP="シンボリックリンクのバックアップパスは整理しません: %s"
UBS_MSG_zh_UPDATE_BACKUP_SYMLINK_SKIP="跳过对符号链接备份路径的清理: %s"

UBS_MSG_ko_UPDATE_BACKUP_PRUNED="백업 정리 완료: %s일 초과 디렉터리 %s개 삭제"
UBS_MSG_en_UPDATE_BACKUP_PRUNED="Backup cleanup complete: deleted %s director(y/ies) older than %s day(s)"
UBS_MSG_ja_UPDATE_BACKUP_PRUNED="バックアップ整理完了: %s日を超えたディレクトリを%s個削除しました"
UBS_MSG_zh_UPDATE_BACKUP_PRUNED="备份清理完成: 已删除超过 %s 天的目录 %s 个"

UBS_MSG_ko_UPDATE_SHA256_TOOL_REQUIRED="SHA-256 도구(sha256sum 또는 shasum)가 필요합니다."
UBS_MSG_en_UPDATE_SHA256_TOOL_REQUIRED="A SHA-256 tool (sha256sum or shasum) is required."
UBS_MSG_ja_UPDATE_SHA256_TOOL_REQUIRED="SHA-256ツール（sha256sumまたはshasum）が必要です。"
UBS_MSG_zh_UPDATE_SHA256_TOOL_REQUIRED="需要 SHA-256 工具（sha256sum 或 shasum）。"

UBS_MSG_ko_UPDATE_PATH_SYMLINK_SKIP="심볼릭 링크 경로는 업데이트하지 않습니다: %s"
UBS_MSG_en_UPDATE_PATH_SYMLINK_SKIP="Skipping update of symlinked path: %s"
UBS_MSG_ja_UPDATE_PATH_SYMLINK_SKIP="シンボリックリンクのパスは更新しません: %s"
UBS_MSG_zh_UPDATE_PATH_SYMLINK_SKIP="跳过对符号链接路径的更新: %s"

UBS_MSG_ko_UPDATE_RESTORE_DIR_FAILED="복원 경로 생성 실패: %s"
UBS_MSG_en_UPDATE_RESTORE_DIR_FAILED="Failed to create restore path: %s"
UBS_MSG_ja_UPDATE_RESTORE_DIR_FAILED="復元パスの作成に失敗しました: %s"
UBS_MSG_zh_UPDATE_RESTORE_DIR_FAILED="创建还原路径失败: %s"

UBS_MSG_ko_UPDATE_RESTORE_TEMP_FAILED="복원 임시 파일 생성 실패: %s"
UBS_MSG_en_UPDATE_RESTORE_TEMP_FAILED="Failed to create restore temp file: %s"
UBS_MSG_ja_UPDATE_RESTORE_TEMP_FAILED="復元用一時ファイルの作成に失敗しました: %s"
UBS_MSG_zh_UPDATE_RESTORE_TEMP_FAILED="创建还原临时文件失败: %s"

UBS_MSG_ko_UPDATE_RESTORE_FAILED="복원 실패: %s"
UBS_MSG_en_UPDATE_RESTORE_FAILED="Restore failed: %s"
UBS_MSG_ja_UPDATE_RESTORE_FAILED="復元に失敗しました: %s"
UBS_MSG_zh_UPDATE_RESTORE_FAILED="还原失败: %s"

UBS_MSG_ko_UPDATE_NEW_FILE_REMOVE_FAILED="새 파일 제거 실패: %s"
UBS_MSG_en_UPDATE_NEW_FILE_REMOVE_FAILED="Failed to remove new file: %s"
UBS_MSG_ja_UPDATE_NEW_FILE_REMOVE_FAILED="新規ファイルの削除に失敗しました: %s"
UBS_MSG_zh_UPDATE_NEW_FILE_REMOVE_FAILED="删除新文件失败: %s"

UBS_MSG_ko_UPDATE_CURL_REQUIRED="업데이트에는 curl이 필요합니다."
UBS_MSG_en_UPDATE_CURL_REQUIRED="curl is required for updates."
UBS_MSG_ja_UPDATE_CURL_REQUIRED="更新にはcurlが必要です。"
UBS_MSG_zh_UPDATE_CURL_REQUIRED="更新需要 curl。"

UBS_MSG_ko_UPDATE_FILE_SCHEME_TEST_ONLY="file:// 업데이트는 테스트 모드에서만 허용됩니다."
UBS_MSG_en_UPDATE_FILE_SCHEME_TEST_ONLY="file:// updates are only allowed in test mode."
UBS_MSG_ja_UPDATE_FILE_SCHEME_TEST_ONLY="file://による更新はテストモードでのみ許可されます。"
UBS_MSG_zh_UPDATE_FILE_SCHEME_TEST_ONLY="file:// 更新仅在测试模式下允许。"

UBS_MSG_ko_UPDATE_URL_HTTPS_REQUIRED="업데이트 URL은 HTTPS만 허용됩니다: %s"
UBS_MSG_en_UPDATE_URL_HTTPS_REQUIRED="Update URL must be HTTPS only: %s"
UBS_MSG_ja_UPDATE_URL_HTTPS_REQUIRED="更新URLはHTTPSのみ許可されます: %s"
UBS_MSG_zh_UPDATE_URL_HTTPS_REQUIRED="更新 URL 仅允许 HTTPS: %s"

UBS_MSG_ko_UPDATE_MANIFEST_FETCH_FAILED="업데이트 manifest를 가져오지 못했습니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_FETCH_FAILED="Failed to fetch update manifest: %s"
UBS_MSG_ja_UPDATE_MANIFEST_FETCH_FAILED="更新manifestの取得に失敗しました: %s"
UBS_MSG_zh_UPDATE_MANIFEST_FETCH_FAILED="获取更新 manifest 失败: %s"

UBS_MSG_ko_UPDATE_MANIFEST_SIG_FETCH_FAILED="manifest 서명 파일을 가져오지 못했습니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_SIG_FETCH_FAILED="Failed to fetch manifest signature file: %s"
UBS_MSG_ja_UPDATE_MANIFEST_SIG_FETCH_FAILED="manifestの署名ファイルの取得に失敗しました: %s"
UBS_MSG_zh_UPDATE_MANIFEST_SIG_FETCH_FAILED="获取 manifest 签名文件失败: %s"

UBS_MSG_ko_UPDATE_VERSION_ENTRY_INVALID="잘못된 version 항목입니다."
UBS_MSG_en_UPDATE_VERSION_ENTRY_INVALID="Invalid version entry."
UBS_MSG_ja_UPDATE_VERSION_ENTRY_INVALID="無効なversionエントリです。"
UBS_MSG_zh_UPDATE_VERSION_ENTRY_INVALID="无效的 version 条目。"

UBS_MSG_ko_UPDATE_MANIFEST_ENTRY_INVALID="허용되지 않거나 잘못된 manifest 항목입니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_ENTRY_INVALID="Disallowed or invalid manifest entry: %s"
UBS_MSG_ja_UPDATE_MANIFEST_ENTRY_INVALID="許可されていない、または無効なmanifestエントリです: %s"
UBS_MSG_zh_UPDATE_MANIFEST_ENTRY_INVALID="不允许或无效的 manifest 条目: %s"

UBS_MSG_ko_UPDATE_MANIFEST_PATH_DUPLICATE="중복된 manifest 경로입니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_PATH_DUPLICATE="Duplicate manifest path: %s"
UBS_MSG_ja_UPDATE_MANIFEST_PATH_DUPLICATE="manifestのパスが重複しています: %s"
UBS_MSG_zh_UPDATE_MANIFEST_PATH_DUPLICATE="重复的 manifest 路径: %s"

UBS_MSG_ko_UPDATE_MANIFEST_ENTRY_UNKNOWN="알 수 없는 manifest 항목입니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_ENTRY_UNKNOWN="Unknown manifest entry: %s"
UBS_MSG_ja_UPDATE_MANIFEST_ENTRY_UNKNOWN="不明なmanifestエントリです: %s"
UBS_MSG_zh_UPDATE_MANIFEST_ENTRY_UNKNOWN="未知的 manifest 条目: %s"

UBS_MSG_ko_UPDATE_MANIFEST_VERSION_FORMAT="manifest version은 숫자 SemVer 형식이어야 합니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_VERSION_FORMAT="manifest version must be a numeric SemVer format: %s"
UBS_MSG_ja_UPDATE_MANIFEST_VERSION_FORMAT="manifestのversionは数値のSemVer形式である必要があります: %s"
UBS_MSG_zh_UPDATE_MANIFEST_VERSION_FORMAT="manifest version 必须是数字 SemVer 格式: %s"

UBS_MSG_ko_UPDATE_MANIFEST_REQUIRED_PATH_MISSING="manifest 필수 경로가 누락됐습니다: %s"
UBS_MSG_en_UPDATE_MANIFEST_REQUIRED_PATH_MISSING="Required manifest path is missing: %s"
UBS_MSG_ja_UPDATE_MANIFEST_REQUIRED_PATH_MISSING="manifestの必須パスが欠落しています: %s"
UBS_MSG_zh_UPDATE_MANIFEST_REQUIRED_PATH_MISSING="manifest 缺少必需路径: %s"

UBS_MSG_ko_UPDATE_DOWNGRADE_BLOCKED="다운그레이드를 차단했습니다: local=%s remote=%s"
UBS_MSG_en_UPDATE_DOWNGRADE_BLOCKED="Downgrade blocked: local=%s remote=%s"
UBS_MSG_ja_UPDATE_DOWNGRADE_BLOCKED="ダウングレードをブロックしました: local=%s remote=%s"
UBS_MSG_zh_UPDATE_DOWNGRADE_BLOCKED="已阻止降级: local=%s remote=%s"

UBS_MSG_ko_UPDATE_DOWNGRADE_HINT="복원이 필요하면 .ubs/backups/를 사용하거나 UBS_UPDATE_ALLOW_DOWNGRADE=true를 명시하세요."
UBS_MSG_en_UPDATE_DOWNGRADE_HINT="If you need to restore, use .ubs/backups/ or set UBS_UPDATE_ALLOW_DOWNGRADE=true explicitly."
UBS_MSG_ja_UPDATE_DOWNGRADE_HINT="復元が必要な場合は .ubs/backups/ を使用するか、UBS_UPDATE_ALLOW_DOWNGRADE=true を明示的に指定してください。"
UBS_MSG_zh_UPDATE_DOWNGRADE_HINT="如需还原，请使用 .ubs/backups/ 或显式设置 UBS_UPDATE_ALLOW_DOWNGRADE=true。"

UBS_MSG_ko_UPDATE_RUST_HELPER_PATH_OUTSIDE="Rust helper가 manifest 밖 경로를 반환했습니다: %s"
UBS_MSG_en_UPDATE_RUST_HELPER_PATH_OUTSIDE="Rust helper returned a path outside the manifest: %s"
UBS_MSG_ja_UPDATE_RUST_HELPER_PATH_OUTSIDE="RustヘルパーがmanifestにないパスをOK返しました: %s"
UBS_MSG_zh_UPDATE_RUST_HELPER_PATH_OUTSIDE="Rust helper 返回了 manifest 之外的路径: %s"

UBS_MSG_ko_UPDATE_RUST_HELPER_PATH_DUPLICATE="Rust helper가 중복 경로를 반환했습니다: %s"
UBS_MSG_en_UPDATE_RUST_HELPER_PATH_DUPLICATE="Rust helper returned a duplicate path: %s"
UBS_MSG_ja_UPDATE_RUST_HELPER_PATH_DUPLICATE="Rustヘルパーが重複したパスを返しました: %s"
UBS_MSG_zh_UPDATE_RUST_HELPER_PATH_DUPLICATE="Rust helper 返回了重复的路径: %s"

UBS_MSG_ko_UPDATE_RUST_HELPER_BATCH_UNSUPPORTED="Rust helper가 batch manifest 명령을 지원하지 않아 portable hash fallback을 사용합니다."
UBS_MSG_en_UPDATE_RUST_HELPER_BATCH_UNSUPPORTED="Rust helper does not support the batch manifest command; using the portable hash fallback."
UBS_MSG_ja_UPDATE_RUST_HELPER_BATCH_UNSUPPORTED="Rustヘルパーがbatch manifestコマンドに対応していないため、portable hash fallbackを使用します。"
UBS_MSG_zh_UPDATE_RUST_HELPER_BATCH_UNSUPPORTED="Rust helper 不支持 batch manifest 命令，将使用可移植哈希回退方案。"

UBS_MSG_ko_UPDATE_VERSION_STATUS="Universal Build Script: local=%s remote=%s"
UBS_MSG_en_UPDATE_VERSION_STATUS="Universal Build Script: local=%s remote=%s"
UBS_MSG_ja_UPDATE_VERSION_STATUS="Universal Build Script: local=%s remote=%s"
UBS_MSG_zh_UPDATE_VERSION_STATUS="Universal Build Script: local=%s remote=%s"

UBS_MSG_ko_UPDATE_UP_TO_DATE="이미 최신 상태이며 관리 파일의 무결성도 일치합니다."
UBS_MSG_en_UPDATE_UP_TO_DATE="Already up to date, and the integrity of managed files matches."
UBS_MSG_ja_UPDATE_UP_TO_DATE="既に最新の状態であり、管理対象ファイルの整合性も一致しています。"
UBS_MSG_zh_UPDATE_UP_TO_DATE="已是最新状态，且受管理文件的完整性一致。"

UBS_MSG_ko_UPDATE_CHANGED_COUNT="변경 대상: %s개"
UBS_MSG_en_UPDATE_CHANGED_COUNT="Files to update: %s"
UBS_MSG_ja_UPDATE_CHANGED_COUNT="変更対象: %s件"
UBS_MSG_zh_UPDATE_CHANGED_COUNT="待更新文件: %s 个"

UBS_MSG_ko_UPDATE_CHECK_ONLY_DONE="확인만 수행했습니다. 적용하려면: ./build.sh update"
UBS_MSG_en_UPDATE_CHECK_ONLY_DONE="Check only was performed. To apply: ./build.sh update"
UBS_MSG_ja_UPDATE_CHECK_ONLY_DONE="確認のみ実行しました。適用するには: ./build.sh update"
UBS_MSG_zh_UPDATE_CHECK_ONLY_DONE="仅执行了检查。要应用请运行: ./build.sh update"

UBS_MSG_ko_UPDATE_DRY_RUN_SKIPPED="dry-run이므로 다운로드·백업·교체하지 않았습니다."
UBS_MSG_en_UPDATE_DRY_RUN_SKIPPED="This is a dry run, so nothing was downloaded, backed up, or replaced."
UBS_MSG_ja_UPDATE_DRY_RUN_SKIPPED="dry-runのため、ダウンロード・バックアップ・置換は行いませんでした。"
UBS_MSG_zh_UPDATE_DRY_RUN_SKIPPED="这是 dry-run，未执行下载、备份或替换。"

UBS_MSG_ko_UPDATE_BACKUP_ROOT_SYMLINK_BLOCK="심볼릭 링크 백업 경로는 사용하지 않습니다: %s"
UBS_MSG_en_UPDATE_BACKUP_ROOT_SYMLINK_BLOCK="Symlinked backup path is not used: %s"
UBS_MSG_ja_UPDATE_BACKUP_ROOT_SYMLINK_BLOCK="シンボリックリンクのバックアップパスは使用しません: %s"
UBS_MSG_zh_UPDATE_BACKUP_ROOT_SYMLINK_BLOCK="不使用符号链接备份路径: %s"

UBS_MSG_ko_UPDATE_STATE_DIR_FAILED="업데이트 상태 경로를 만들 수 없습니다."
UBS_MSG_en_UPDATE_STATE_DIR_FAILED="Failed to create the update state directory."
UBS_MSG_ja_UPDATE_STATE_DIR_FAILED="更新状態のパスを作成できませんでした。"
UBS_MSG_zh_UPDATE_STATE_DIR_FAILED="无法创建更新状态目录。"

UBS_MSG_ko_UPDATE_LOCK_HELD="다른 업데이트가 진행 중입니다: %s"
UBS_MSG_en_UPDATE_LOCK_HELD="Another update is already in progress: %s"
UBS_MSG_ja_UPDATE_LOCK_HELD="他の更新が進行中です: %s"
UBS_MSG_zh_UPDATE_LOCK_HELD="另一个更新正在进行中: %s"

UBS_MSG_ko_UPDATE_STAGE_DIR_FAILED="임시 경로 생성 실패: %s"
UBS_MSG_en_UPDATE_STAGE_DIR_FAILED="Failed to create staging path: %s"
UBS_MSG_ja_UPDATE_STAGE_DIR_FAILED="一時パスの作成に失敗しました: %s"
UBS_MSG_zh_UPDATE_STAGE_DIR_FAILED="创建暂存路径失败: %s"

UBS_MSG_ko_UPDATE_FILE_DOWNLOAD_FAILED="파일 다운로드 실패: %s"
UBS_MSG_en_UPDATE_FILE_DOWNLOAD_FAILED="File download failed: %s"
UBS_MSG_ja_UPDATE_FILE_DOWNLOAD_FAILED="ファイルのダウンロードに失敗しました: %s"
UBS_MSG_zh_UPDATE_FILE_DOWNLOAD_FAILED="文件下载失败: %s"

UBS_MSG_ko_UPDATE_SHA256_MISMATCH="SHA-256 불일치: %s"
UBS_MSG_en_UPDATE_SHA256_MISMATCH="SHA-256 mismatch: %s"
UBS_MSG_ja_UPDATE_SHA256_MISMATCH="SHA-256 が一致しません: %s"
UBS_MSG_zh_UPDATE_SHA256_MISMATCH="SHA-256 不匹配: %s"

UBS_MSG_ko_UPDATE_RUST_BATCH_VERIFY_FAILED="Rust batch manifest 검증에 실패했습니다."
UBS_MSG_en_UPDATE_RUST_BATCH_VERIFY_FAILED="Rust batch manifest verification failed."
UBS_MSG_ja_UPDATE_RUST_BATCH_VERIFY_FAILED="Rust batch manifestの検証に失敗しました。"
UBS_MSG_zh_UPDATE_RUST_BATCH_VERIFY_FAILED="Rust batch manifest 验证失败。"

UBS_MSG_ko_UPDATE_BACKUP_DIR_FAILED="백업 경로를 만들 수 없습니다: %s"
UBS_MSG_en_UPDATE_BACKUP_DIR_FAILED="Failed to create backup path: %s"
UBS_MSG_ja_UPDATE_BACKUP_DIR_FAILED="バックアップパスを作成できませんでした: %s"
UBS_MSG_zh_UPDATE_BACKUP_DIR_FAILED="无法创建备份路径: %s"

UBS_MSG_ko_UPDATE_BACKUP_PRECHECK_FAILED="백업 직전 경로 검증 실패: %s"
UBS_MSG_en_UPDATE_BACKUP_PRECHECK_FAILED="Path validation failed just before backup: %s"
UBS_MSG_ja_UPDATE_BACKUP_PRECHECK_FAILED="バックアップ直前のパス検証に失敗しました: %s"
UBS_MSG_zh_UPDATE_BACKUP_PRECHECK_FAILED="备份前的路径校验失败: %s"

UBS_MSG_ko_UPDATE_BACKUP_FAILED="백업 실패: %s"
UBS_MSG_en_UPDATE_BACKUP_FAILED="Backup failed: %s"
UBS_MSG_ja_UPDATE_BACKUP_FAILED="バックアップに失敗しました: %s"
UBS_MSG_zh_UPDATE_BACKUP_FAILED="备份失败: %s"

UBS_MSG_ko_UPDATE_REPLACE_PRECHECK_FAILED="교체 직전 경로 검증 실패: %s — 적용된 파일을 복원합니다."
UBS_MSG_en_UPDATE_REPLACE_PRECHECK_FAILED="Path validation failed just before replacement: %s — restoring applied files."
UBS_MSG_ja_UPDATE_REPLACE_PRECHECK_FAILED="置換直前のパス検証に失敗しました: %s — 適用済みファイルを復元します。"
UBS_MSG_zh_UPDATE_REPLACE_PRECHECK_FAILED="替换前的路径校验失败: %s——正在还原已应用的文件。"

UBS_MSG_ko_UPDATE_DEST_DIR_FAILED="대상 경로 생성 실패: %s — 적용된 파일을 복원합니다."
UBS_MSG_en_UPDATE_DEST_DIR_FAILED="Failed to create destination path: %s — restoring applied files."
UBS_MSG_ja_UPDATE_DEST_DIR_FAILED="対象パスの作成に失敗しました: %s — 適用済みファイルを復元します。"
UBS_MSG_zh_UPDATE_DEST_DIR_FAILED="创建目标路径失败: %s——正在还原已应用的文件。"

UBS_MSG_ko_UPDATE_REPLACE_TEMP_FAILED="교체 임시 파일 생성 실패: %s — 적용된 파일을 복원합니다."
UBS_MSG_en_UPDATE_REPLACE_TEMP_FAILED="Failed to create replacement temp file: %s — restoring applied files."
UBS_MSG_ja_UPDATE_REPLACE_TEMP_FAILED="置換用一時ファイルの作成に失敗しました: %s — 適用済みファイルを復元します。"
UBS_MSG_zh_UPDATE_REPLACE_TEMP_FAILED="创建替换临时文件失败: %s——正在还原已应用的文件。"

UBS_MSG_ko_UPDATE_REPLACE_PREP_FAILED="교체 준비 실패: %s"
UBS_MSG_en_UPDATE_REPLACE_PREP_FAILED="Failed to prepare replacement: %s"
UBS_MSG_ja_UPDATE_REPLACE_PREP_FAILED="置換の準備に失敗しました: %s"
UBS_MSG_zh_UPDATE_REPLACE_PREP_FAILED="准备替换失败: %s"

UBS_MSG_ko_UPDATE_PERMISSION_FAILED="권한 설정 실패: %s — 적용된 파일을 복원합니다."
UBS_MSG_en_UPDATE_PERMISSION_FAILED="Failed to set permissions: %s — restoring applied files."
UBS_MSG_ja_UPDATE_PERMISSION_FAILED="権限設定に失敗しました: %s — 適用済みファイルを復元します。"
UBS_MSG_zh_UPDATE_PERMISSION_FAILED="设置权限失败: %s——正在还原已应用的文件。"

UBS_MSG_ko_UPDATE_REPLACE_FAILED="교체 실패: %s — 적용된 파일을 복원합니다."
UBS_MSG_en_UPDATE_REPLACE_FAILED="Replacement failed: %s — restoring applied files."
UBS_MSG_ja_UPDATE_REPLACE_FAILED="置換に失敗しました: %s — 適用済みファイルを復元します。"
UBS_MSG_zh_UPDATE_REPLACE_FAILED="替换失败: %s——正在还原已应用的文件。"

UBS_MSG_ko_UPDATE_RUST_REBUILD_FAILED="경고: 관리 파일은 갱신됐지만 Rust helper 재빌드에 실패했습니다. portable fallback을 사용할 수 있습니다."
UBS_MSG_en_UPDATE_RUST_REBUILD_FAILED="Warning: managed files were updated, but rebuilding the Rust helper failed. The portable fallback can be used."
UBS_MSG_ja_UPDATE_RUST_REBUILD_FAILED="警告: 管理対象ファイルは更新されましたが、Rustヘルパーの再ビルドに失敗しました。portable fallbackを使用できます。"
UBS_MSG_zh_UPDATE_RUST_REBUILD_FAILED="警告: 受管理文件已更新，但重新构建 Rust helper 失败。可以使用可移植回退方案。"

UBS_MSG_ko_UPDATE_RUST_REBUILD_NO_CARGO="경고: Rust helper 소스가 갱신됐지만 cargo가 없어 바이너리를 재빌드하지 못했습니다."
UBS_MSG_en_UPDATE_RUST_REBUILD_NO_CARGO="Warning: Rust helper source was updated, but cargo is not available so the binary could not be rebuilt."
UBS_MSG_ja_UPDATE_RUST_REBUILD_NO_CARGO="警告: Rustヘルパーのソースは更新されましたが、cargoがないためバイナリを再ビルドできませんでした。"
UBS_MSG_zh_UPDATE_RUST_REBUILD_NO_CARGO="警告: Rust helper 源码已更新，但缺少 cargo，无法重新构建二进制文件。"

UBS_MSG_ko_UPDATE_COMPLETE="업데이트 완료: %s"
UBS_MSG_en_UPDATE_COMPLETE="Update complete: %s"
UBS_MSG_ja_UPDATE_COMPLETE="更新完了: %s"
UBS_MSG_zh_UPDATE_COMPLETE="更新完成: %s"

UBS_MSG_ko_UPDATE_BACKUP_LOCATION="백업 위치: %s"
UBS_MSG_en_UPDATE_BACKUP_LOCATION="Backup location: %s"
UBS_MSG_ja_UPDATE_BACKUP_LOCATION="バックアップの場所: %s"
UBS_MSG_zh_UPDATE_BACKUP_LOCATION="备份位置: %s"

# --- scripts/build-flutter.sh ---

UBS_MSG_ko_VERSION_RESTORE_ON_FAIL="빌드가 완료되지 않아 버전을 %s 으로 복원했습니다."
UBS_MSG_en_VERSION_RESTORE_ON_FAIL="Build did not complete, so the version was restored to %s."
UBS_MSG_ja_VERSION_RESTORE_ON_FAIL="ビルドが完了しなかったため、バージョンを %s に復元しました。"
UBS_MSG_zh_VERSION_RESTORE_ON_FAIL="构建未完成，版本已恢复为 %s。"

UBS_MSG_ko_CURRENT_VERSION_LABEL="현재 버전: %s"
UBS_MSG_en_CURRENT_VERSION_LABEL="Current version: %s"
UBS_MSG_ja_CURRENT_VERSION_LABEL="現在のバージョン: %s"
UBS_MSG_zh_CURRENT_VERSION_LABEL="当前版本: %s"

UBS_MSG_ko_UNSUPPORTED_VERSION_BUMP="지원하지 않는 UBS_VERSION_BUMP 값입니다."
UBS_MSG_en_UNSUPPORTED_VERSION_BUMP="Unsupported UBS_VERSION_BUMP value."
UBS_MSG_ja_UNSUPPORTED_VERSION_BUMP="サポートされていない UBS_VERSION_BUMP の値です。"
UBS_MSG_zh_UNSUPPORTED_VERSION_BUMP="不支持的 UBS_VERSION_BUMP 值。"

UBS_MSG_ko_NONINTERACTIVE_VERSION_POLICY="비대화형 버전 정책: %s"
UBS_MSG_en_NONINTERACTIVE_VERSION_POLICY="Non-interactive version policy: %s"
UBS_MSG_ja_NONINTERACTIVE_VERSION_POLICY="非対話型バージョンポリシー: %s"
UBS_MSG_zh_NONINTERACTIVE_VERSION_POLICY="非交互式版本策略: %s"

UBS_MSG_ko_MENU_VERSION_PROMPT="어떤 버전을 올릴까요?"
UBS_MSG_en_MENU_VERSION_PROMPT="Which version would you like to bump?"
UBS_MSG_ja_MENU_VERSION_PROMPT="どのバージョンを上げますか？"
UBS_MSG_zh_MENU_VERSION_PROMPT="要升级哪个版本？"

UBS_MSG_ko_MENU_OPT_BUILD_NUMBER_BUMP="1) Build Number만 올리기"
UBS_MSG_en_MENU_OPT_BUILD_NUMBER_BUMP="1) Bump build number only"
UBS_MSG_ja_MENU_OPT_BUILD_NUMBER_BUMP="1) ビルド番号のみ上げる"
UBS_MSG_zh_MENU_OPT_BUILD_NUMBER_BUMP="1) 仅递增 Build Number"

UBS_MSG_ko_MENU_OPT_PATCH_BUMP="2) Patch 버전 올리기"
UBS_MSG_en_MENU_OPT_PATCH_BUMP="2) Bump patch version"
UBS_MSG_ja_MENU_OPT_PATCH_BUMP="2) パッチバージョンを上げる"
UBS_MSG_zh_MENU_OPT_PATCH_BUMP="2) 递增 Patch 版本"

UBS_MSG_ko_MENU_OPT_MINOR_BUMP="3) Minor 버전 올리기"
UBS_MSG_en_MENU_OPT_MINOR_BUMP="3) Bump minor version"
UBS_MSG_ja_MENU_OPT_MINOR_BUMP="3) マイナーバージョンを上げる"
UBS_MSG_zh_MENU_OPT_MINOR_BUMP="3) 递增 Minor 版本"

UBS_MSG_ko_MENU_OPT_MAJOR_BUMP="4) Major 버전 올리기"
UBS_MSG_en_MENU_OPT_MAJOR_BUMP="4) Bump major version"
UBS_MSG_ja_MENU_OPT_MAJOR_BUMP="4) メジャーバージョンを上げる"
UBS_MSG_zh_MENU_OPT_MAJOR_BUMP="4) 递增 Major 版本"

UBS_MSG_ko_MENU_OPT_VERSION_KEEP="5) 버전 유지"
UBS_MSG_en_MENU_OPT_VERSION_KEEP="5) Keep current version"
UBS_MSG_ja_MENU_OPT_VERSION_KEEP="5) バージョンを維持"
UBS_MSG_zh_MENU_OPT_VERSION_KEEP="5) 保持版本不变"

UBS_MSG_ko_MENU_OPT_CANCEL_VERSION="6) 취소"
UBS_MSG_en_MENU_OPT_CANCEL_VERSION="6) Cancel"
UBS_MSG_ja_MENU_OPT_CANCEL_VERSION="6) キャンセル"
UBS_MSG_zh_MENU_OPT_CANCEL_VERSION="6) 取消"

UBS_MSG_ko_VERSION_KEEP_LABEL="버전 유지: %s"
UBS_MSG_en_VERSION_KEEP_LABEL="Keeping version: %s"
UBS_MSG_ja_VERSION_KEEP_LABEL="バージョンを維持: %s"
UBS_MSG_zh_VERSION_KEEP_LABEL="保持版本: %s"

UBS_MSG_ko_BUILD_CANCELLED="빌드를 취소했습니다."
UBS_MSG_en_BUILD_CANCELLED="Build cancelled."
UBS_MSG_ja_BUILD_CANCELLED="ビルドをキャンセルしました。"
UBS_MSG_zh_BUILD_CANCELLED="已取消构建。"

UBS_MSG_ko_INVALID_CHOICE_KEEP_VERSION="잘못된 선택입니다. 버전을 유지합니다."
UBS_MSG_en_INVALID_CHOICE_KEEP_VERSION="Invalid choice. Keeping the current version."
UBS_MSG_ja_INVALID_CHOICE_KEEP_VERSION="無効な選択です。バージョンを維持します。"
UBS_MSG_zh_INVALID_CHOICE_KEEP_VERSION="选择无效。将保持当前版本。"

UBS_MSG_ko_VERSION_UPDATED="버전 업데이트: %s → %s"
UBS_MSG_en_VERSION_UPDATED="Version updated: %s → %s"
UBS_MSG_ja_VERSION_UPDATED="バージョンを更新しました: %s → %s"
UBS_MSG_zh_VERSION_UPDATED="版本已更新: %s → %s"

UBS_MSG_ko_UNSUPPORTED_FLUTTER_OUTPUTS="지원하지 않는 UBS_FLUTTER_OUTPUTS 값입니다: %s"
UBS_MSG_en_UNSUPPORTED_FLUTTER_OUTPUTS="Unsupported UBS_FLUTTER_OUTPUTS value: %s"
UBS_MSG_ja_UNSUPPORTED_FLUTTER_OUTPUTS="サポートされていない UBS_FLUTTER_OUTPUTS の値です: %s"
UBS_MSG_zh_UNSUPPORTED_FLUTTER_OUTPUTS="不支持的 UBS_FLUTTER_OUTPUTS 值: %s"

UBS_MSG_ko_FLUTTER_OUTPUTS_SPECIFIED="Flutter 출력 지정: %s"
UBS_MSG_en_FLUTTER_OUTPUTS_SPECIFIED="Flutter outputs specified: %s"
UBS_MSG_ja_FLUTTER_OUTPUTS_SPECIFIED="Flutter 出力を指定: %s"
UBS_MSG_zh_FLUTTER_OUTPUTS_SPECIFIED="已指定 Flutter 输出: %s"

UBS_MSG_ko_UNSUPPORTED_FLUTTER_PLATFORM="지원하지 않는 UBS_FLUTTER_PLATFORM 값입니다."
UBS_MSG_en_UNSUPPORTED_FLUTTER_PLATFORM="Unsupported UBS_FLUTTER_PLATFORM value."
UBS_MSG_ja_UNSUPPORTED_FLUTTER_PLATFORM="サポートされていない UBS_FLUTTER_PLATFORM の値です。"
UBS_MSG_zh_UNSUPPORTED_FLUTTER_PLATFORM="不支持的 UBS_FLUTTER_PLATFORM 值。"

UBS_MSG_ko_NONINTERACTIVE_FLUTTER_PLATFORM="비대화형 Flutter 플랫폼: %s"
UBS_MSG_en_NONINTERACTIVE_FLUTTER_PLATFORM="Non-interactive Flutter platform: %s"
UBS_MSG_ja_NONINTERACTIVE_FLUTTER_PLATFORM="非対話型 Flutter プラットフォーム: %s"
UBS_MSG_zh_NONINTERACTIVE_FLUTTER_PLATFORM="非交互式 Flutter 平台: %s"

UBS_MSG_ko_MENU_PLATFORM_PROMPT="어떤 플랫폼을 빌드할까요?"
UBS_MSG_en_MENU_PLATFORM_PROMPT="Which platform would you like to build?"
UBS_MSG_ja_MENU_PLATFORM_PROMPT="どのプラットフォームをビルドしますか？"
UBS_MSG_zh_MENU_PLATFORM_PROMPT="要构建哪个平台？"

UBS_MSG_ko_MENU_OPT_PLATFORM_BOTH="1) iOS + Android 둘 다"
UBS_MSG_en_MENU_OPT_PLATFORM_BOTH="1) Both iOS + Android"
UBS_MSG_ja_MENU_OPT_PLATFORM_BOTH="1) iOS + Android 両方"
UBS_MSG_zh_MENU_OPT_PLATFORM_BOTH="1) iOS + Android 两者都要"

UBS_MSG_ko_MENU_OPT_PLATFORM_IOS="2) iOS만"
UBS_MSG_en_MENU_OPT_PLATFORM_IOS="2) iOS only"
UBS_MSG_ja_MENU_OPT_PLATFORM_IOS="2) iOS のみ"
UBS_MSG_zh_MENU_OPT_PLATFORM_IOS="2) 仅 iOS"

UBS_MSG_ko_MENU_OPT_PLATFORM_ANDROID="3) Android만"
UBS_MSG_en_MENU_OPT_PLATFORM_ANDROID="3) Android only"
UBS_MSG_ja_MENU_OPT_PLATFORM_ANDROID="3) Android のみ"
UBS_MSG_zh_MENU_OPT_PLATFORM_ANDROID="3) 仅 Android"

UBS_MSG_ko_MENU_OPT_CANCEL_PLATFORM="4) 취소"
UBS_MSG_en_MENU_OPT_CANCEL_PLATFORM="4) Cancel"
UBS_MSG_ja_MENU_OPT_CANCEL_PLATFORM="4) キャンセル"
UBS_MSG_zh_MENU_OPT_CANCEL_PLATFORM="4) 取消"

UBS_MSG_ko_PLATFORM_SELECTED_BOTH="iOS + Android 빌드"
UBS_MSG_en_PLATFORM_SELECTED_BOTH="Building iOS + Android"
UBS_MSG_ja_PLATFORM_SELECTED_BOTH="iOS + Android をビルド"
UBS_MSG_zh_PLATFORM_SELECTED_BOTH="构建 iOS + Android"

UBS_MSG_ko_PLATFORM_SELECTED_IOS="iOS만 빌드"
UBS_MSG_en_PLATFORM_SELECTED_IOS="Building iOS only"
UBS_MSG_ja_PLATFORM_SELECTED_IOS="iOS のみビルド"
UBS_MSG_zh_PLATFORM_SELECTED_IOS="仅构建 iOS"

UBS_MSG_ko_PLATFORM_SELECTED_ANDROID="Android만 빌드"
UBS_MSG_en_PLATFORM_SELECTED_ANDROID="Building Android only"
UBS_MSG_ja_PLATFORM_SELECTED_ANDROID="Android のみビルド"
UBS_MSG_zh_PLATFORM_SELECTED_ANDROID="仅构建 Android"

UBS_MSG_ko_INVALID_CHOICE_BOTH="잘못된 선택입니다. iOS + Android 둘 다 빌드합니다."
UBS_MSG_en_INVALID_CHOICE_BOTH="Invalid choice. Building both iOS + Android."
UBS_MSG_ja_INVALID_CHOICE_BOTH="無効な選択です。iOS + Android の両方をビルドします。"
UBS_MSG_zh_INVALID_CHOICE_BOTH="选择无效。将同时构建 iOS + Android。"

UBS_MSG_ko_PARALLEL_PREF_SAVED_PARALLEL="저장된 설정: 동시 빌드 사용"
UBS_MSG_en_PARALLEL_PREF_SAVED_PARALLEL="Saved setting: using concurrent build"
UBS_MSG_ja_PARALLEL_PREF_SAVED_PARALLEL="保存された設定: 同時ビルドを使用"
UBS_MSG_zh_PARALLEL_PREF_SAVED_PARALLEL="已保存的设置: 使用并行构建"

UBS_MSG_ko_PARALLEL_PREF_SAVED_SEQUENTIAL="저장된 설정: 순차 빌드 사용"
UBS_MSG_en_PARALLEL_PREF_SAVED_SEQUENTIAL="Saved setting: using sequential build"
UBS_MSG_ja_PARALLEL_PREF_SAVED_SEQUENTIAL="保存された設定: 順次ビルドを使用"
UBS_MSG_zh_PARALLEL_PREF_SAVED_SEQUENTIAL="已保存的设置: 使用顺序构建"

UBS_MSG_ko_PARALLEL_PREF_CHANGE_HINT="(변경하려면 %s 삭제)"
UBS_MSG_en_PARALLEL_PREF_CHANGE_HINT="(delete %s to change)"
UBS_MSG_ja_PARALLEL_PREF_CHANGE_HINT="(変更するには %s を削除)"
UBS_MSG_zh_PARALLEL_PREF_CHANGE_HINT="（如需更改，请删除 %s）"

UBS_MSG_ko_PARALLEL_CHOICE_PROMPT="iOS·Android 빌드 방식을 선택하세요."
UBS_MSG_en_PARALLEL_CHOICE_PROMPT="Choose how to build iOS and Android."
UBS_MSG_ja_PARALLEL_CHOICE_PROMPT="iOS・Android のビルド方式を選択してください。"
UBS_MSG_zh_PARALLEL_CHOICE_PROMPT="请选择 iOS 和 Android 的构建方式。"

UBS_MSG_ko_MENU_OPT_SEQUENTIAL="1) 순차 빌드 (권장)"
UBS_MSG_en_MENU_OPT_SEQUENTIAL="1) Sequential build (recommended)"
UBS_MSG_ja_MENU_OPT_SEQUENTIAL="1) 順次ビルド（推奨）"
UBS_MSG_zh_MENU_OPT_SEQUENTIAL="1) 顺序构建（推荐）"

UBS_MSG_ko_MENU_OPT_CONCURRENT="2) 동시 빌드"
UBS_MSG_en_MENU_OPT_CONCURRENT="2) Concurrent build"
UBS_MSG_ja_MENU_OPT_CONCURRENT="2) 同時ビルド"
UBS_MSG_zh_MENU_OPT_CONCURRENT="2) 并行构建"

UBS_MSG_ko_MENU_OPT_CONCURRENT_WARNING="(Gradle+Xcode 동시 실행 → 메모리 여유 없으면 오히려 느려질 수 있음)"
UBS_MSG_en_MENU_OPT_CONCURRENT_WARNING="(runs Gradle+Xcode concurrently → can be slower if memory is limited)"
UBS_MSG_ja_MENU_OPT_CONCURRENT_WARNING="(Gradle+Xcode を同時実行 → メモリに余裕がないとかえって遅くなる場合あり)"
UBS_MSG_zh_MENU_OPT_CONCURRENT_WARNING="（同时运行 Gradle+Xcode → 内存不足时反而可能更慢）"

UBS_MSG_ko_PARALLEL_CHOSEN_CONCURRENT="동시 빌드로 진행"
UBS_MSG_en_PARALLEL_CHOSEN_CONCURRENT="Proceeding with concurrent build"
UBS_MSG_ja_PARALLEL_CHOSEN_CONCURRENT="同時ビルドで進めます"
UBS_MSG_zh_PARALLEL_CHOSEN_CONCURRENT="将以并行构建方式进行"

UBS_MSG_ko_PARALLEL_CHOSEN_SEQUENTIAL="순차 빌드로 진행"
UBS_MSG_en_PARALLEL_CHOSEN_SEQUENTIAL="Proceeding with sequential build"
UBS_MSG_ja_PARALLEL_CHOSEN_SEQUENTIAL="順次ビルドで進めます"
UBS_MSG_zh_PARALLEL_CHOSEN_SEQUENTIAL="将以顺序构建方式进行"

UBS_MSG_ko_PARALLEL_PREF_SAVE_NOTICE="이 선택은 저장되어 다음부터 자동 적용됩니다. 바꾸려면 %s 을 삭제하세요."
UBS_MSG_en_PARALLEL_PREF_SAVE_NOTICE="This choice is saved and applied automatically next time. To change it, delete %s."
UBS_MSG_ja_PARALLEL_PREF_SAVE_NOTICE="この選択は保存され、次回から自動的に適用されます。変更するには %s を削除してください。"
UBS_MSG_zh_PARALLEL_PREF_SAVE_NOTICE="此选择已保存，下次将自动应用。如需更改，请删除 %s。"

UBS_MSG_ko_ENV_FILE_MISSING=".env 파일 없음 — dart-define 없이 빌드합니다."
UBS_MSG_en_ENV_FILE_MISSING="No .env file found — building without dart-define."
UBS_MSG_ja_ENV_FILE_MISSING=".env ファイルが見つかりません — dart-define なしでビルドします。"
UBS_MSG_zh_ENV_FILE_MISSING="未找到 .env 文件 — 将不使用 dart-define 进行构建。"

UBS_MSG_ko_ENV_FILE_LABEL="환경변수: %s"
UBS_MSG_en_ENV_FILE_LABEL="Environment file: %s"
UBS_MSG_ja_ENV_FILE_LABEL="環境変数ファイル: %s"
UBS_MSG_zh_ENV_FILE_LABEL="环境变量文件: %s"

UBS_MSG_ko_STEP_CLEAN_FETCH="Cleaning & Fetching Dependencies..."
UBS_MSG_en_STEP_CLEAN_FETCH="Cleaning & Fetching Dependencies..."
UBS_MSG_ja_STEP_CLEAN_FETCH="クリーンアップと依存関係の取得中..."
UBS_MSG_zh_STEP_CLEAN_FETCH="正在清理并获取依赖..."

UBS_MSG_ko_SKIP_CLEAN_NOTICE="UBS_SKIP_CLEAN=true — 기존 빌드 캐시를 유지합니다."
UBS_MSG_en_SKIP_CLEAN_NOTICE="UBS_SKIP_CLEAN=true — keeping the existing build cache."
UBS_MSG_ja_SKIP_CLEAN_NOTICE="UBS_SKIP_CLEAN=true — 既存のビルドキャッシュを維持します。"
UBS_MSG_zh_SKIP_CLEAN_NOTICE="UBS_SKIP_CLEAN=true — 将保留现有构建缓存。"

UBS_MSG_ko_STEP_BUILD_ANDROID="Building Android App Bundle (Optimized)..."
UBS_MSG_en_STEP_BUILD_ANDROID="Building Android App Bundle (Optimized)..."
UBS_MSG_ja_STEP_BUILD_ANDROID="Android App Bundle をビルド中（最適化）..."
UBS_MSG_zh_STEP_BUILD_ANDROID="正在构建 Android App Bundle（优化）..."

UBS_MSG_ko_STEP_BUILD_APK="Building Android APKs (Optimized, split per ABI)..."
UBS_MSG_en_STEP_BUILD_APK="Building Android APKs (Optimized, split per ABI)..."
UBS_MSG_ja_STEP_BUILD_APK="Android APK をビルド中（最適化、ABI ごとに分割）..."
UBS_MSG_zh_STEP_BUILD_APK="正在构建 Android APK（优化，按 ABI 拆分）..."

UBS_MSG_ko_EXPORT_OPTIONS_FALLBACK="앱 전용 ExportOptions가 없어 UBS 일반 App Store 템플릿을 사용합니다."
UBS_MSG_en_EXPORT_OPTIONS_FALLBACK="No app-specific ExportOptions found — using the generic UBS App Store template."
UBS_MSG_ja_EXPORT_OPTIONS_FALLBACK="アプリ専用の ExportOptions がないため、UBS の汎用 App Store テンプレートを使用します。"
UBS_MSG_zh_EXPORT_OPTIONS_FALLBACK="未找到应用专用的 ExportOptions，将使用 UBS 通用 App Store 模板。"

UBS_MSG_ko_EXPORT_OPTIONS_NOT_FOUND="iOS 내보내기 설정을 찾을 수 없습니다: %s"
UBS_MSG_en_EXPORT_OPTIONS_NOT_FOUND="Could not find iOS export options: %s"
UBS_MSG_ja_EXPORT_OPTIONS_NOT_FOUND="iOS のエクスポート設定が見つかりません: %s"
UBS_MSG_zh_EXPORT_OPTIONS_NOT_FOUND="找不到 iOS 导出设置: %s"

UBS_MSG_ko_STEP_BUILD_IOS="Building iOS IPA (Archive + Export)..."
UBS_MSG_en_STEP_BUILD_IOS="Building iOS IPA (Archive + Export)..."
UBS_MSG_ja_STEP_BUILD_IOS="iOS IPA をビルド中（アーカイブ + エクスポート）..."
UBS_MSG_zh_STEP_BUILD_IOS="正在构建 iOS IPA（归档 + 导出）..."

UBS_MSG_ko_STEP_BUILD_WEB="Building Flutter Web (Optimized)..."
UBS_MSG_en_STEP_BUILD_WEB="Building Flutter Web (Optimized)..."
UBS_MSG_ja_STEP_BUILD_WEB="Flutter Web をビルド中（最適化）..."
UBS_MSG_zh_STEP_BUILD_WEB="正在构建 Flutter Web（优化）..."

UBS_MSG_ko_PARALLEL_BUILD_START="Android·iOS 동시 빌드 시작 (로그가 섞여 보일 수 있음)"
UBS_MSG_en_PARALLEL_BUILD_START="Starting concurrent Android·iOS build (logs may appear interleaved)"
UBS_MSG_ja_PARALLEL_BUILD_START="Android・iOS の同時ビルドを開始します（ログが混在して表示される場合があります）"
UBS_MSG_zh_PARALLEL_BUILD_START="开始并行构建 Android·iOS（日志可能会交错显示）"

UBS_MSG_ko_PARALLEL_BUILD_FAILED="동시 빌드 실패 (Android: %s, iOS: %s)"
UBS_MSG_en_PARALLEL_BUILD_FAILED="Concurrent build failed (Android: %s, iOS: %s)"
UBS_MSG_ja_PARALLEL_BUILD_FAILED="同時ビルドに失敗しました（Android: %s, iOS: %s）"
UBS_MSG_zh_PARALLEL_BUILD_FAILED="并行构建失败（Android: %s，iOS: %s）"

UBS_MSG_ko_BUILD_SUCCESS="BUILD COMPLETED SUCCESSFULLY!"
UBS_MSG_en_BUILD_SUCCESS="BUILD COMPLETED SUCCESSFULLY!"
UBS_MSG_ja_BUILD_SUCCESS="ビルドが正常に完了しました！"
UBS_MSG_zh_BUILD_SUCCESS="构建成功完成！"

UBS_MSG_ko_BUILD_SUMMARY_VERSION="Version    : %s"
UBS_MSG_en_BUILD_SUMMARY_VERSION="Version    : %s"
UBS_MSG_ja_BUILD_SUMMARY_VERSION="Version    : %s"
UBS_MSG_zh_BUILD_SUMMARY_VERSION="Version    : %s"

UBS_MSG_ko_BUILD_SUMMARY_ANDROID_AAB="Android AAB : %s"
UBS_MSG_en_BUILD_SUMMARY_ANDROID_AAB="Android AAB : %s"
UBS_MSG_ja_BUILD_SUMMARY_ANDROID_AAB="Android AAB : %s"
UBS_MSG_zh_BUILD_SUMMARY_ANDROID_AAB="Android AAB : %s"

UBS_MSG_ko_BUILD_SUMMARY_IOS_IPA="iOS IPA     : %s"
UBS_MSG_en_BUILD_SUMMARY_IOS_IPA="iOS IPA     : %s"
UBS_MSG_ja_BUILD_SUMMARY_IOS_IPA="iOS IPA     : %s"
UBS_MSG_zh_BUILD_SUMMARY_IOS_IPA="iOS IPA     : %s"

UBS_MSG_ko_BUILD_SUMMARY_ANDROID_APK="Android APK : %s/ (ABI별 APK)"
UBS_MSG_en_BUILD_SUMMARY_ANDROID_APK="Android APK : %s/ (per-ABI APK)"
UBS_MSG_ja_BUILD_SUMMARY_ANDROID_APK="Android APK : %s/ (ABI ごとの APK)"
UBS_MSG_zh_BUILD_SUMMARY_ANDROID_APK="Android APK : %s/（按 ABI 拆分的 APK）"

UBS_MSG_ko_BUILD_SUMMARY_FLUTTER_WEB="Flutter Web : %s/"
UBS_MSG_en_BUILD_SUMMARY_FLUTTER_WEB="Flutter Web : %s/"
UBS_MSG_ja_BUILD_SUMMARY_FLUTTER_WEB="Flutter Web : %s/"
UBS_MSG_zh_BUILD_SUMMARY_FLUTTER_WEB="Flutter Web : %s/"

UBS_MSG_ko_BUILD_SUMMARY_ELAPSED="빌드 시간   : %s (%s 빌드)"
UBS_MSG_en_BUILD_SUMMARY_ELAPSED="Build time   : %s (%s build)"
UBS_MSG_ja_BUILD_SUMMARY_ELAPSED="ビルド時間   : %s (%s ビルド)"
UBS_MSG_zh_BUILD_SUMMARY_ELAPSED="构建时间   : %s（%s 构建）"

UBS_MSG_ko_BUILD_MODE_PARALLEL="동시"
UBS_MSG_en_BUILD_MODE_PARALLEL="concurrent"
UBS_MSG_ja_BUILD_MODE_PARALLEL="同時"
UBS_MSG_zh_BUILD_MODE_PARALLEL="并行"

UBS_MSG_ko_BUILD_MODE_SEQUENTIAL="순차"
UBS_MSG_en_BUILD_MODE_SEQUENTIAL="sequential"
UBS_MSG_ja_BUILD_MODE_SEQUENTIAL="順次"
UBS_MSG_zh_BUILD_MODE_SEQUENTIAL="顺序"

# --- shared: interactive prompts / notifications (build-flutter.sh, build-tauri-macos.sh) ---

UBS_MSG_ko_CHOICE_PROMPT_1_2="선택 (1-2): "
UBS_MSG_en_CHOICE_PROMPT_1_2="Choice (1-2): "
UBS_MSG_ja_CHOICE_PROMPT_1_2="選択 (1-2): "
UBS_MSG_zh_CHOICE_PROMPT_1_2="选择 (1-2): "

UBS_MSG_ko_CHOICE_PROMPT_1_4="선택 (1-4): "
UBS_MSG_en_CHOICE_PROMPT_1_4="Choice (1-4): "
UBS_MSG_ja_CHOICE_PROMPT_1_4="選択 (1-4): "
UBS_MSG_zh_CHOICE_PROMPT_1_4="选择 (1-4): "

UBS_MSG_ko_CHOICE_PROMPT_1_5="선택 (1-5): "
UBS_MSG_en_CHOICE_PROMPT_1_5="Choice (1-5): "
UBS_MSG_ja_CHOICE_PROMPT_1_5="選択 (1-5): "
UBS_MSG_zh_CHOICE_PROMPT_1_5="选择 (1-5): "

UBS_MSG_ko_CHOICE_PROMPT_1_6="선택 (1-6): "
UBS_MSG_en_CHOICE_PROMPT_1_6="Choice (1-6): "
UBS_MSG_ja_CHOICE_PROMPT_1_6="選択 (1-6): "
UBS_MSG_zh_CHOICE_PROMPT_1_6="选择 (1-6): "

UBS_MSG_ko_NOTIFY_BUILD_DONE="Version %s 빌드 완료 (%s)"
UBS_MSG_en_NOTIFY_BUILD_DONE="Version %s build complete (%s)"
UBS_MSG_ja_NOTIFY_BUILD_DONE="Version %s ビルド完了 (%s)"
UBS_MSG_zh_NOTIFY_BUILD_DONE="Version %s 构建完成 (%s)"

# --- shared: version-change commit (build-flutter.sh, build-tauri-macos.sh) ---

UBS_MSG_ko_VERSION_COMMIT_SUCCESS="버전 변경 커밋: chore: 버전 %s"
UBS_MSG_en_VERSION_COMMIT_SUCCESS="Committed version change: chore: version %s"
UBS_MSG_ja_VERSION_COMMIT_SUCCESS="バージョン変更をコミットしました: chore: version %s"
UBS_MSG_zh_VERSION_COMMIT_SUCCESS="已提交版本变更: chore: version %s"

UBS_MSG_ko_VERSION_COMMIT_SUCCESS_APP="버전 변경 커밋: chore: %s 버전 %s"
UBS_MSG_en_VERSION_COMMIT_SUCCESS_APP="Committed version change: chore: %s version %s"
UBS_MSG_ja_VERSION_COMMIT_SUCCESS_APP="バージョン変更をコミットしました: chore: %s version %s"
UBS_MSG_zh_VERSION_COMMIT_SUCCESS_APP="已提交版本变更: chore: %s version %s"

UBS_MSG_ko_VERSION_COMMIT_FAILED="버전 변경(%s)을 자동 커밋하지 못했습니다 — 직접 커밋하세요."
UBS_MSG_en_VERSION_COMMIT_FAILED="Failed to auto-commit the version change (%s) — commit it manually."
UBS_MSG_ja_VERSION_COMMIT_FAILED="バージョン変更(%s)の自動コミットに失敗しました — 手動でコミットしてください。"
UBS_MSG_zh_VERSION_COMMIT_FAILED="自动提交版本变更(%s)失败 — 请手动提交。"

UBS_MSG_ko_VERSION_COMMIT_NOT_GIT_REPO="git 저장소가 아니라 버전 변경(%s)이 uncommitted 상태로 남습니다."
UBS_MSG_en_VERSION_COMMIT_NOT_GIT_REPO="Not a git repository, so the version change (%s) remains uncommitted."
UBS_MSG_ja_VERSION_COMMIT_NOT_GIT_REPO="git リポジトリではないため、バージョン変更(%s)はコミットされないまま残ります。"
UBS_MSG_zh_VERSION_COMMIT_NOT_GIT_REPO="不是 git 仓库，版本变更(%s)将保持未提交状态。"

# --- shared: build-finished OS notification (build-flutter.sh, build-tauri-macos.sh) ---

UBS_MSG_ko_NOTIFY_TTS_BUILD_COMPLETE="빌드가 성공적으로 완료되었습니다"
UBS_MSG_en_NOTIFY_TTS_BUILD_COMPLETE="Build process completed successfully"
UBS_MSG_ja_NOTIFY_TTS_BUILD_COMPLETE="ビルドが正常に完了しました"
UBS_MSG_zh_NOTIFY_TTS_BUILD_COMPLETE="构建已成功完成"

UBS_MSG_ko_NOTIFY_TITLE_BUILD_FINISHED="빌드 완료"
UBS_MSG_en_NOTIFY_TITLE_BUILD_FINISHED="Build Finished"
UBS_MSG_ja_NOTIFY_TITLE_BUILD_FINISHED="ビルド完了"
UBS_MSG_zh_NOTIFY_TITLE_BUILD_FINISHED="构建完成"

UBS_MSG_ko_NOTIFY_SUBTITLE_DEPLOYMENT_READY="배포 파일 준비 완료"
UBS_MSG_en_NOTIFY_SUBTITLE_DEPLOYMENT_READY="Deployment files are ready"
UBS_MSG_ja_NOTIFY_SUBTITLE_DEPLOYMENT_READY="デプロイファイルの準備ができました"
UBS_MSG_zh_NOTIFY_SUBTITLE_DEPLOYMENT_READY="部署文件已就绪"

UBS_MSG_ko_NOTIFY_SUBTITLE_ARTIFACT_READY="%s 준비 완료"
UBS_MSG_en_NOTIFY_SUBTITLE_ARTIFACT_READY="%s is ready"
UBS_MSG_ja_NOTIFY_SUBTITLE_ARTIFACT_READY="%s の準備ができました"
UBS_MSG_zh_NOTIFY_SUBTITLE_ARTIFACT_READY="%s 已就绪"
