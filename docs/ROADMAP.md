# MusicKeyBoard - 开发路线图 (Roadmap)

## Phase 1: 核心骨架 ✅ MVP

**目标**: 最小可用原型——按键出声

### 里程碑 1.1: 项目初始化
- [x] 创建 Xcode 项目（SwiftUI, macOS 14+）
- [x] 配置 Swift Package Manager 依赖（MidiParser）
- [x] 添加 GeneralUser GS SoundFont 到 Bundle（需用户手动下载）

### 里程碑 1.2: 音频引擎
- [x] 实现 `SoundFontPlayer`（单采样器，加载 SF2，播放/停止音符）
- [x] 实现 `MultiSamplerPlayer`（多采样器预加载，零延迟切换）
- [x] 实现低延迟缓冲区设置（256 帧）

### 里程碑 1.3: 键盘输入
- [x] 实现 `NSEvent.addLocalMonitorForEvents` 本地监听
- [x] 实现默认钢琴键位映射（DAW 标准布局）
- [x] 按键防重复处理

### 里程碑 1.4: 基础 UI
- [x] 虚拟键盘可视化（显示按键与音符对应关系）
- [x] 乐器选择下拉框
- [x] 演奏模式切换（顺序/映射）

---

## Phase 2: 乐谱系统

**目标**: 支持导入和解析多种乐谱格式

### 里程碑 2.1: 统一数据模型
- [x] 定义 `MusicNote` 结构体（MIDI 音符、时值、力度、休止符）
- [x] 定义乐谱容器 `Score` 类型

### 里程碑 2.2: 简谱解析器
- [x] 实现 `JianpuParser`（1-7 音阶、升降号、八度、时值、连音线）
- [x] 支持调式设置（C/D/E/F/G/A/B 调）
- [x] 简谱文本输入框 UI

### 里程碑 2.3: MusicXML 解析器
- [x] 实现 `MusicXMLParser`（XMLParser 委托模式）
- [x] 解析 pitch（step/octave/alter）、duration、divisions、tempo
- [x] 文件导入 UI

### 里程碑 2.4: MIDI 文件解析
- [x] 集成 MidiParser 库
- [x] 实现 MIDI → MusicNote 转换
- [x] 文件导入 UI

---

## Phase 3: 全局监听与增强体验

**目标**: 后台演奏、设置持久化

### 里程碑 3.1: 全局键盘监听
- [x] 实现 `GlobalKeyboardMonitor`（CGEventTap）
- [x] 权限检测与引导（输入监控权限）
- [x] 超时保护自动重连

### 里程碑 3.2: 设置与持久化
- [x] 键位映射导入/导出（JSON）
- [x] 用户偏好存储（UserDefaults / @AppStorage）
- [x] 设置面板 UI

---

## Phase 4: 打磨与发布（未来）

**目标**: 用户体验优化、App Store 上架准备

### 里程碑 4.1: UI 打磨
- [ ] 按键动画效果（按下高亮、松开恢复）
- [ ] 乐谱进度可视化（当前音符高亮）
- [ ] 深色/浅色模式适配

### 里程碑 4.2: 高级功能
- [ ] 自动播放模式（按节拍自动演奏乐谱）
- [ ] 多音轨支持
- [ ] 和弦模式（一键触发和弦）

### 里程碑 4.3: 发布准备
- [ ] App 图标设计
- [ ] App Sandbox 配置
- [ ] App Store 审核准备
- [ ] 用户文档

---

## 技术架构图

```
┌──────────────────────────────────────────────┐
│                  SwiftUI Views               │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ KeyBoard │ │ ScoreView│ │SettingsView  │  │
│  │  View    │ │          │ │              │  │
│  └──────────┘ └──────────┘ └──────────────┘  │
├──────────────────────────────────────────────┤
│              AppState (@Observable)           │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │KeyMap   │ │Score     │ │PlaybackState │  │
│  │Manager  │ │Manager   │ │              │  │
│  └─────────┘ └──────────┘ └──────────────┘  │
├──────────────────────────────────────────────┤
│  ┌──────────────┐    ┌────────────────────┐  │
│  │ Audio Engine  │    │  Input Monitor     │  │
│  │ MultiSampler │    │  Local / Global    │  │
│  │  Player      │    │  KeyboardMonitor   │  │
│  └──────────────┘    └────────────────────┘  │
├──────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ Jianpu   │ │MusicXML  │ │  MIDI        │  │
│  │ Parser   │ │ Parser   │ │  Parser      │  │
│  └──────────┘ └──────────┘ └──────────────┘  │
├──────────────────────────────────────────────┤
│          AVAudioEngine + SoundFont (SF2)     │
└──────────────────────────────────────────────┘
```

## 文件结构

```
MusicKeyBoard/
├── Package.swift                    # SPM 依赖配置
├── MusicKeyBoard/
│   ├── App/
│   │   ├── MusicKeyBoardApp.swift   # @main 入口
│   │   └── AppState.swift           # 核心状态管理
│   ├── Audio/
│   │   ├── SoundFontPlayer.swift    # 单采样器播放
│   │   └── MultiSamplerPlayer.swift # 多采样器引擎
│   ├── Input/
│   │   ├── GlobalKeyboardMonitor.swift  # CGEventTap 全局监听
│   │   ├── KeyMapping.swift         # 键位映射定义
│   │   └── PermissionManager.swift  # 权限管理
│   ├── Parser/
│   │   ├── MusicNote.swift          # 统一音符模型
│   │   ├── JianpuParser.swift       # 简谱解析
│   │   ├── MusicXMLParser.swift     # MusicXML 解析
│   │   └── MIDIFileParser.swift     # MIDI 文件解析
│   ├── Views/
│   │   ├── ContentView.swift        # 主界面
│   │   ├── KeyboardView.swift       # 虚拟键盘
│   │   ├── ScoreInputView.swift     # 乐谱输入
│   │   └── SettingsView.swift       # 设置面板
│   └── Resources/
│       └── (GeneralUser GS.sf2)     # 用户手动下载放入
├── docs/
│   ├── PRD.md
│   └── ROADMAP.md
└── README.md
```
