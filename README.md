# MusicKeyBoard

macOS 原生键盘音乐应用 —— 用电脑键盘演奏各种乐器。

## 功能特性

- **键盘演奏**: 用 QWERTY 键盘模拟钢琴键盘（DAW 标准布局）
- **多音色支持**: 预加载多种 General MIDI 乐器，切换零延迟
- **低延迟音频**: AVAudioEngine + 256 帧缓冲，按键到出声 < 15ms
- **多种乐谱格式**: 支持简谱（Jianpu）、MusicXML、MIDI 文件导入
- **两种演奏模式**:
  - **映射模式**: 每个键对应固定音符（钢琴键盘布局）
  - **顺序模式**: 每按一键播放乐谱中的下一个音
- **全局键盘监听**: 可选后台演奏（需 Input Monitoring 权限）

## 系统要求

- macOS 14.0 (Sonoma) 或更高
- Xcode 15.0+
- Swift 5.9+

## 快速开始

### 1. 下载 SoundFont 音色库

从 [GeneralUser GS](https://github.com/mrbumpy409/GeneralUser-GS) 下载 `GeneralUser GS.sf2` 文件（约 30MB），放入 `MusicKeyBoard/Resources/` 目录。

### 2. 在 Xcode 中打开

```bash
# 方式一：用 Xcode 打开 Package.swift
open Package.swift

# 方式二：创建 Xcode 项目
# 在 Xcode 中选择 File > New > Project > macOS > App
# 将 MusicKeyBoard/ 目录下的源文件拖入项目
```

**推荐**: 在 Xcode 中新建一个 macOS App 项目（SwiftUI, Swift），然后将 `MusicKeyBoard/` 下的所有 `.swift` 文件添加到项目中，并将 SoundFont 文件添加到 Bundle Resources。

### 3. 配置项目

- **Target**: macOS 14.0+
- **Info.plist**: 添加 `NSInputMonitoringUsageDescription`（如需全局监听）
- **Bundle Resources**: 确保 `GeneralUser GS.sf2` 包含在 app bundle 中

### 4. 构建运行

在 Xcode 中按 `Cmd+R` 运行。

## 键位布局

```
  数字行:  2  3     5  6  7        ← 低八度黑键
  QWERTY: W  E     T  Y  U        ← 高八度黑键
  Home行: A  S  D  F  G  H  J  K  L  ← 高八度白键 (C4-D5)
  Z行:    Z  X  C  V  B  N  M     ← 低八度白键 (C3-B3)
```

## 简谱语法

```
1-7: do re mi fa sol la ti
0:   休止符
':   升一个八度
,:   降一个八度
_:   时值减半
-:   延长一拍
#:   升半音（放在数字前）
b:   降半音（放在数字前）

示例（小星星）: 1 1 5 5 6 6 5 - 4 4 3 3 2 2 1 -
```

## 项目结构

```
MusicKeyBoard/
├── App/                  # 应用入口和状态管理
├── Audio/                # 音频引擎（AVAudioEngine + SoundFont）
├── Input/                # 键盘输入监听（本地 + 全局）
├── Parser/               # 乐谱解析器（简谱、MusicXML、MIDI）
├── Views/                # SwiftUI 界面
└── Resources/            # 音色库文件（需手动下载）
```

## 技术栈

- **SwiftUI** + **@Observable** 状态管理
- **AVAudioEngine** + **AVAudioUnitSampler** 音频播放
- **CGEventTap** 全局键盘监听
- **XMLParser** MusicXML 解析
- **AudioToolbox** MIDI 文件解析
- 零第三方音频库依赖

## 文档

- [产品需求文档 (PRD)](docs/PRD.md)
- [开发路线图 (Roadmap)](docs/ROADMAP.md)

## 许可

MIT License
