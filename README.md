# Stremio Web → iOS 未签名 IPA(自签安装,最低支持 iOS 15.0)

把开源的 [Stremio/stremio-web](https://github.com/Stremio/stremio-web)(官方 Web 前端)打包成一个轻量 iOS 壳 App(WKWebView + 自定义协议),由 **GitHub Actions 云端编译**——你本机不需要安装 Xcode。产物是**未签名 IPA**,用你自己的 Apple ID 自签后即可安装,最低系统 **iOS 15.0**(你的 15.6 可用)。

## 目录结构

```
.github/workflows/build-ipa.yml   # CI:macOS 云主机上克隆 stremio-web → 构建 → 编译壳 → 产出 IPA
scripts/build-web.sh              # 克隆并生产构建 stremio-web(关闭 Service Worker)
scripts/build-ipa.sh              # swiftc 编译壳(arm64, iOS 15.0)+ 组装未签名 IPA
shell/SchemeHandler.swift         # 自定义协议:把内置 web 资源以 stremio://localhost/ 提供
shell/AppDelegate.swift           # App 入口 + 外部链接/外部播放器跳转处理
shell/Info.plist                  # 包名/图标/最低系统/横屏等声明
shell/icons/AppIcon60x60@2x.png   # App 图标(官方素材合成)
.nvmrc                            # CI 使用的 Node 版本(22)
```

## 构建步骤(约 15 分钟)

1. **解压本包**,得到上面这些文件。
2. 在 GitHub 上 **New repository**(建议 Public——公有仓库的 Actions 免费且不限 macOS 时长;Private 也可以,消耗免费分钟数配额)。不要勾选 "Add a README"。
3. 把文件传上去,两种方式任选:
   - **网页上传**:仓库页 `uploading an existing file`,把解压出的全部内容拖进去。⚠️ 必须包含隐藏文件夹 `.github`(macOS 按 `Cmd+Shift+.` 显示隐藏文件),否则 CI 不会出现。
   - **git 推送**:
     ```bash
     cd 解压目录
     git init && git add -A && git commit -m "stremio ios build"
     git branch -M main
     git remote add origin https://github.com/<你的用户名>/<仓库名>.git
     git push -u origin main
     ```
4. 打开仓库的 **Actions** 页 → 左侧选 **Build Stremio iOS IPA** → **Run workflow**(想换 stremio-web 版本就在输入框填分支或 tag,默认 `development`)→ 运行。
5. 跑完后在该次运行页底部 **Artifacts** 下载 `Stremio-web-iOS15-unsigned-ipa`,**解压得到 .ipa**(artifact 本身是个 zip)。

## 自签安装(你本机)

IPA 是未签名的,任选一种自签方式:

| 方式 | 证书 | 有效期 | 说明 |
| --- | --- | --- | --- |
| Sideloadly(sideloadly.io)/ AltStore | 免费 Apple ID | 7 天,到期需连电脑重签 | 每台设备免费证书限 3 个 App |
| 个人开发者账号($99/年) | 付费 | 12 个月 | 同样用上述工具签 |
| 爱思助手 / 其他工具 + 证书 | 购买的证书 | 视证书 | 直接选 ipa 签名安装 |

签名时工具会自动改写 Bundle ID(`com.stremio.web.selfhost`)并替换签名;装上后首次打开如果提示不受信任,到 设置 → 通用 → VPN 与设备管理 里信任你的开发者证书。

## 能力与限制(如实说明)

- **能力与 web.stremio.com 同级**:登录 Stremio 账号、库同步、目录/插件、字幕、Chromecast 由网页逻辑决定。
- **种子流(torrent)需要 Streaming Server**:iOS 上没有内置服务器,默认会提示 "Streaming server is not available"。两种解决方式:
  1. 在 App 内 **设置 → Streaming** 添加你自架的 stremio-service / Stremio Server 地址(家里常开的电脑或 NAS);
  2. 构建前把地址写进 `web/server-url.txt`(一行,http/https),启动时会自动添加并选中该服务器(改完需重新跑一次 CI 并重签)。
- **直链视频(http/https)**:在 设置 里把 **Play in external player** 改为 **VLC** 或 **Outplayer**(手机上先装好对应播放器)。壳已实现把 `vlc://` 等自定义 scheme 转交给系统打开。
- **iOS 15/16 的 WKWebView 不支持 MSE**(网页内 HLS.js 播放不可用),iOS 17.1+ 才原生支持——在 15.6 上请用外部播放器播放。
- 官方 stremio-web 更新后,重新跑一次 workflow 即得到新包(改 `stremio_web_ref` 可固定版本)。
- stremio-web 为 GPL-2.0 开源;自用无需处理,若对外分发请遵守其许可证。

## 常见问题

- **Actions 里没有这个 workflow** → 检查 `.github/workflows/build-ipa.yml` 是否真的传上去了(隐藏文件夹)。
- **构建失败** → 打开该次运行看红色步骤的日志;最常见是网络拉取失败,直接 Re-run 即可。
- **Sideloadly 签名报错** → 让工具自动改 Bundle ID;或换 AltStore / 爱思助手重试。
- **装上后白屏** → 首次启动需要联网加载远端 API;确认手机网络正常后重启 App。
