"""Message catalog data for scripts/i18n.py. Imported only from there.

MESSAGES maps a key to a dict of {"ko": ..., "en": ..., "ja": ..., "zh": ...}.
Use {name}-style placeholders and call t(key, name=value) to fill them.
Keep ANSI color codes and emoji OUT of these strings — call sites wrap them.
"""

from __future__ import annotations

MESSAGES: dict[str, dict[str, str]] = {
    "NODE_SKIP_INSTALL": {
        "ko": "Node 의존성 설치를 건너뜁니다 (UBS_SKIP_INSTALL=true).",
        "en": "Skipping Node dependency installation (UBS_SKIP_INSTALL=true).",
        "ja": "Node の依存関係インストールをスキップします (UBS_SKIP_INSTALL=true)。",
        "zh": "跳过 Node 依赖安装 (UBS_SKIP_INSTALL=true)。",
    },
    "NODE_INSTALL_MODE_INVALID": {
        "ko": "UBS_INSTALL_MODE은 auto 또는 always여야 합니다: {mode}",
        "en": "UBS_INSTALL_MODE must be auto or always: {mode}",
        "ja": "UBS_INSTALL_MODE は auto または always である必要があります: {mode}",
        "zh": "UBS_INSTALL_MODE 必须是 auto 或 always: {mode}",
    },
    "NODE_INSTALL_SKIP_UNCHANGED": {
        "ko": "의존성 입력이 변경되지 않아 {manager} install을 생략합니다.",
        "en": "Dependency inputs unchanged; skipping {manager} install.",
        "ja": "依存関係の入力が変更されていないため、{manager} install をスキップします。",
        "zh": "依赖输入未变化，跳过 {manager} install。",
    },
    "NODE_MANAGER_REQUIRED": {
        "ko": "{manager} 패키지 매니저가 필요합니다.",
        "en": "The {manager} package manager is required.",
        "ja": "{manager} パッケージマネージャーが必要です。",
        "zh": "需要 {manager} 包管理器。",
    },
    "NODE_BUILD_START": {
        "ko": "Node 프로젝트 빌드 ({manager}, script={script})",
        "en": "Building Node project ({manager}, script={script})",
        "ja": "Node プロジェクトをビルド中 ({manager}, script={script})",
        "zh": "正在构建 Node 项目 ({manager}, script={script})",
    },
    "NODE_WORKSPACE_ROOT": {
        "ko": "Node workspace root: {workspace}",
        "en": "Node workspace root: {workspace}",
        "ja": "Node workspace root: {workspace}",
        "zh": "Node workspace root: {workspace}",
    },
    "NODE_BUILD_DONE": {
        "ko": "Node 빌드 완료 ({seconds}s)",
        "en": "Node build complete ({seconds}s)",
        "ja": "Node ビルド完了 ({seconds}s)",
        "zh": "Node 构建完成 ({seconds}s)",
    },
    "GRADLE_COMMAND_REQUIRED": {
        "ko": "Gradle Wrapper 또는 gradle 명령이 필요합니다.",
        "en": "Gradle Wrapper or the gradle command is required.",
        "ja": "Gradle Wrapper または gradle コマンドが必要です。",
        "zh": "需要 Gradle Wrapper 或 gradle 命令。",
    },
    "GRADLE_BUILD_START": {
        "ko": "Gradle 프로젝트 빌드: {command}",
        "en": "Building Gradle project: {command}",
        "ja": "Gradle プロジェクトをビルド中: {command}",
        "zh": "正在构建 Gradle 项目: {command}",
    },
    "GRADLE_BUILD_DONE": {
        "ko": "Gradle 빌드 완료 ({seconds}s)",
        "en": "Gradle build complete ({seconds}s)",
        "ja": "Gradle ビルド完了 ({seconds}s)",
        "zh": "Gradle 构建完成 ({seconds}s)",
    },
    "XCODE_MACOS_ONLY": {
        "ko": "Xcode iOS 빌드는 macOS에서만 실행할 수 있습니다.",
        "en": "Xcode iOS builds can only run on macOS.",
        "ja": "Xcode iOS ビルドは macOS でのみ実行できます。",
        "zh": "Xcode iOS 构建仅可在 macOS 上运行。",
    },
    "XCODEBUILD_NOT_FOUND": {
        "ko": "xcodebuild를 찾을 수 없습니다. Xcode Command Line Tools가 필요합니다.",
        "en": "xcodebuild not found. Xcode Command Line Tools is required.",
        "ja": "xcodebuild が見つかりません。Xcode Command Line Tools が必要です。",
        "zh": "找不到 xcodebuild。需要 Xcode Command Line Tools。",
    },
    "XCODE_ARCHIVE_START": {
        "ko": "Xcode archive 빌드: {command}",
        "en": "Building Xcode archive: {command}",
        "ja": "Xcode archive をビルド中: {command}",
        "zh": "正在构建 Xcode archive: {command}",
    },
    "XCODE_EXPORT_OPTIONS_MISSING": {
        "ko": "ExportOptions.plist를 찾을 수 없습니다: {path}",
        "en": "Could not find ExportOptions.plist: {path}",
        "ja": "ExportOptions.plist が見つかりません: {path}",
        "zh": "找不到 ExportOptions.plist: {path}",
    },
    "XCODE_BUILD_DONE": {
        "ko": "Xcode 빌드 완료 ({seconds}s)",
        "en": "Xcode build complete ({seconds}s)",
        "ja": "Xcode ビルド完了 ({seconds}s)",
        "zh": "Xcode 构建完成 ({seconds}s)",
    },
    "ASC_MACOS_ONLY": {
        "ko": "App Store Connect 업로드는 macOS에서만 실행할 수 있습니다.",
        "en": "App Store Connect uploads can only run on macOS.",
        "ja": "App Store Connect へのアップロードは macOS でのみ実行できます。",
        "zh": "App Store Connect 上传仅可在 macOS 上运行。",
    },
    "ASC_ENV_MISSING": {
        "ko": "App Store Connect 환경변수가 없습니다: {missing}",
        "en": "Missing App Store Connect environment variables: {missing}",
        "ja": "App Store Connect の環境変数がありません: {missing}",
        "zh": "缺少 App Store Connect 环境变量: {missing}",
    },
    "ASC_UNSUPPORTED_ARTIFACT": {
        "ko": "App Store Connect에서 지원하지 않는 산출물입니다: {artifact}",
        "en": "Artifact not supported by App Store Connect: {artifact}",
        "ja": "App Store Connect でサポートされていない成果物です: {artifact}",
        "zh": "App Store Connect 不支持的产物: {artifact}",
    },
    "ASC_VERSION_MISSING": {
        "ko": "앱 버전을 확인할 수 없습니다. 환경변수를 설정하세요: {missing}",
        "en": "Could not determine app version. Set the environment variable(s): {missing}",
        "ja": "アプリバージョンを確認できません。環境変数を設定してください: {missing}",
        "zh": "无法确定应用版本。请设置环境变量: {missing}",
    },
    "ASC_UPLOAD_START": {
        "ko": "스토어 업로드: {artifact} → App Store Connect 앱 {apple_id} ({bundle_id})",
        "en": "Store upload: {artifact} → App Store Connect app {apple_id} ({bundle_id})",
        "ja": "ストアアップロード: {artifact} → App Store Connect アプリ {apple_id} ({bundle_id})",
        "zh": "商店上传: {artifact} → App Store Connect 应用 {apple_id} ({bundle_id})",
    },
    "ASC_ALTOOL_EXEC_FAILED": {
        "ko": "altool을 실행할 수 없습니다: {error}",
        "en": "Could not run altool: {error}",
        "ja": "altool を実行できません: {error}",
        "zh": "无法执行 altool: {error}",
    },
    "PLAY_ENV_MISSING": {
        "ko": "Google Play 환경변수가 없습니다: {missing}",
        "en": "Missing Google Play environment variables: {missing}",
        "ja": "Google Play の環境変数がありません: {missing}",
        "zh": "缺少 Google Play 环境变量: {missing}",
    },
    "PLAY_INVALID_TRACK": {
        "ko": "잘못된 Google Play 트랙: {track}",
        "en": "Invalid Google Play track: {track}",
        "ja": "無効な Google Play トラックです: {track}",
        "zh": "无效的 Google Play 发布通道: {track}",
    },
    "PLAY_SERVICE_ACCOUNT_READ_FAILED": {
        "ko": "Google Play 서비스 계정을 읽을 수 없습니다: {error}",
        "en": "Could not read the Google Play service account: {error}",
        "ja": "Google Play サービスアカウントを読み込めません: {error}",
        "zh": "无法读取 Google Play 服务账号: {error}",
    },
    "PLAY_UPLOAD_START": {
        "ko": "스토어 업로드: {artifact} → Google Play 앱 {package}, 트랙 {track}",
        "en": "Store upload: {artifact} → Google Play app {package}, track {track}",
        "ja": "ストアアップロード: {artifact} → Google Play アプリ {package}、トラック {track}",
        "zh": "商店上传: {artifact} → Google Play 应用 {package}，发布通道 {track}",
    },
    "PLAY_UPLOAD_BYTE_RANGE": {
        "ko": ", 마지막 시도 바이트 {start}-{end}",
        "en": ", last attempted bytes {start}-{end}",
        "ja": "、最後に試行したバイト範囲 {start}-{end}",
        "zh": "，最后尝试的字节范围 {start}-{end}",
    },
    "PLAY_UPLOAD_FAILED": {
        "ko": "Google Play 업로드 실패 ({artifact}{upload_point}): {error}",
        "en": "Google Play upload failed ({artifact}{upload_point}): {error}",
        "ja": "Google Play アップロードに失敗しました ({artifact}{upload_point}): {error}",
        "zh": "Google Play 上传失败 ({artifact}{upload_point}): {error}",
    },
    "PLAY_UPLOAD_DONE": {
        "ko": "Google Play 업로드 완료: {artifact} → {track}",
        "en": "Google Play upload complete: {artifact} → {track}",
        "ja": "Google Play アップロード完了: {artifact} → {track}",
        "zh": "Google Play 上传完成: {artifact} → {track}",
    },
    "PUBLISH_NO_ARTIFACTS": {
        "ko": "업로드할 스토어 산출물이 없습니다: {path}",
        "en": "No store artifacts to upload: {path}",
        "ja": "アップロードするストア成果物がありません: {path}",
        "zh": "没有可上传的商店产物: {path}",
    },
    "PUBLISH_PRODUCTION_TRACK_WARNING": {
        "ko": "경고: --track production 없이 환경변수로 production 트랙이 선택되었습니다.",
        "en": "Warning: the production track was selected via environment variable without --track production.",
        "ja": "警告: --track production を指定せずに環境変数で production トラックが選択されました。",
        "zh": "警告: 未使用 --track production，但通过环境变量选择了 production 发布通道。",
    },
    "OUTPUT_DIR_NOT_FOUND": {
        "ko": "예상 출력 폴더를 찾을 수 없습니다: {path}",
        "en": "Could not find the expected output folder: {path}",
        "ja": "想定される出力フォルダーが見つかりません: {path}",
        "zh": "找不到预期的输出文件夹: {path}",
    },
    "OUTPUT_DIR_OPEN_NO_PROGRAM": {
        "ko": "결과 폴더를 열 프로그램을 찾지 못했습니다: {directory}",
        "en": "Could not find a program to open the result folder: {directory}",
        "ja": "結果フォルダーを開くプログラムが見つかりません: {directory}",
        "zh": "找不到可打开结果文件夹的程序: {directory}",
    },
    "OUTPUT_DIR_OPEN_FAILED": {
        "ko": "결과 폴더를 열지 못했습니다: {directory} ({error})",
        "en": "Failed to open the result folder: {directory} ({error})",
        "ja": "結果フォルダーを開けませんでした: {directory} ({error})",
        "zh": "无法打开结果文件夹: {directory} ({error})",
    },
    "BUILD_OUTPUT_DIR": {
        "ko": "빌드 결과 폴더: {link}",
        "en": "Build output folder: {link}",
        "ja": "ビルド結果フォルダー: {link}",
        "zh": "构建结果文件夹: {link}",
    },
    "PROJECT_TYPE_UNSUPPORTED": {
        "ko": "지원하지 않는 프로젝트 타입입니다: {type}",
        "en": "Unsupported project type: {type}",
        "ja": "サポートされていないプロジェクトタイプです: {type}",
        "zh": "不支持的项目类型: {type}",
    },
    "BUILD_ADAPTER_MISSING": {
        "ko": "빌드 어댑터가 없습니다: {adapter}",
        "en": "Build adapter not found: {adapter}",
        "ja": "ビルドアダプターが見つかりません: {adapter}",
        "zh": "找不到构建适配器: {adapter}",
    },
    "NO_MATCHING_PROJECTS": {
        "ko": "조건에 맞는 프로젝트가 없습니다.",
        "en": "No projects match the given conditions.",
        "ja": "条件に一致するプロジェクトがありません。",
        "zh": "没有符合条件的项目。",
    },
    "FAIL_FAST_SEQUENTIAL": {
        "ko": "--fail-fast에서는 결정적 중단을 위해 순차 실행합니다.",
        "en": "With --fail-fast, running sequentially for deterministic stopping.",
        "ja": "--fail-fast では決定的に停止するため順次実行します。",
        "zh": "使用 --fail-fast 时将顺序执行以确保确定性中止。",
    },
    "BUILD_FAILED": {
        "ko": "빌드 실패: [{type}] {path}",
        "en": "Build failed: [{type}] {path}",
        "ja": "ビルド失敗: [{type}] {path}",
        "zh": "构建失败: [{type}] {path}",
    },
    "PARALLEL_EXECUTION_PLAN": {
        "ko": "프로젝트 {projects}개를 위상 단계 {layers}개, 충돌 없는 그룹 {groups}개로 나눠 최대 {jobs}개씩 병렬 실행합니다 (직렬 그룹 {serial}개).",
        "en": "Running {projects} project(s) across {layers} topological level(s) and {groups} conflict-free group(s), up to {jobs} in parallel (serial groups: {serial}).",
        "ja": "プロジェクト {projects} 個を、トポロジカル段階 {layers} 個、競合のないグループ {groups} 個に分け、最大 {jobs} 個ずつ並列実行します(直列グループ {serial} 個)。",
        "zh": "将 {projects} 个项目分为 {layers} 个拓扑层级、{groups} 个无冲突分组，最多 {jobs} 个并行执行(串行分组 {serial} 个)。",
    },
    "BUILD_SKIPPED": {
        "ko": "빌드 건너뜀: [{type}] {path} ({reason})",
        "en": "Build skipped: [{type}] {path} ({reason})",
        "ja": "ビルドをスキップ: [{type}] {path} ({reason})",
        "zh": "跳过构建: [{type}] {path} ({reason})",
    },
    "TOPO_LEVEL_PROJECTS": {
        "ko": "위상 단계 {level}: 프로젝트 {count}개",
        "en": "Topological level {level}: {count} project(s)",
        "ja": "トポロジカル段階 {level}: プロジェクト {count} 個",
        "zh": "拓扑层级 {level}: {count} 个项目",
    },
    "BUILD_GROUP_ERROR": {
        "ko": "빌드 그룹 실행 오류: {error}",
        "en": "Build group execution error: {error}",
        "ja": "ビルドグループ実行エラー: {error}",
        "zh": "构建分组执行出错: {error}",
    },
    "BUILD_SUMMARY_TOTAL": {"ko": "전체", "en": "Total", "ja": "合計", "zh": "总计"},
    "BUILD_SUMMARY_SUCCESS": {"ko": "성공", "en": "Succeeded", "ja": "成功", "zh": "成功"},
    "BUILD_SUMMARY_FAILED": {"ko": "실패", "en": "Failed", "ja": "失敗", "zh": "失败"},
    "BUILD_SUMMARY_SKIPPED": {"ko": "건너뜀", "en": "Skipped", "ja": "スキップ", "zh": "跳过"},
    "PUBLISH_SKIPPED_DUE_TO_FAILURE": {
        "ko": "빌드 실패가 있어 발행 단계를 모두 건너뜁니다.",
        "en": "Skipping all publish steps due to build failures.",
        "ja": "ビルド失敗があるため、発行ステップをすべてスキップします。",
        "zh": "由于存在构建失败，将跳过所有发布步骤。",
    },
    "UPDATE_MODULE_MISSING": {
        "ko": "업데이트 모듈을 찾을 수 없습니다: {path}",
        "en": "Update module not found: {path}",
        "ja": "更新モジュールが見つかりません: {path}",
        "zh": "找不到更新模块: {path}",
    },
    "PRUNE_BACKUPS_INCOMPATIBLE": {
        "ko": "--prune-backups는 --check/--dry-run과 함께 사용할 수 없습니다.",
        "en": "--prune-backups cannot be used together with --check/--dry-run.",
        "ja": "--prune-backups は --check/--dry-run と併用できません。",
        "zh": "--prune-backups 不能与 --check/--dry-run 同时使用。",
    },
    "NO_INPUT_USE_DEFAULT": {
        "ko": "입력을 받지 못해 이번만 기본값으로 진행합니다 (다음 실행에서 다시 물어봅니다).",
        "en": "No input received; proceeding with the default this time (you'll be asked again next run).",
        "ja": "入力が得られなかったため、今回のみデフォルト値で進めます(次回実行時に再度確認します)。",
        "zh": "未收到输入，本次将使用默认值继续(下次运行会再次询问)。",
    },
    "CONFIG_SAVED": {
        "ko": "{path}에 저장했습니다. {hint}",
        "en": "Saved to {path}. {hint}",
        "ja": "{path} に保存しました。{hint}",
        "zh": "已保存到 {path}。{hint}",
    },
    "FIRST_BUILD_HEADER": {
        "ko": "처음 빌드네요 — 앞으로 기본 동작을 선택해주세요.",
        "en": "This is your first build — please choose the default behavior going forward.",
        "ja": "初回のビルドですね — 今後のデフォルト動作を選択してください。",
        "zh": "这是您的首次构建 — 请选择今后的默认行为。",
    },
    "NON_INTERACTIVE_OPTION_UNATTENDED": {
        "ko": "무인 빌드 (기본값 자동 적용, 매번 묻지 않음)",
        "en": "Unattended build (defaults applied automatically, never asks again)",
        "ja": "無人ビルド(デフォルト値を自動適用し、以後確認しません)",
        "zh": "无人值守构建(自动应用默认值，不再询问)",
    },
    "NON_INTERACTIVE_OPTION_INTERACTIVE": {
        "ko": "대화형 빌드 (버전·플랫폼을 매번 직접 선택)",
        "en": "Interactive build (choose version/platform yourself every time)",
        "ja": "対話型ビルド(毎回バージョン・プラットフォームを直接選択)",
        "zh": "交互式构建(每次手动选择版本/平台)",
    },
    "NON_INTERACTIVE_OVERRIDE_HINT": {
        "ko": "매 실행마다 --interactive 또는 --non-interactive로 재정의할 수 있습니다.",
        "en": "You can override this per run with --interactive or --non-interactive.",
        "ja": "毎回の実行時に --interactive または --non-interactive で上書きできます。",
        "zh": "每次运行时都可以通过 --interactive 或 --non-interactive 覆盖此设置。",
    },
    "OBFUSCATE_HEADER": {
        "ko": "Tauri 프런트엔드 JS 난독화를 기본으로 켤까요?",
        "en": "Enable Tauri frontend JS obfuscation by default?",
        "ja": "Tauri フロントエンドの JS 難読化をデフォルトで有効にしますか?",
        "zh": "是否默认启用 Tauri 前端 JS 混淆?",
    },
    "OBFUSCATE_OPTION_OFF": {
        "ko": "끄기 (기본값, 배포 전 필요할 때만 켜기)",
        "en": "Off (default, enable only when needed before release)",
        "ja": "オフ(デフォルト、リリース前に必要な時だけ有効化)",
        "zh": "关闭(默认，仅在发布前需要时启用)",
    },
    "OBFUSCATE_OPTION_ON": {
        "ko": "켜기 (매번 자동으로 난독화 적용)",
        "en": "On (obfuscation applied automatically every time)",
        "ja": "オン(毎回自動的に難読化を適用)",
        "zh": "开启(每次自动应用混淆)",
    },
    "OBFUSCATE_OVERRIDE_HINT": {
        "ko": "매 실행마다 --obfuscate-js 또는 --no-obfuscate-js로 재정의할 수 있습니다.",
        "en": "You can override this per run with --obfuscate-js or --no-obfuscate-js.",
        "ja": "毎回の実行時に --obfuscate-js または --no-obfuscate-js で上書きできます。",
        "zh": "每次运行时都可以通过 --obfuscate-js 或 --no-obfuscate-js 覆盖此设置。",
    },
    "PUBLISH_PROMPT_HEADER": {
        "ko": "빌드 성공 후 스토어 업로드는 어떻게 할까요?",
        "en": "How should store upload work after a successful build?",
        "ja": "ビルド成功後のストアアップロードはどうしますか?",
        "zh": "构建成功后如何处理商店上传?",
    },
    "PUBLISH_PROMPT_OPTION_NONE": {
        "ko": "안 함 (매번 ./build.sh publish 직접 실행)",
        "en": "Never (run ./build.sh publish manually each time)",
        "ja": "しない(毎回 ./build.sh publish を手動実行)",
        "zh": "不上传(每次手动运行 ./build.sh publish)",
    },
    "PUBLISH_PROMPT_OPTION_ASK": {
        "ko": "빌드 성공 시마다 업로드할지 물어봄",
        "en": "Ask whether to upload on every successful build",
        "ja": "ビルド成功のたびにアップロードするか確認する",
        "zh": "每次构建成功时询问是否上传",
    },
    "PUBLISH_PROMPT_OVERRIDE_HINT": {
        "ko": "매 실행마다 --publish 또는 --no-publish로 재정의할 수 있습니다.",
        "en": "You can override this per run with --publish or --no-publish.",
        "ja": "毎回の実行時に --publish または --no-publish で上書きできます。",
        "zh": "每次运行时都可以通过 --publish 或 --no-publish 覆盖此设置。",
    },
    "UPLOAD_CANCELLED": {
        "ko": "업로드를 취소했습니다.",
        "en": "Upload cancelled.",
        "ja": "アップロードをキャンセルしました。",
        "zh": "已取消上传。",
    },
    "PUBLISH_SUMMARY_TOTAL": {
        "ko": "발행 전체", "en": "Publish total", "ja": "発行合計", "zh": "发布总计",
    },
    "LABEL_TYPE": {"ko": "유형", "en": "TYPE", "ja": "種別", "zh": "类型"},
    "LABEL_PATH": {"ko": "경로", "en": "PATH", "ja": "パス", "zh": "路径"},
    "LABEL_CATEGORY": {"ko": "분류", "en": "CATEGORY", "ja": "カテゴリ", "zh": "类别"},
    "LABEL_CHECK": {"ko": "점검", "en": "CHECK", "ja": "チェック", "zh": "检查项"},
    "LABEL_STATUS": {"ko": "상태", "en": "STATUS", "ja": "状態", "zh": "状态"},
    "NO_PROJECTS_DETECTED": {
        "ko": "감지된 프로젝트가 없습니다.",
        "en": "No projects detected.",
        "ja": "検出されたプロジェクトがありません。",
        "zh": "未检测到项目。",
    },
    "GRAPH_LEVEL": {
        "ko": "단계 {level}", "en": "Level {level}", "ja": "段階 {level}", "zh": "层级 {level}",
    },
    "NO_PROJECTS_FOR_GRAPH": {
        "ko": "그래프로 표시할 프로젝트가 없습니다.",
        "en": "No projects to display in the graph.",
        "ja": "グラフに表示するプロジェクトがありません。",
        "zh": "没有可在图中显示的项目。",
    },
    "MCP_SERVER_ERROR": {
        "ko": "MCP 서버 오류: {error}",
        "en": "MCP server error: {error}",
        "ja": "MCP サーバーエラー: {error}",
        "zh": "MCP 服务器错误: {error}",
    },
    "AUDIT_NO_PROJECTS": {
        "ko": "감사할 프로젝트가 없습니다.",
        "en": "No projects to audit.",
        "ja": "監査するプロジェクトがありません。",
        "zh": "没有可审计的项目。",
    },
    "PLAN_NO_PROJECTS": {
        "ko": "계획할 프로젝트가 없습니다.",
        "en": "No projects to plan.",
        "ja": "計画するプロジェクトがありません。",
        "zh": "没有可规划的项目。",
    },
    "PUBLISH_JSON_UNSUPPORTED": {
        "ko": "--json은 publish 명령에서 지원하지 않습니다.",
        "en": "--json is not supported for the publish command.",
        "ja": "--json は publish コマンドではサポートされていません。",
        "zh": "publish 命令不支持 --json。",
    },
    "PROJECT_TYPE_UNDETECTED": {
        "ko": "프로젝트 타입을 감지할 수 없습니다: {path}",
        "en": "Could not detect project type: {path}",
        "ja": "プロジェクトタイプを検出できません: {path}",
        "zh": "无法检测项目类型: {path}",
    },
    "PUBLISH_NO_PROJECTS": {
        "ko": "발행할 프로젝트가 없습니다.",
        "en": "No projects to publish.",
        "ja": "発行するプロジェクトがありません。",
        "zh": "没有可发布的项目。",
    },
    "JSON_UNSUPPORTED_COMMANDS": {
        "ko": "--json은 detect, audit, plan 또는 graph 명령에서 지원합니다.",
        "en": "--json is only supported for the detect, audit, plan, or graph commands.",
        "ja": "--json は detect、audit、plan、graph コマンドでのみサポートされます。",
        "zh": "--json 仅在 detect、audit、plan 或 graph 命令中支持。",
    },
    "MONOREPO_ROOT_AUTO_BUILD": {
        "ko": "현재 폴더는 모노레포 루트로 판단했습니다. 하위 프로젝트를 자동 빌드합니다.",
        "en": "Detected the current folder as a monorepo root. Building sub-projects automatically.",
        "ja": "現在のフォルダーはモノレポのルートと判断しました。サブプロジェクトを自動ビルドします。",
        "zh": "已判断当前文件夹为 monorepo 根目录，将自动构建子项目。",
    },
    "AUDIT_FLUTTER_RELEASE_TREESHAKE": {
        "ko": "선택한 모든 출력에 release 빌드와 icon tree shaking을 적용",
        "en": "Applies release build and icon tree shaking to all selected outputs",
        "ja": "選択したすべての出力に release ビルドと icon tree shaking を適用",
        "zh": "对所有选定输出应用 release 构建和图标 tree shaking",
    },
    "AUDIT_FLUTTER_OBFUSCATE": {
        "ko": "AAB/APK/IPA에 --obfuscate와 --split-debug-info 적용",
        "en": "Applies --obfuscate and --split-debug-info to AAB/APK/IPA",
        "ja": "AAB/APK/IPA に --obfuscate と --split-debug-info を適用",
        "zh": "对 AAB/APK/IPA 应用 --obfuscate 和 --split-debug-info",
    },
    "AUDIT_FLUTTER_WEB_NOT_SUPPORTED": {
        "ko": "Flutter web은 최적화 빌드지만 Dart --obfuscate 대상이 아님",
        "en": "Flutter web is an optimized build but is not a target for Dart --obfuscate",
        "ja": "Flutter web は最適化ビルドですが、Dart --obfuscate の対象ではありません",
        "zh": "Flutter web 是优化构建，但不是 Dart --obfuscate 的适用对象",
    },
    "AUDIT_RUST_LTO_CONFIGURED": {
        "ko": "Cargo release LTO 설정 감지",
        "en": "Detected Cargo release LTO setting",
        "ja": "Cargo release の LTO 設定を検出",
        "zh": "检测到 Cargo release LTO 设置",
    },
    "AUDIT_RUST_LTO_RECOMMENDED": {
        "ko": "Cargo.toml release profile의 lto 설정을 검토",
        "en": "Review the lto setting in Cargo.toml's release profile",
        "ja": "Cargo.toml の release profile の lto 設定を確認してください",
        "zh": "请检查 Cargo.toml release profile 中的 lto 设置",
    },
    "AUDIT_RUST_STRIP_CONFIGURED": {
        "ko": "Rust strip 설정 감지",
        "en": "Detected Rust strip setting",
        "ja": "Rust の strip 設定を検出",
        "zh": "检测到 Rust strip 设置",
    },
    "AUDIT_RUST_STRIP_RECOMMENDED": {
        "ko": "배포 바이너리의 strip 설정을 검토",
        "en": "Review the strip setting for the release binary",
        "ja": "配布バイナリの strip 設定を確認してください",
        "zh": "请检查发布二进制文件的 strip 设置",
    },
    "AUDIT_FRONTEND_MINIFY_FRAMEWORK": {
        "ko": "프런트엔드 도구의 production minify/tree-shaking에 위임",
        "en": "Delegated to the frontend tool's production minify/tree-shaking",
        "ja": "フロントエンドツールの production minify/tree-shaking に委任",
        "zh": "委托给前端工具的 production minify/tree-shaking",
    },
    "AUDIT_FRONTEND_MINIFY_UNKNOWN": {
        "ko": "프런트엔드 build script의 minify 설정을 수동 확인",
        "en": "Manually verify the frontend build script's minify setting",
        "ja": "フロントエンドの build script の minify 設定を手動で確認してください",
        "zh": "请手动检查前端 build script 的 minify 设置",
    },
    "AUDIT_JS_OBFUSCATE_CONFIGURED": {
        "ko": "javascript-obfuscator 활성화 감지",
        "en": "Detected javascript-obfuscator enabled",
        "ja": "javascript-obfuscator の有効化を検出",
        "zh": "检测到已启用 javascript-obfuscator",
    },
    "AUDIT_JS_OBFUSCATE_OFF": {
        "ko": "기본 minify만 적용; 추가 JS 난독화는 꺼져 있음",
        "en": "Only default minify applied; additional JS obfuscation is off",
        "ja": "デフォルトの minify のみ適用; 追加の JS 難読化はオフ",
        "zh": "仅应用默认 minify；未启用额外的 JS 混淆",
    },
    "AUDIT_RUST_NATIVE_COMPILED": {
        "ko": "Rust는 release 네이티브 바이너리로 컴파일되며 난독화와 동일 개념은 아님",
        "en": "Rust compiles to a release native binary; this is not equivalent to obfuscation",
        "ja": "Rust は release ネイティブバイナリにコンパイルされ、難読化とは同じ概念ではありません",
        "zh": "Rust 编译为 release 原生二进制文件，这与混淆并非同一概念",
    },
    "AUDIT_ANDROID_MINIFY_CONFIGURED": {
        "ko": "release minify/R8 활성화 감지",
        "en": "Detected release minify/R8 enabled",
        "ja": "release minify/R8 の有効化を検出",
        "zh": "检测到已启用 release minify/R8",
    },
    "AUDIT_ANDROID_MINIFY_NOT_CONFIGURED": {
        "ko": "release minifyEnabled/isMinifyEnabled=true를 확인하지 못함",
        "en": "Could not confirm release minifyEnabled/isMinifyEnabled=true",
        "ja": "release minifyEnabled/isMinifyEnabled=true を確認できませんでした",
        "zh": "无法确认 release minifyEnabled/isMinifyEnabled=true",
    },
    "AUDIT_ANDROID_SHRINK_CONFIGURED": {
        "ko": "Android resource shrinking 활성화 감지",
        "en": "Detected Android resource shrinking enabled",
        "ja": "Android resource shrinking の有効化を検出",
        "zh": "检测到已启用 Android resource shrinking",
    },
    "AUDIT_ANDROID_SHRINK_NOT_CONFIGURED": {
        "ko": "release shrinkResources/isShrinkResources=true를 확인하지 못함",
        "en": "Could not confirm release shrinkResources/isShrinkResources=true",
        "ja": "release shrinkResources/isShrinkResources=true を確認できませんでした",
        "zh": "无法确认 release shrinkResources/isShrinkResources=true",
    },
    "AUDIT_ANDROID_R8_CONFIGURED": {
        "ko": "ProGuard/R8 규칙 연결 감지",
        "en": "Detected ProGuard/R8 rules linked",
        "ja": "ProGuard/R8 ルールの連携を検出",
        "zh": "检测到已关联 ProGuard/R8 规则",
    },
    "AUDIT_ANDROID_R8_NOT_CONFIGURED": {
        "ko": "ProGuard/R8 규칙 연결을 확인하지 못함",
        "en": "Could not confirm ProGuard/R8 rules are linked",
        "ja": "ProGuard/R8 ルールの連携を確認できませんでした",
        "zh": "无法确认已关联 ProGuard/R8 规则",
    },
    "AUDIT_GRADLE_RELEASE_PROJECT_SPECIFIC": {
        "ko": "기본 build task를 실행하며 최적화 수준은 Gradle 프로젝트 설정에 따름",
        "en": "Runs the default build task; the optimization level depends on the Gradle project's own settings",
        "ja": "デフォルトの build task を実行し、最適化レベルは Gradle プロジェクトの設定に依存します",
        "zh": "运行默认 build task，优化程度取决于 Gradle 项目自身设置",
    },
    "AUDIT_JVM_OBFUSCATE_CONFIGURED": {
        "ko": "축소/난독화 관련 Gradle 설정 감지",
        "en": "Detected shrink/obfuscation-related Gradle settings",
        "ja": "縮小・難読化に関する Gradle 設定を検出",
        "zh": "检测到与压缩/混淆相关的 Gradle 设置",
    },
    "AUDIT_JVM_OBFUSCATE_NOT_CONFIGURED": {
        "ko": "일반 Kotlin/JVM build는 자동 난독화를 보장하지 않음",
        "en": "A plain Kotlin/JVM build does not guarantee automatic obfuscation",
        "ja": "通常の Kotlin/JVM build は自動的な難読化を保証しません",
        "zh": "普通的 Kotlin/JVM build 不保证自动混淆",
    },
    "AUDIT_NODE_BUNDLE_FRAMEWORK": {
        "ko": "production build 도구의 minify/tree-shaking에 위임",
        "en": "Delegated to the production build tool's minify/tree-shaking",
        "ja": "production build ツールの minify/tree-shaking に委任",
        "zh": "委托给 production build 工具的 minify/tree-shaking",
    },
    "AUDIT_NODE_BUNDLE_UNKNOWN": {
        "ko": "scripts.build가 최적화 빌드인지 수동 확인",
        "en": "Manually verify whether scripts.build produces an optimized build",
        "ja": "scripts.build が最適化ビルドかどうか手動で確認してください",
        "zh": "请手动确认 scripts.build 是否为优化构建",
    },
    "AUDIT_NODE_JS_OBFUSCATE_CONFIGURED": {
        "ko": "JS 난독화 패키지 감지",
        "en": "Detected a JS obfuscation package",
        "ja": "JS 難読化パッケージを検出",
        "zh": "检测到 JS 混淆软件包",
    },
    "AUDIT_NODE_JS_OBFUSCATE_NOT_CONFIGURED": {
        "ko": "minification은 난독화 보장이 아니며 별도 난독화 설정을 확인하지 못함",
        "en": "Minification is not a guarantee of obfuscation, and no separate obfuscation setting was found",
        "ja": "minification は難読化を保証するものではなく、別途の難読化設定も確認できませんでした",
        "zh": "minification 并不等同于混淆，也未发现单独的混淆设置",
    },
    "AUDIT_XCODE_RELEASE_ARCHIVE": {
        "ko": "Release configuration으로 xcodebuild archive 실행",
        "en": "Runs xcodebuild archive with the Release configuration",
        "ja": "Release configuration で xcodebuild archive を実行",
        "zh": "使用 Release configuration 运行 xcodebuild archive",
    },
    "AUDIT_XCODE_SWIFT_OPT_CONFIGURED": {
        "ko": "Swift 최적화 레벨 감지",
        "en": "Detected Swift optimization level",
        "ja": "Swift 最適化レベルを検出",
        "zh": "检测到 Swift 优化级别",
    },
    "AUDIT_XCODE_SWIFT_OPT_DEFAULT": {
        "ko": "Release 기본값 또는 프로젝트 설정에 따름",
        "en": "Follows the Release default or the project's own settings",
        "ja": "Release のデフォルト値、またはプロジェクト設定に依存します",
        "zh": "遵循 Release 默认值或项目自身设置",
    },
    "AUDIT_XCODE_SYMBOL_STRIP_CONFIGURED": {
        "ko": "설치 제품 symbol strip 감지",
        "en": "Detected installed-product symbol strip",
        "ja": "インストール製品の symbol strip を検出",
        "zh": "检测到已对安装产物进行 symbol strip",
    },
    "AUDIT_XCODE_SYMBOL_STRIP_DEFAULT": {
        "ko": "Xcode Release 기본 strip 설정을 확인",
        "en": "Check Xcode Release's default strip setting",
        "ja": "Xcode Release のデフォルト strip 設定を確認してください",
        "zh": "请检查 Xcode Release 的默认 strip 设置",
    },
    "AUDIT_XCODE_NATIVE_COMPILED": {
        "ko": "Swift/Objective-C 네이티브 컴파일은 별도 난독화 보장이 아님",
        "en": "Swift/Objective-C native compilation does not by itself guarantee obfuscation",
        "ja": "Swift/Objective-C のネイティブコンパイルは、それ自体では難読化を保証しません",
        "zh": "Swift/Objective-C 原生编译本身并不保证混淆",
    },
    "XCODE_CONTAINER_NOT_FOUND": {
        "ko": "Xcode workspace/project를 찾을 수 없습니다: {directory}",
        "en": "Could not find an Xcode workspace/project: {directory}",
        "ja": "Xcode workspace/project が見つかりません: {directory}",
        "zh": "找不到 Xcode workspace/project: {directory}",
    },
    "XCODE_SCHEME_AUTODETECT_FAILED": {
        "ko": "Xcode scheme 자동 감지에 실패했습니다. UBS_XCODE_SCHEME을 지정하세요.",
        "en": "Failed to auto-detect the Xcode scheme. Set UBS_XCODE_SCHEME explicitly.",
        "ja": "Xcode scheme の自動検出に失敗しました。UBS_XCODE_SCHEME を指定してください。",
        "zh": "自动检测 Xcode scheme 失败。请显式设置 UBS_XCODE_SCHEME。",
    },
    "XCODE_LIST_JSON_PARSE_FAILED": {
        "ko": "xcodebuild -list JSON을 해석할 수 없습니다.",
        "en": "Could not parse xcodebuild -list JSON output.",
        "ja": "xcodebuild -list の JSON を解析できません。",
        "zh": "无法解析 xcodebuild -list 的 JSON 输出。",
    },
    "XCODE_SCHEME_NOT_FOUND": {
        "ko": "공유 Xcode scheme을 찾지 못했습니다. UBS_XCODE_SCHEME을 지정하세요.",
        "en": "Could not find a shared Xcode scheme. Set UBS_XCODE_SCHEME explicitly.",
        "ja": "共有 Xcode scheme が見つかりませんでした。UBS_XCODE_SCHEME を指定してください。",
        "zh": "找不到共享的 Xcode scheme。请显式设置 UBS_XCODE_SCHEME。",
    },
    "XCODE_SCHEME_AMBIGUOUS": {
        "ko": "Xcode scheme이 여러 개입니다: {schemes}. UBS_XCODE_SCHEME을 지정하세요.",
        "en": "Multiple Xcode schemes found: {schemes}. Set UBS_XCODE_SCHEME explicitly.",
        "ja": "複数の Xcode scheme が見つかりました: {schemes}。UBS_XCODE_SCHEME を指定してください。",
        "zh": "发现多个 Xcode scheme: {schemes}。请显式设置 UBS_XCODE_SCHEME。",
    },
    "ADAPTER_TYPE_UNSUPPORTED": {
        "ko": "Python adapter가 지원하지 않는 타입입니다: {kind}",
        "en": "Type not supported by the Python adapter: {kind}",
        "ja": "Python adapter がサポートしていないタイプです: {kind}",
        "zh": "Python adapter 不支持的类型: {kind}",
    },
    "SERVICE_ACCOUNT_FIELDS_MISSING": {
        "ko": "서비스 계정 JSON 필드가 없습니다: {missing}",
        "en": "Missing service account JSON field(s): {missing}",
        "ja": "サービスアカウント JSON のフィールドがありません: {missing}",
        "zh": "服务账号 JSON 缺少字段: {missing}",
    },
    "OPENSSL_EXEC_FAILED": {
        "ko": "openssl을 실행할 수 없습니다: {error}",
        "en": "Could not run openssl: {error}",
        "ja": "openssl を実行できません: {error}",
        "zh": "无法执行 openssl: {error}",
    },
    "JWT_SIGN_FAILED": {
        "ko": "Google JWT RSA 서명에 실패했습니다: {detail}",
        "en": "Failed to sign the Google JWT with RSA: {detail}",
        "ja": "Google JWT の RSA 署名に失敗しました: {detail}",
        "zh": "Google JWT 的 RSA 签名失败: {detail}",
    },
    "JSON_TOP_LEVEL_NOT_OBJECT": {
        "ko": "JSON 최상위 값이 객체가 아닙니다.",
        "en": "The top-level JSON value is not an object.",
        "ja": "JSON のトップレベル値がオブジェクトではありません。",
        "zh": "JSON 顶层值不是对象。",
    },
    "PRUNE_DAYS_REQUIRED": {
        "ko": "--prune-backups 일수가 필요합니다.",
        "en": "--prune-backups requires a day count.",
        "ja": "--prune-backups には日数の指定が必要です。",
        "zh": "--prune-backups 需要天数参数。",
    },
    "RETENTION_DAYS_INVALID": {
        "ko": "보존 일수는 0 이상의 정수여야 합니다.",
        "en": "Retention days must be a non-negative integer.",
        "ja": "保持日数は0以上の整数である必要があります。",
        "zh": "保留天数必须是非负整数。",
    },
    "UPDATE_ARG_UNSUPPORTED": {
        "ko": "update에서 지원하지 않는 옵션 또는 인자입니다: {value}",
        "en": "Unsupported option or argument for update: {value}",
        "ja": "update でサポートされていないオプションまたは引数です: {value}",
        "zh": "update 不支持的选项或参数: {value}",
    },
    "OPTION_VALUE_REQUIRED": {
        "ko": "{option} 값이 필요합니다.",
        "en": "{option} requires a value.",
        "ja": "{option} には値の指定が必要です。",
        "zh": "{option} 需要一个值。",
    },
    "JOBS_INVALID": {
        "ko": "--jobs는 1 이상의 정수여야 합니다.",
        "en": "--jobs must be an integer of 1 or greater.",
        "ja": "--jobs は1以上の整数である必要があります。",
        "zh": "--jobs 必须是大于等于 1 的整数。",
    },
    "OPTION_UNKNOWN": {
        "ko": "알 수 없는 옵션: {option}",
        "en": "Unknown option: {option}",
        "ja": "不明なオプションです: {option}",
        "zh": "未知选项: {option}",
    },
    "VERSION_BUMP_INVALID_VALUE": {
        "ko": "잘못된 version bump: {value}",
        "en": "Invalid version bump: {value}",
        "ja": "無効な version bump です: {value}",
        "zh": "无效的 version bump: {value}",
    },
    "FLUTTER_PLATFORM_INVALID_VALUE": {
        "ko": "잘못된 Flutter 플랫폼: {value}",
        "en": "Invalid Flutter platform: {value}",
        "ja": "無効な Flutter プラットフォームです: {value}",
        "zh": "无效的 Flutter 平台: {value}",
    },
    "FLUTTER_OUTPUTS_INVALID_VALUE": {
        "ko": "잘못된 Flutter 출력: {value}",
        "en": "Invalid Flutter output: {value}",
        "ja": "無効な Flutter 出力です: {value}",
        "zh": "无效的 Flutter 输出: {value}",
    },
    "PLAY_TRACK_INVALID_VALUE": {
        "ko": "잘못된 Google Play 트랙: {value}",
        "en": "Invalid Google Play track: {value}",
        "ja": "無効な Google Play トラックです: {value}",
        "zh": "无效的 Google Play 发布通道: {value}",
    },
    "DEPS_JSON_ERROR": {
        "ko": "ubs.dependencies.json JSON 오류: {error}",
        "en": "ubs.dependencies.json JSON error: {error}",
        "ja": "ubs.dependencies.json の JSON エラー: {error}",
        "zh": "ubs.dependencies.json JSON 错误: {error}",
    },
    "DEPS_SCHEMA_VERSION_INVALID": {
        "ko": "ubs.dependencies.json schema_version은 1이어야 합니다.",
        "en": "ubs.dependencies.json schema_version must be 1.",
        "ja": "ubs.dependencies.json の schema_version は1である必要があります。",
        "zh": "ubs.dependencies.json 的 schema_version 必须为 1。",
    },
    "DEPS_NOT_OBJECT": {
        "ko": "ubs.dependencies.json dependencies는 객체여야 합니다.",
        "en": "ubs.dependencies.json dependencies must be an object.",
        "ja": "ubs.dependencies.json の dependencies はオブジェクトである必要があります。",
        "zh": "ubs.dependencies.json 的 dependencies 必须是对象。",
    },
    "DEPS_PATH_INVALID": {
        "ko": "ubs.dependencies.json 경로는 비어 있지 않은 문자열이어야 합니다.",
        "en": "ubs.dependencies.json paths must be non-empty strings.",
        "ja": "ubs.dependencies.json のパスは空でない文字列である必要があります。",
        "zh": "ubs.dependencies.json 的路径必须是非空字符串。",
    },
    "DEPS_PATH_OUTSIDE_ROOT": {
        "ko": "의존성 경로가 루트를 벗어납니다: {relative}",
        "en": "Dependency path is outside the root: {relative}",
        "ja": "依存パスがルートの外にあります: {relative}",
        "zh": "依赖路径超出了根目录: {relative}",
    },
    "DEPS_LIST_NOT_ARRAY": {
        "ko": "의존성 목록은 배열이어야 합니다: {source}",
        "en": "Dependency list must be an array: {source}",
        "ja": "依存関係リストは配列である必要があります: {source}",
        "zh": "依赖列表必须是数组: {source}",
    },
    "NODE_PACKAGE_NAME_DUPLICATE": {
        "ko": "중복 Node package name: {name}",
        "en": "Duplicate Node package name: {name}",
        "ja": "Node package name が重複しています: {name}",
        "zh": "重复的 Node package name: {name}",
    },
    "DEPENDENCY_PROJECT_NOT_SELECTED": {
        "ko": "명시한 의존 프로젝트가 선택되지 않았거나 감지되지 않았습니다: {source} -> {target}",
        "en": "The specified dependency project was not selected or detected: {source} -> {target}",
        "ja": "指定した依存プロジェクトが選択されていないか検出されませんでした: {source} -> {target}",
        "zh": "指定的依赖项目未被选中或未被检测到: {source} -> {target}",
    },
    "DEPENDENCY_CYCLE_DETECTED": {
        "ko": "프로젝트 의존성 순환을 감지했습니다: {cycle}",
        "en": "Detected a project dependency cycle: {cycle}",
        "ja": "プロジェクトの依存関係の循環を検出しました: {cycle}",
        "zh": "检测到项目依赖循环: {cycle}",
    },
    "CHOICE_PROMPT_1_2": {
        "ko": "선택 (1-2) [1]: ",
        "en": "Choice (1-2) [1]: ",
        "ja": "選択 (1-2) [1]: ",
        "zh": "选择 (1-2) [1]: ",
    },
    "UPLOAD_NOW_PROMPT": {
        "ko": "지금 업로드할까요? (y/N) ",
        "en": "Upload now? (y/N) ",
        "ja": "今すぐアップロードしますか? (y/N) ",
        "zh": "现在上传吗？(y/N) ",
    },
    "NETWORK_ERROR": {
        "ko": "네트워크 오류 {method} {url}: {reason}",
        "en": "Network error {method} {url}: {reason}",
        "ja": "ネットワークエラー {method} {url}: {reason}",
        "zh": "网络错误 {method} {url}: {reason}",
    },
    "GOOGLE_API_JSON_PARSE_FAILED": {
        "ko": "Google API 응답 JSON을 해석할 수 없습니다: {raw}",
        "en": "Could not parse Google API response JSON: {raw}",
        "ja": "Google API レスポンスの JSON を解析できません: {raw}",
        "zh": "无法解析 Google API 响应的 JSON: {raw}",
    },
    "GOOGLE_API_RESPONSE_INVALID": {
        "ko": "Google API 응답 형식이 올바르지 않습니다.",
        "en": "Google API response format is invalid.",
        "ja": "Google API のレスポンス形式が正しくありません。",
        "zh": "Google API 响应格式无效。",
    },
    "OAUTH_TOKEN_JSON_PARSE_FAILED": {
        "ko": "OAuth token 응답 JSON을 해석할 수 없습니다: {raw}",
        "en": "Could not parse OAuth token response JSON: {raw}",
        "ja": "OAuth token レスポンスの JSON を解析できません: {raw}",
        "zh": "无法解析 OAuth token 响应的 JSON: {raw}",
    },
    "ACCESS_TOKEN_MISSING": {
        "ko": "access_token이 응답에 없습니다: {raw}",
        "en": "access_token missing from the response: {raw}",
        "ja": "レスポンスに access_token がありません: {raw}",
        "zh": "响应中缺少 access_token: {raw}",
    },
    "EDIT_ID_MISSING": {
        "ko": "editId가 응답에 없습니다: {raw}",
        "en": "editId missing from the response: {raw}",
        "ja": "レスポンスに editId がありません: {raw}",
        "zh": "响应中缺少 editId: {raw}",
    },
    "RESUMABLE_UPLOAD_LOCATION_MISSING": {
        "ko": "resumable 업로드 응답에 Location 헤더가 없습니다.",
        "en": "The resumable upload response is missing the Location header.",
        "ja": "resumable アップロードのレスポンスに Location ヘッダーがありません。",
        "zh": "resumable 上传响应中缺少 Location 头。",
    },
    "EMPTY_AAB_UPLOAD_REJECTED": {
        "ko": "빈 AAB 파일은 업로드할 수 없습니다: {artifact}",
        "en": "Cannot upload an empty AAB file: {artifact}",
        "ja": "空の AAB ファイルはアップロードできません: {artifact}",
        "zh": "无法上传空的 AAB 文件: {artifact}",
    },
    "VERSION_CODE_MISSING": {
        "ko": "업로드 응답에 versionCode가 없습니다: {uploaded}",
        "en": "versionCode missing from the upload response: {uploaded}",
        "ja": "アップロードのレスポンスに versionCode がありません: {uploaded}",
        "zh": "上传响应中缺少 versionCode: {uploaded}",
    },
    "USAGE_TEXT": {
        "ko": """Universal Build Script

사용법:
  ./build.sh                         자동 감지 + 안전한 기본값으로 무인 빌드
  ./build.sh detect [경로]           하위 프로젝트 탐색
  ./build.sh detect --json [경로]    AI/MCP용 감지 결과 JSON
  ./build.sh audit [경로]            최적화·난독화 설정 감사
  ./build.sh audit --json [경로]     AI/MCP용 감사 결과 JSON
  ./build.sh plan [경로]             읽기 전용 빌드 계획
  ./build.sh plan --json [경로]      AI/MCP용 빌드 계획 JSON
  ./build.sh graph --json [경로]     프로젝트 의존성·위상 정렬 JSON
  ./build.sh update --check [--json] 전체 런타임 업데이트 확인
  ./build.sh update --dry-run        변경 파일 미리 보기
  ./build.sh update                  검증·백업 후 안전 업데이트
  ./build.sh update --prune-backups 30  30일 지난 업데이트 백업 삭제
  ./build.sh --dry-run               실행할 빌드만 미리 확인
  ./build.sh --interactive           버전과 플랫폼을 직접 선택
  ./build.sh build --project <경로>  지정 프로젝트 빌드
  ./build.sh build --all --type TYPE 특정 타입만 빌드
  ./build.sh publish [--project PATH] [--track TRACK]  기존 스토어 산출물 업로드

주요 옵션:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android|macos
  --flutter-outputs auto|appbundle,apk,ipa,web,pkg
  --clean | --skip-clean
  --obfuscate-js | --no-obfuscate-js  Tauri 프런트엔드 JS 난독화 (첫 Tauri 빌드에서 기본값을 물어봄)
  --publish | --no-publish            빌드 성공 후 스토어 업로드 강제/비활성화
  --fail-fast
  --jobs N                            독립 프로젝트 제한 병렬 빌드
  --report-json <파일>               실제 빌드 결과 JSON 저장

지원 타입:
  tauri, flutter, android, kotlin-multiplatform, kotlin, gradle,
  react, next, node, ios-xcode
""",
        "en": """Universal Build Script

Usage:
  ./build.sh                         Auto-detect + unattended build with safe defaults
  ./build.sh detect [path]           Discover sub-projects
  ./build.sh detect --json [path]    Detection result as JSON for AI/MCP
  ./build.sh audit [path]            Audit optimization/obfuscation settings
  ./build.sh audit --json [path]     Audit result as JSON for AI/MCP
  ./build.sh plan [path]             Read-only build plan
  ./build.sh plan --json [path]      Build plan as JSON for AI/MCP
  ./build.sh graph --json [path]     Project dependency/topological-order JSON
  ./build.sh update --check [--json] Check for a full runtime update
  ./build.sh update --dry-run        Preview changed files
  ./build.sh update                  Safe update with verification and backup
  ./build.sh update --prune-backups 30  Delete update backups older than 30 days
  ./build.sh --dry-run               Preview which build would run
  ./build.sh --interactive           Choose version and platform directly
  ./build.sh build --project <path>  Build a specific project
  ./build.sh build --all --type TYPE Build only a given type
  ./build.sh publish [--project PATH] [--track TRACK]  Upload an existing store artifact

Main options:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android|macos
  --flutter-outputs auto|appbundle,apk,ipa,web,pkg
  --clean | --skip-clean
  --obfuscate-js | --no-obfuscate-js  Obfuscate the Tauri frontend JS (asked on the first Tauri build)
  --publish | --no-publish            Force/disable store upload after a successful build
  --fail-fast
  --jobs N                            Limit parallel builds of independent projects
  --report-json <file>                Save the actual build result as JSON

Supported types:
  tauri, flutter, android, kotlin-multiplatform, kotlin, gradle,
  react, next, node, ios-xcode
""",
        "ja": """Universal Build Script

使い方:
  ./build.sh                         自動検出 + 安全なデフォルトで無人ビルド
  ./build.sh detect [パス]           サブプロジェクトを検出
  ./build.sh detect --json [パス]    AI/MCP 向け検出結果 JSON
  ./build.sh audit [パス]            最適化・難読化設定を監査
  ./build.sh audit --json [パス]     AI/MCP 向け監査結果 JSON
  ./build.sh plan [パス]             読み取り専用のビルド計画
  ./build.sh plan --json [パス]      AI/MCP 向けビルド計画 JSON
  ./build.sh graph --json [パス]     プロジェクト依存関係・トポロジカル順序 JSON
  ./build.sh update --check [--json] ランタイム全体の更新を確認
  ./build.sh update --dry-run        変更されるファイルをプレビュー
  ./build.sh update                  検証・バックアップ後に安全に更新
  ./build.sh update --prune-backups 30  30日経過した更新バックアップを削除
  ./build.sh --dry-run               実行されるビルドのみプレビュー
  ./build.sh --interactive           バージョンとプラットフォームを直接選択
  ./build.sh build --project <パス>  指定プロジェクトをビルド
  ./build.sh build --all --type TYPE 指定タイプのみビルド
  ./build.sh publish [--project PATH] [--track TRACK]  既存のストア成果物をアップロード

主なオプション:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android|macos
  --flutter-outputs auto|appbundle,apk,ipa,web,pkg
  --clean | --skip-clean
  --obfuscate-js | --no-obfuscate-js  Tauri フロントエンド JS の難読化(初回 Tauri ビルドで既定値を確認)
  --publish | --no-publish            ビルド成功後のストアアップロードを強制/無効化
  --fail-fast
  --jobs N                            独立プロジェクトの並列ビルド数を制限
  --report-json <ファイル>            実際のビルド結果を JSON で保存

サポートするタイプ:
  tauri, flutter, android, kotlin-multiplatform, kotlin, gradle,
  react, next, node, ios-xcode
""",
        "zh": """Universal Build Script

用法:
  ./build.sh                         自动检测 + 使用安全默认值进行无人值守构建
  ./build.sh detect [路径]           发现子项目
  ./build.sh detect --json [路径]    以 JSON 输出检测结果(供 AI/MCP 使用)
  ./build.sh audit [路径]            审计优化/混淆设置
  ./build.sh audit --json [路径]     以 JSON 输出审计结果(供 AI/MCP 使用)
  ./build.sh plan [路径]             只读构建计划
  ./build.sh plan --json [路径]      以 JSON 输出构建计划(供 AI/MCP 使用)
  ./build.sh graph --json [路径]     项目依赖/拓扑排序 JSON
  ./build.sh update --check [--json] 检查完整运行时更新
  ./build.sh update --dry-run        预览将变更的文件
  ./build.sh update                  验证并备份后安全更新
  ./build.sh update --prune-backups 30  删除超过 30 天的更新备份
  ./build.sh --dry-run               仅预览将执行的构建
  ./build.sh --interactive           直接选择版本和平台
  ./build.sh build --project <路径>  构建指定项目
  ./build.sh build --all --type TYPE 仅构建指定类型
  ./build.sh publish [--project PATH] [--track TRACK]  上传已有的商店产物

主要选项:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android|macos
  --flutter-outputs auto|appbundle,apk,ipa,web,pkg
  --clean | --skip-clean
  --obfuscate-js | --no-obfuscate-js  混淆 Tauri 前端 JS(首次 Tauri 构建时会询问默认值)
  --publish | --no-publish            强制/禁用构建成功后的商店上传
  --fail-fast
  --jobs N                            限制独立项目的并行构建数
  --report-json <文件>               将实际构建结果保存为 JSON

支持的类型:
  tauri, flutter, android, kotlin-multiplatform, kotlin, gradle,
  react, next, node, ios-xcode
""",
    },
}
