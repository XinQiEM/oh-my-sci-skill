# Ansys Help Search Skill

这个 skill 用于在本地 Ansys Help 文档中进行快速关键词检索，并返回高相关度结果。

适用于电磁场与电磁波相关工程场景，特别是 HFSS、Q3D、Maxwell 等工具的文档查询。

## 能解决的问题

支持以下关键词类型：

- 软件名：HFSS、Q3D、Maxwell、Icepak、SIwave 等
- 功能模块：建模、网格、求解、后处理、并行计算
- 使用方法：导圆角、剖分设置、材料设置、端口/边界条件、S 参数、方向图
- 用例名：微带天线、过孔、变压器、母排等
- 具体问题：Error、Warning、求解失败、收敛问题

## 输入要求

必填：

1. `help_path`：本地 Ansys Help 路径（文件夹或文件）
2. `query`：关键词（一个或多个）

可选：

- `top_k`：返回条数（默认 10）
- `file_filter`：按产品或文档子集过滤
- `version_hint`：版本提示（如 2024R1）

## 支持的文档类型

优先支持：

- HTML/HTM 帮助目录
- TXT/MD/XML/LOG 文本
- PDF 手册

条件支持：

- CHM 文档（需要先解包再检索）

## 返回结果格式

结果会以结构化方式输出：

1. 搜索摘要：路径、关键词、扫描类型、命中总数
2. Top 命中：文件位置、片段、相关性说明
3. 下一步建议：如何进一步缩小范围或提高命中质量

## 可直接执行脚本（PowerShell）

脚本位置：`skills/ansys-help/scripts/search-ansys-help.ps1`

### 基本用法

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\ansys-help\scripts\search-ansys-help.ps1 \
	-HelpPath "D:\AnsysHelp" \
	-Query "HFSS","wave port","S参数" \
	-TopK 10
```

### 常用参数

- `-HelpPath`：帮助文档根目录或单个文档路径（必填）
- `-Query`：关键词数组（必填）
- `-TopK`：返回结果数量（默认 10）
- `-FileFilter`：路径关键字过滤（例如 `HFSS`）
- `-VersionHint`：版本提示（例如 `2024R1`）
- `-AsJson`：以 JSON 输出，便于二次处理

### JSON 输出示例

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\ansys-help\scripts\search-ansys-help.ps1 \
	-HelpPath "D:\AnsysHelp" \
	-Query "Maxwell","error","matrix is singular" \
	-TopK 5 \
	-AsJson
```

说明：脚本会直接检索 HTML/HTM/TXT/MD/XML/LOG。若目录内仅有 CHM/PDF，脚本会给出提示，建议先解包 CHM 或将 PDF 转成可检索文本。

## 使用示例

- 在 `D:\AnsysHelp\` 里查 HFSS 里 wave port 的设置方法
- 搜索 Q3D 中过孔建模和网格剖分建议
- 在 Maxwell 文档中查 error: matrix is singular
- 查微带天线 S 参数和方向图后处理流程

## 目录结构

```text
.github/skills/ansys-help/
├── SKILL.md
├── README.md
└── scripts/
	└── search-ansys-help.ps1
```

## 质量要求

- 必须基于用户给定路径返回可追溯结果
- 不输出臆造文档内容
- 优先给出高相关、可操作的片段
- 无命中时明确说明并给出改进关键词建议
