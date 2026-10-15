# FoliaPlayer iOS MVP

这是一个独立实现的 iOS 音乐播放器原型，使用 SwiftUI + UIKit，最低系统版本为 iOS 17.0；不是 Folia 上游项目的完整移植。

## 当前功能

- 从 iPhone「文件」App 导入本地音频。
- 播放、暂停、进度控制、后台音频和锁屏播放控制。
- 导入 LRC 歌词并全屏滚动高亮。
- 多种渐变主题、歌词字号设置。
- Navidrome/Subsonic 兼容 API 的连接测试和专辑列表读取。
- iTunes 文件共享相关设置。

## 生成未签名 IPA

仓库已配置 GitHub Actions 自动构建，不需要配置 Apple 证书、.p12、.mobileprovision 或 GitHub Secrets。

1. 打开仓库的 [Actions 页面](https://github.com/haha145142/folia-ios/actions)。
2. 选择 **Build unsigned FoliaPlayer IPA**。
3. 点击 **Run workflow** 并再次点击确认运行。
4. 构建成功后，打开最新一次运行记录，在 **Artifacts** 中下载 **FoliaPlayer-unsigned-IPA**。
5. 在 iPhone 上下载并解压 artifact ZIP，取得里面的 **FoliaPlayer-unsigned.ipa**，再用你的签名工具导入签名。

提交到 main 的播放器源文件、工程文件、README 或工作流更新，也会自动触发构建。

## 签名说明

生成的 IPA **没有代码签名，也不包含描述文件**，不能直接安装到 iPhone。它是交给你已有签名工具处理的安装包素材。签名工具需要使用你自己的有效证书和与应用 Bundle ID 匹配的描述文件；部分工具可在签名时替换 Bundle ID，若提示 App ID 不匹配，需要在签名工具中按你原有描述文件的 App ID 配置。

当前工程中的默认 Bundle ID 是 **com.xxx.folia**，属于占位值；它不是你 Apple 开发者账户中的真实 App ID。

## 本地构建

需要安装 Xcode 的 Mac。在仓库根目录打开 FoliaPlayer.xcodeproj，选择 FoliaPlayer scheme。真机安装前仍需使用有效证书和 provisioning profile 进行签名。

## 当前限制

- Navidrome 目前支持连通性测试和读取专辑标题，不包含远程音频流播放、封面加载或凭据持久化。
- LRC 导入目前按 UTF-8 读取。
- 暂无网易云音乐搜索、AI 主题生成、歌词在线匹配和完整播放队列。
