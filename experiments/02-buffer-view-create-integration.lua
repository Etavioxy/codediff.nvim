-- Experiment 02: Buffer View Create Integration
-- 验证buffer填充后能否调用codediff.view.create渲染diff
--
-- 问题：整个流程串联点
-- - 创建buffer并填充文本片段
-- - 调用codediff.ui.view.create()渲染diff
-- - 确认codediff内部机制是否正常工作

-- 运行方式：nvim -l experiments/02-buffer-view-create-integration.lua

-- Setup runtimepath to find codediff module
local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = package.path .. ";" .. cwd .. "/lua/?.lua;" .. cwd .. "/lua/?/init.lua"

-- Load plugin files
vim.cmd('runtime! plugin/*.lua plugin/*.vim')

local function run_experiment()
  -- 1. 初始化codediff
  require("codediff").setup()

  -- 2. 准备两段文本片段（模拟从定位器提取）
  local original_lines = {
    "function foo() {",
    "  return 1;",
    "}",
  }

  local modified_lines = {
    "function foo() {",
    "  return 2;  -- changed",
    "}",
  }

  -- 3. 创建buffer并填充内容
  local orig_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(orig_buf, 0, -1, false, original_lines)
  vim.api.nvim_buf_set_name(orig_buf, "original.lua")

  local mod_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(mod_buf, 0, -1, false, modified_lines)
  vim.api.nvim_buf_set_name(mod_buf, "modified.lua")

  print("Created buffers:", orig_buf, mod_buf)

  -- 4. 尝试调用view.create
  local view = require("codediff.ui.view")
  print("view module functions:", vim.inspect(vim.tbl_keys(view)))

  local session_config = {
    mode = "standalone",
    original_path = "original.lua",
    modified_path = "modified.lua",
  }

  -- 5. 调用view.create
  local ok, result = pcall(view.create, session_config, "lua")
  if not ok then
    print("ERROR: view.create failed:", result)
    return false
  end

  print("view.create returned:", vim.inspect(result))

  -- 6. 检查是否创建了tab和diff窗口
  local tabnr = vim.fn.tabpagenr()
  print("Current tab:", tabnr)
  print("Tab count:", vim.fn.tabpagenr("$"))

  local wins = vim.api.nvim_tabpage_list_wins(tabnr)
  print("Windows in tab:", #wins)
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    print("  Win", win, "-> Buf", buf, ":", name)
  end

  return true
end

local success = run_experiment()
print("\n=== Experiment Result ===")
print(success and "PASS: buffer-view-create integration works" or "FAIL: check error above")

-- 清理：关闭所有tab
while vim.fn.tabpagenr("$") > 1 do
  vim.cmd("tabclose")
end

return success