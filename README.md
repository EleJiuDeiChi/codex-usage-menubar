# Codex Usage

[中文](#中文) | [English](#english)

## 中文

一个原生 macOS 菜单栏应用，用来查看 Codex 使用情况。

### 功能特性

- 菜单栏显示今日 USD 花费
- 每分钟自动刷新
- 展示今日输入 / 输出 Token
- 展示最近 7 天使用趋势
- 展示主流 Codex 模型价格
- 按 `cwd` 聚合今日项目用量
- 支持登录时启动

### 截图说明

- 菜单栏标题显示 `Codex $...`
- 菜单展开后可查看今日总览、今日项目、模型价格和最近 7 天数据

### 运行要求

- macOS 13+
- 已安装 `ccusage-codex`
- 已安装 Node.js

### 本地运行

```bash
swift run CodexMenuBarApp
```

### 构建 `.app`

```bash
./scripts/build-app.sh
```

构建产物默认输出到：

```bash
dist/Codex Usage.app
```

### 安装依赖检查

```bash
ccusage-codex daily --since 2026-03-31 --until 2026-03-31 --json
```

如果应用显示 `Codex --`，通常表示日志读取、`ccusage-codex` 或 Node 环境有问题。

### 项目结构

```text
Sources/
  CodexMenuBarApp/
    App/      App 入口
    Core/     日志解析、价格查询、项目聚合
    UI/       菜单栏界面
Tests/
scripts/
resources/
```

### 说明

当前版本更适合本地自用或开发者分发。由于应用依赖本机 Codex 日志和外部 `ccusage-codex` 环境，若要上架 Mac App Store，还需要进一步做沙箱兼容改造。

## English

A native macOS menu bar app for tracking Codex usage.

### Features

- Shows today's USD cost in the menu bar
- Refreshes automatically every minute
- Displays today's input and output tokens
- Shows the last 7 days of usage
- Displays pricing for common Codex models
- Aggregates today's usage by project based on `cwd`
- Supports open at login

### Overview

- The menu bar title shows `Codex $...`
- The popover includes today's summary, project breakdown, model pricing, and a 7-day view

### Requirements

- macOS 13+
- `ccusage-codex` installed
- Node.js installed

### Run Locally

```bash
swift run CodexMenuBarApp
```

### Build A Double-Clickable App

```bash
./scripts/build-app.sh
```

The app bundle will be generated at:

```bash
dist/Codex Usage.app
```

### Verify Dependencies

```bash
ccusage-codex daily --since 2026-03-31 --until 2026-03-31 --json
```

If the app shows `Codex --`, the most likely issue is with log access, `ccusage-codex`, or the local Node.js environment.

### Project Structure

```text
Sources/
  CodexMenuBarApp/
    App/      App entry
    Core/     log parsing, pricing, project aggregation
    UI/       menu bar interface
Tests/
scripts/
resources/
```

### Notes

The current version is best suited for local use or developer distribution. To publish it on the Mac App Store, the app would need further sandbox-compatible architecture changes.
