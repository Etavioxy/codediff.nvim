-- Experiment 07: Buffer Writeback
-- 验证buffer保存时写回原文件流程
--
-- 设计：
-- - 编辑阶段：buffer作为区间内容的临时编辑空间
-- - 保存触发：检查原文件是否变动
--   - 有变动 → 报错，不写回
--   - 无变动 → 写回，重新定位区间

local M = {}

M.file_state = {}

function M.record_state(bufnr)
  M.file_state[bufnr] = {
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
  }
end

function M.file_changed(bufnr)
  local recorded = M.file_state[bufnr]
  if not recorded then return true end

  local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  if current_tick ~= recorded.changedtick then
    return true
  end

  local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #current_lines ~= #recorded.lines then return true end
  for i, line in ipairs(current_lines) do
    if line ~= recorded.lines[i] then return true end
  end

  return false
end

function M.extract_range(source_bufnr, start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(source_bufnr, start_line - 1, end_line, false)
  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(new_buf, "range:" .. source_bufnr .. ":" .. start_line .. "-" .. end_line)

  vim.api.nvim_buf_set_var(new_buf, "universe_path_source", source_bufnr)
  vim.api.nvim_buf_set_var(new_buf, "universe_path_start", start_line)
  vim.api.nvim_buf_set_var(new_buf, "universe_path_end", end_line)

  return new_buf
end

function M.writeback(range_bufnr)
  local source_bufnr = vim.api.nvim_buf_get_var(range_bufnr, "universe_path_source")
  local start_line = vim.api.nvim_buf_get_var(range_bufnr, "universe_path_start")
  local end_line = vim.api.nvim_buf_get_var(range_bufnr, "universe_path_end")

  if M.file_changed(source_bufnr) then
    return false, "source file has changed since extraction"
  end

  local new_lines = vim.api.nvim_buf_get_lines(range_bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(source_bufnr, start_line - 1, end_line, false, new_lines)

  M.record_state(source_bufnr)

  local new_end_line = start_line + #new_lines - 1
  vim.api.nvim_buf_set_var(range_bufnr, "universe_path_end", new_end_line)

  return true, nil
end

local function run_test()
  print("=== 创建原文件 ===")
  local source_buf = vim.api.nvim_create_buf(false, true)
  local source_lines = {
    "function first() {",
    "  return 1;",
    "}",
    "function second() {",
    "  return 2;",
    "}",
  }
  vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, source_lines)
  vim.api.nvim_buf_set_name(source_buf, "source.lua")
  M.record_state(source_buf)
  print("原文件buffer:", source_buf)

  print("\n=== 提取区间（行1-3）到新buffer ===")
  local range_buf = M.extract_range(source_buf, 1, 3)
  local range_lines = vim.api.nvim_buf_get_lines(range_buf, 0, -1, false)
  print("区间buffer:", range_buf)
  print("区间内容:", vim.inspect(range_lines))

  print("\n=== 修改区间buffer ===")
  local modified_lines = {
    "function first() {",
    "  return 100;  -- modified",
    "  console.log('added');",
    "}",
  }
  vim.api.nvim_buf_set_lines(range_buf, 0, -1, false, modified_lines)
  print("修改后内容:", vim.inspect(vim.api.nvim_buf_get_lines(range_buf, 0, -1, false)))

  print("\n=== 测试1：原文件无变动，写回成功 ===")
  local ok1, err1 = M.writeback(range_buf)
  print("写回结果:", ok1, err1 or "成功")
  local source_after = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  print("原文件内容:", vim.inspect(source_after))

  print("\n=== 测试2：原文件有变动，写回失败 ===")
  M.record_state(source_buf)
  local range_buf2 = M.extract_range(source_buf, 4, 6)

  vim.api.nvim_buf_set_lines(source_buf, 0, 0, false, { "// external modification" })

  local ok2, err2 = M.writeback(range_buf2)
  print("写回结果:", ok2, "错误:", err2 or "nil")

  print("\n=== 验证结果 ===")
  local pass = true

  if not ok1 then pass = false; print("FAIL: 测试1应成功") end
  if source_after[2] ~= "  return 100;  -- modified" then pass = false; print("FAIL: 写回内容不匹配") end
  if ok2 then pass = false; print("FAIL: 测试2应失败（原文件有变动）") end
  if err2 ~= "source file has changed since extraction" then pass = false; print("FAIL: 错误信息不匹配") end

  if pass then
    print("PASS: buffer写回流程正确")
  end

  vim.api.nvim_buf_delete(source_buf, { force = true })
  vim.api.nvim_buf_delete(range_buf, { force = true })
  vim.api.nvim_buf_delete(range_buf2, { force = true })
end

run_test()

return M