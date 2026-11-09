# StayAwake

macOS 菜单栏小工具：运行期间防止 Mac 睡眠，显示器照常熄灭，网络不断。思路来自 [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake)。

用 Go + 少量 Objective-C（cgo）编写，只支持 macOS 13 及以上（含 macOS 27），不需要 Xcode。

## 用法

- 打开 App 即开启：菜单栏出现信号天线图标，系统不会因闲置而睡眠
- 左键点击图标：开启 / 关闭（关闭时图标变灰，系统恢复正常睡眠）
- 右键（或 Control+点击）› 退出（⌘Q）；App 崩溃时系统也会自动恢复正常睡眠
- 显示器仍按“系统设置 › 锁定屏幕 › 不活跃时关闭显示器”熄灭

原理：向系统申请 `PreventUserIdleSystemSleep` 电源断言，等同于 `caffeinate -i`。可用 `pmset -g assertions | grep StayAwake` 查看。

合上 MacBook 盖子、手动选择“睡眠”时仍会睡眠，这是 macOS 的限制。

## 构建

需要 Go 和 Xcode Command Line Tools（`xcode-select --install`）。

```sh
./build.sh          # 生成 StayAwake.app
open StayAwake.app
swift icons/make-icons.swift   # 修改图标后重新生成 icons/icon.png
```
