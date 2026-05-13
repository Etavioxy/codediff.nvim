# User Goals

## 约束

1. **最小修改原则**：尽量保持对codediff.nvim源文件的最小修改，尽量新增外置文件。不要侵入性太大的改动。
2. **Universe Path Syntax**：设计用于精确定位文本范围进行比较的语法

## 开发位置

- **正确位置**：`D:\Project\bloominginthemud\codediff-universe-path\`（独立开发目录）
- **错误位置**：`AppData/Local/nvim-data/lazy/codediff.nvim/`（lazy管理，会被清理）