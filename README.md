# TypeCount

简体中文 | [English](README.en.md)

TypeCount 是一款适用于 macOS 13 及以上版本的轻量菜单栏工具，用于估算每天的打字字数。

菜单栏中只显示一个键盘图标。将鼠标悬停在图标上可查看今日总数，点击图标可查看最近 7 天的统计、暂停或恢复统计，以及查看权限状态。

## 计数规则

- 英文输入法：字母、数字、标点和空格，每次按键计为 1 个字符。
- 中文输入法：每按 2 次字母键，估算为 1 个字；数字、标点和空格，每次按键计为 1 个字符。
- 忽略 Command 和 Control 快捷键，以及 Return、Delete、Tab、方向导航键和功能键。
- 粘贴、语音输入、自动补全和删除操作不会改变总数。

TypeCount 不保存输入的字符、按键序列、应用名称或文本框内容，也不进行联网通信或遥测。

## 构建与安装

```sh
swift test
./scripts/build-app.sh
cp -R dist/TypeCount.app /Applications/
open /Applications/TypeCount.app
```

macOS 提示时，请授予 TypeCount「输入监控」权限。权限与应用的安装位置关联，因此应先安装应用，再授权。

如果已开启权限开关，TypeCount 仍显示 `Needs access`，请检查旧版本留下的权限记录：进入「系统设置 > 隐私与安全性 > 输入监控」，选中旧的 TypeCount 条目并点击减号移除，再重新添加 `/Applications/TypeCount.app`，开启权限并重新打开应用。

构建脚本会为应用进行本地临时签名，并使用固定的签名身份要求，使后续本地重新构建能够保持相同的输入监控身份。如需开机自动运行，可在系统设置中将 TypeCount 添加到「登录时打开」。

## 实现参考

本项目为独立实现，在事件监听、数据持久化和菜单栏交互方式上参考了采用 MIT 许可证的 [KeyStats](https://github.com/debugtheworldbot/keyStats) 和 [Activity Bar](https://github.com/SuveenE/activity-bar) 项目。
