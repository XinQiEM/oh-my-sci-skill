# oh-my-sci-skill

面向**学术研究与工程应用**的 GitHub Copilot Skill 库，聚焦**电磁场与电磁波技术**领域。

## 定位

本库收录的 Skill 专为以下方向提供 AI 辅助能力：

- **电磁场建模** — 物理建模、等效电路、边界条件、本构参数提取
- **电磁计算与分析** — 数值方法（FEM、FDTD、MoM、BEM）、解析解推导、模态分析、参数扫描
- **仿真优化** — 多目标优化、代理模型、自动调参、收敛判断
- **CAE / EDA 工具使用** — HFSS、CST、Feko、ADS、Cadence、Ansys、Keysight 等工具的脚本化与自动化

## Skills 目录

| Skill | 说明 |
|---|---|
| [pdf-paper-analysis](skills/pdf-paper-analysis/README.md) | 解析 PDF 文献，提炼核心算法与实现原理，输出原理分析文档和开发指导手册 |
| [ansys-help](skills/ansys-help/README.md) | 在本地 Ansys Help 路径中按关键词快速检索并返回高相关结果（软件名、模块、操作、用例、错误） |

## 适用人群

- 从事电磁场、信号完整性、天线、微波、射频、电力电子等方向的工程师与研究人员
- 需要将学术论文快速转化为可落地实现的工程文档的开发者
- 使用 HFSS、CST、Feko、ADS 等仿真工具并希望借助 AI 提升工作效率的用户

## 使用方式

在 VS Code 中安装 GitHub Copilot，将本库路径加入 Copilot Skills 配置，即可在 Copilot Chat 中通过自然语言调用对应 Skill。

详细配置方法参见各 Skill 目录下的 `README.md`。

## 贡献

欢迎提交新的 Skill 或改进现有 Skill。每个 Skill 独立存放于 `skills/<skill-name>/` 目录下，包含：

- `SKILL.md` — Skill 定义与调用逻辑（供 Copilot 读取）
- `README.md` — 面向开发者的说明文档
- `templates/`（可选）— 输出模板文件
