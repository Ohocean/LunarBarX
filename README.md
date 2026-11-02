# LunarBarX

状态栏时钟美化插件，面向 **Relaxin（RootHide）+ iOS 17.0** 越狱环境。

功能：把状态栏时间改成「周二 20:00 · 09/08 七月廿四」的样式，支持农历、公历日期、星期，以及**双行布局**（时间一行、农历日期一行）。

> 参考项目：[Tappy](https://github.com/b4db1r3/Tappy)（MIT，状态栏时钟 hook 方式）、[Atria-iOS17](https://github.com/s-gdn/Atria-iOS17)（CI 编译链路）。

## 目录结构

```
LunarBarX/
├── Makefile                     # Theos 构建配置（arm64 + arm64e）
├── control                      # deb 包信息
├── Tweak.x                      # 插件源码（Logos hook）
├── lunarbarx.example.plist      # 配置文件示例
└── .github/workflows/build.yml  # 云端编译：rootless + roothide 两个包
```

## 一、云端编译（Windows 上不用装任何东西）

1. 把整个 `LunarBarX` 文件夹上传到你自己的 GitHub 仓库（新建仓库 → Upload files，或用 git 推送）。
2. 打开仓库的 **Actions** 标签页，启用 workflow（首次会提示 `I understand...`，点确认）。
3. push 到 main 或手动 Run workflow，等 3~5 分钟。
4. 在该次运行的 **Artifacts** 里下载 `LunarBarX-deb`，解压得到两个包：
   - **`LunarBarX.roothide.deb` ← Relaxin 用这个**
   - `LunarBarX.rootless.deb`（Dopamine 等普通 rootless 越狱用）

## 二、安装（iPhone 上操作）

前提：Relaxin 越狱后已装好 **ElleKit + PreferenceLoader + RootHide Patcher**。

1. 把 `LunarBarX.roothide.deb` 传到手机（AirDrop / 微信文件 / iCloud 均可）。
2. 用 **Filza** 打开这个 deb → 点右上角 Install。
3. 完成后点 **Restart SpringBoard（注销）**。
4. 看状态栏时间是否变化。

卸载：Sileo → 已安装 → LunarBarX → 卸载，注销即可完全恢复原状。

## 三、配置

用 Filza 在 `/var/mobile/Library/Preferences/` 下创建 `com.local.lunarbarx.plist`
（可以直接复制本目录的 `lunarbarx.example.plist` 过去），改完注销生效。

| 键 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `Enabled` | Bool | YES | 总开关 |
| `TwoLine` | Bool | NO | YES=双行布局（时间上移，下方一行农历日期）；NO=单行合并 |
| `ShowLunar` | Bool | YES | 显示农历（含闰月标注） |
| `ShowDate` | Bool | YES | 显示 MM/dd |
| `ShowWeekday` | Bool | NO | 时间前加「周二」等 |
| `TimeFormat` | String | `HH:mm` | 时间格式（Unicode 日期格式） |
| `BottomFontSize` | Real | 8 | 第二行字号 |
| `BottomOffsetY` | Real | 0 | 第二行 y 偏移微调（负数上移） |
| `DebugLog` | Bool | NO | 输出调试日志到 syslog |

双行布局是实验性功能：状态栏在灵动岛旁空间有限，如果第二行被裁剪或与灵动岛重叠，用 `BottomOffsetY` 微调，或把 `BottomFontSize` 调小。

## 四、故障排查

- **装完注销后没变化**：确认装的是 `roothide` 包而不是 `rootless` 包；确认 ElleKit 和 RootHide Patcher 已安装。
- **弹安全模式**：Filza 卸载本插件即可恢复，然后把现象（什么操作后弹的）反馈给我。
- **时间变了但没有农历**：把 `DebugLog` 设为 YES 注销，告诉我 SpringBoard 日志里 `[LunarBarX]` 开头的内容。
- **只对桌面/锁屏生效，App 内状态栏没变**：v0.1 只注入 SpringBoard 进程，属于预期行为，后续版本可以改为全进程注入。

## 五、已知限制（v0.1）

- 未在真机上验证 iOS 17.0 的 `_UIStatusBarStringView._setText:` hook（Tappy 验证过 iOS 14–16，17 上有概率失效）——这正是把本插件作为 P0 的原因：**它同时是注入链路的探针**。如失效，源码里换 hook 点成本很低。
- 双行布局的第二行位置是按灵动岛机型估算的，需要真机微调。
- 暂无设置面板（PreferenceLoader UI），配置走 plist，v0.2 再加。
