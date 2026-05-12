# Universe Path Experiments

## 实验列表

| 编号 | 实验名称 | 描述 |
|------|----------|------|
| 01-nested-bracket-matching | 贪心vs嵌套匹配算法验证 | 验证两种匹配模式差异 |
| 02-buffer-view-create-integration | buffer填充后调用codediff.view.create渲染diff | 整个流程串联点，最关键 |
| 03-index-semantic-validation | 嵌套{}下索引正确性及倒序[-N]反向扫描 | 两个测试环境：正常+失配 |
| 04-buffer-preparation-bypass | 绕过prepare_buffer直接填充buffer | codediff.nvim内部流程兼容性 |
| 05-virtual-buffer-naming-scheme | buffer命名方案影响filetype高亮 | 文本片段buffer如何命名 |
| 06-realtime-rematching | 文件改动后重新匹配机制 | 缓存失效策略和重新匹配时机 |
| 07-buffer-writeback | buffer保存时写回原文件 | 写回前检测变动、写回后重新定位 |