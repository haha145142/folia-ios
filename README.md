# FoliaPlayer iOS MVP

这是一个**独立实现的 iOS 沉浸式音乐播放器原型**，以 SwiftUI + UIKit 生命周期宿主实现，最低系统 iOS 17.0，不依赖 CocoaPods 或第三方 Swift Package。它参考了 Folia 类播放器的核心体验，但不是 Folia 上游代码的完整移植。

## 当前包含的功能

- 从 iOS「文件」App 多选导入本地音频，并复制到应用的 `Documents/Media` 目录。
- AVAudioPlayer 播放、暂停、进度拖动；配置 `.playback` 音频会话、后台音频模式、锁屏 Now Playing 信息、播放/暂停/拖动远程命令。
- 导入 UTF-8 编码 LRC 歌词，解析多时间戳和 `[offset:...]`，全屏滚动高亮歌词。
- 三种动态渐变主题、歌词字号设置，并将偏好保存到 UserDefaults。
- Navidrome/Subsonic 兼容 API：`ping.view` 登录测试、`getAlbumList2.view` 专辑列表读取。
- iTunes 文件共享相关 Info.plist 设置；可在文件共享中查看应用 Documents 内容。
- GitHub Actions 在 `macos-15` 上使用 Xcode 16.x 进行手动签名归档、导出 Ad Hoc IPA 并上传 Artifact。

## 目录结构

```text
FoliaPlayer-iOS/
├── .github/
│   └── workflows/
│       └── build-ipa.yml                 # GitHub Actions 手动签名 IPA 流程（YAML）
├── FoliaPlayer.xcodeproj/
│   ├── project.pbxproj                   # Xcode 项目定义（PBX）
│   └── xcshareddata/xcschemes/
│       └── FoliaPlayer.xcscheme          # 共享 Scheme（XML）
├── FoliaPlayer/
│   ├── AppDelegate.swift                 # UIKit App 入口 / Swift
│   ├── SceneDelegate.swift               # UIWindow 与 SwiftUI 宿主 / Swift
│   ├── Info.plist                        # 后台音频、文件共享、Scene 配置 / XML plist
│   ├── Models/
│   │   ├── Track.swift                   # 曲目模型 / Swift
│   │   └── LyricLine.swift               # 歌词行模型 / Swift
│   ├── Services/
│   │   ├── LRCParser.swift               # LRC 解析 / Swift
│   │   └── NavidromeClient.swift         # Subsonic 兼容 API / Swift
│   ├── ViewModels/
│   │   ├── PlayerViewModel.swift         # 曲库、播放与远程控制 / Swift
│   │   └── NavidromeViewModel.swift      # Navidrome 页面状态 / Swift
│   └── Views/
│       ├── FoliaRootView.swift           # Tab 入口 / SwiftUI
│       ├── LibraryView.swift             # 本地曲库与迷你播放器 / SwiftUI
│       ├── FullscreenLyricsView.swift    # 动态全屏歌词 / SwiftUI
│       ├── SettingsView.swift            # 主题与字号设置 / SwiftUI
│       ├── NavidromeView.swift           # Navidrome 连接与专辑列表 / SwiftUI
│       └── PlayerSettings.swift          # 主题设置模型 / Swift
├── ExportOptions.plist.template          # 导出选项模板（运行时填入团队/Bundle/Profile）
├── .gitignore
└── README.md
```

## Xcode 工程设置

- Scheme：`FoliaPlayer`
- Target：`FoliaPlayer`
- 最低 iOS：`17.0`
- Bundle ID 模板：`com.xxx.folia`。实际签名前必须换成 Apple Developer 账号中已注册的显式 App ID。
- 后台音频 Info.plist：`UIBackgroundModes` 包含 `audio`。
- 文件共享 Info.plist：`UIFileSharingEnabled = YES`、`LSSupportsOpeningDocumentsInPlace = YES`。

在 Xcode 中也可以打开 Target → **Signing & Capabilities** → `+ Capability` → **Background Modes**，勾选 **Audio, AirPlay, and Picture in Picture**（至少勾选 Audio）。`UIBackgroundModes` 已经在 Info.plist 中配置。不要把证书、私钥、描述文件或密码提交到仓库。

## GitHub Actions 配置

进入 GitHub 仓库 **Settings → Secrets and variables → Actions**。本工作流会从 mobileprovision 自动读取 Team ID、Bundle ID 和描述文件类型，因此不用手动填写 Repository Variables。

### Repository Secrets（机密）

| Secret | 内容 |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | 带私钥的 Apple Distribution `.p12` 文件的单行 Base64 内容 |
| `P12_PASSWORD` | 导出该 `.p12` 时设置的密码 |
| `PROVISIONING_PROFILE_BASE64` | 与 Team ID、Bundle ID、Apple Distribution 证书匹配的 Ad Hoc `.mobileprovision` 单行 Base64 内容 |
| `KEYCHAIN_PASSWORD` | GitHub Actions 临时 keychain 的自定义密码；设置为一段强随机值，不需要等于 P12 密码 |

工作流会根据描述文件自动选择 `development` 或 `ad-hoc` 导出方式。描述文件必须是带明确 App ID 的 iOS Development 或 Ad Hoc 类型；Ad Hoc 描述文件必须包含你准备安装 IPA 的 iPhone/iPad UDID。App Store 分发描述文件不适用于这条个人设备安装流程。

### 如何从 Mac 生成 Base64

先在 macOS「钥匙串访问」中导出 **Apple Distribution 证书及其私钥**为 `.p12`，然后把生成的内容粘贴到对应 GitHub Secret。下面命令会把 Base64 结果直接复制到剪贴板，不会把密码写入命令：

```bash
# 证书：替换成实际 p12 路径；执行后粘贴到 BUILD_CERTIFICATE_BASE64
base64 -i "$HOME/Desktop/AppleDistribution.p12" | tr -d '\n' | pbcopy

# 描述文件：替换成实际 mobileprovision 路径；执行后粘贴到 PROVISIONING_PROFILE_BASE64
base64 -i "$HOME/Downloads/Folia_AdHoc.mobileprovision" | tr -d '\n' | pbcopy
```

每条命令执行后，分别去 GitHub Secret 输入框粘贴。不要将 Base64 内容提交到仓库，也不要把 `.p12` 或 `.mobileprovision` 上传为公开 Release 附件。

Linux 上如需生成 Base64，可以使用 `base64 -w 0 文件路径`；macOS 自带的 `base64` 没有 `-w 0` 参数，因此上面使用 `tr -d '\n'`。

## 编译流程

1. 将本目录里的全部文件上传到 GitHub 仓库根目录，并确保默认分支为 `main`。
2. 设置上述 2 个 Variables 和 4 个 Secrets。
3. 打开仓库 **Actions → Build FoliaPlayer IPA → Run workflow**，或推送对项目/工作流的更改到 `main`。
4. 任务成功后，打开本次 workflow run 页面，在 **Artifacts** 中下载 `FoliaPlayer-IPA`，解压即可取得 `.ipa`。

工作流会从 provisioning profile 自动读取 UUID、名称、Team ID、App ID 和导出方式；创建一次性 keychain、导入证书、安装描述文件，然后 Archive 与 Export IPA。它会校验 profile 是否为明确的 App ID，并要求 Development/Ad Hoc 描述文件带有已注册设备。

## 本地构建

在装有 Xcode 16.x 的 Mac 上：

```bash
open FoliaPlayer.xcodeproj
```

选择 `FoliaPlayer` scheme 和 iOS Simulator 可先做不签名预览；真机归档需要填写你的 Team ID、Bundle ID 和匹配的签名配置。GitHub workflow 使用 Release + Manual signing，并从 Actions Variables 覆盖 Bundle ID/Team ID。

## 当前限制

- Navidrome 目前支持连通性测试和读取专辑标题，不包含远程音频流播放、封面加载或凭据持久化。
- LRC 导入目前按 UTF-8 读取；部分简体中文旧编码歌词需要先转为 UTF-8。
- 暂无网易云音乐搜索、AI 主题生成、模组系统、歌词在线匹配和完整播放队列。
- 项目文件和 workflow 已生成，但此执行环境不是 macOS/Xcode 环境，无法在这里实际运行 `xcodebuild archive` 或验证签名；首次 GitHub Actions 运行的结果才是实际云编译验证。
