# FoliaPlayer iOS

这是 FoliaPlayer iOS MVP 的 GitHub 仓库。首次运行 `Build FoliaPlayer IPA` 工作流时，会从临时源代码包还原完整的 Xcode 工程、清理临时包文件，并把真实项目文件提交到 `main`，然后继续执行签名和 IPA 编译。

首次编译前，请在仓库 Settings → Secrets and variables → Actions 设置 README 中列出的 2 个 Variables 和 4 个 Secrets。Ad Hoc 签名必须使用匹配 Bundle ID、Team ID、证书的描述文件，并包含要安装的 iPhone UDID。
