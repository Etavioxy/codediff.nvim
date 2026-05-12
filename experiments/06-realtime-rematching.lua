-- Experiment 06: Realtime Rematching
-- 验证文件改动后重新匹配机制
--
-- 问题：
-- - 监听文件改动事件（TextChanged, BufWritePost）
-- - 缓存失效策略
-- - 重新匹配时机

local M = {}

M.cache = {}

function M.match_and_cache(bufnr, start_delim, end_delim, index)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local nesting = 0
  local count = 0
  local start_line = nil
  local end_line = nil

  for i, line in ipairs(lines) do
    for j = 1, #line do
      local char = line:sub(j, j)
      if char == start_delim then
        if nesting == 0 then
          count = count + 1
          if count == index + 1 then
            start_line = i
          end
        end
        nesting = nesting + 1
      elseif char == end_delim then
        nesting = nesting - 1
        if nesting == 0 and start_line then
          end_line = i
          break
        end
      end
    end
    if end_line then break end
  end

  local key = string.format("%d:%s:%s:%d", bufnr, start_delim, end_delim, index)
  M.cache[key] = {
    start_line = start_line,
    end_line = end_line,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
  }

  return start_line, end_line
end

function M.cache_valid(bufnr, start_delim, end_delim, index)
  local key = string.format("%d:%s:%s:%d", bufnr, start_delim, end_delim, index)
  local cached = M.cache[key]
  if not cached then return false end
  local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  return cached.changedtick == current_tick
end

function M.get_match(bufnr, start_delim, end_delim, index)
  if M.cache_valid(bufnr, start_delim, end_delim, index) then
    local key = string.format("%d:%s:%s:%d", bufnr, start_delim, end_delim, index)
    local cached = M.cache[key]
    return cached.start_line, cached.end_line, true
  else
    local s, e = M.match_and_cache(bufnr, start_delim, end_delim, index)
    return s, e, false
  end
end

local function run_test()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = {
    "function first() {",
    "}",
    "function second() {",
    "}",
  }
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  print("=== 初始匹配测试 ===")
  local s1, e1, cached1 = M.get_match(bufnr, "{", "}", 0)
  print(string.format("[0] 行%d-%d, 缓存=%s", s1 or 0, e1 or 0, cached1))

  local s2, e2, cached2 = M.get_match(bufnr, "{", "}", 1)
  print(string.format("[1] 行%d-%d, 缓存=%s", s2 or 0, e2 or 0, cached2))

  print("\n=== 缓存有效性测试 ===")
  local valid1 = M.cache_valid(bufnr, "{", "}", 0)
  print(string.format("缓存[0]有效: %s", valid1))

  print("\n=== 修改文件后缓存失效测试 ===")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    "function new_first() {",
    "  // added line",
    "}",
    "function second() {",
    "}",
  })

  local valid2 = M.cache_valid(bufnr, "{", "}", 0)
  print(string.format("修改后缓存[0]有效: %s (期望: false)", valid2))

  local s3, e3, cached3 = M.get_match(bufnr, "{", "}", 0)
  print(string.format("重新匹配[0] 行%d-%d (期望: 1-3), 缓存=%s (期望: false)", s3 or 0, e3 or 0, cached3))

  local s4, e4, cached4 = M.get_match(bufnr, "{", "}", 0)
  print(string.format("再次获取[0] 行%d-%d, 缓存=%s (期望: true)", s4 or 0, e4 or 0, cached4))

  print("\n=== 验证结果 ===")
  local pass = true

  if s1 ~= 1 or e1 ~= 2 then pass = false; print("FAIL: 初始[0]应为1-2") end
  if s2 ~= 3 or e2 ~= 4 then pass = false; print("FAIL: 初始[1]应为3-4") end
  if valid1 ~= true then pass = false; print("FAIL: 初始缓存应有效") end
  if valid2 ~= false then pass = false; print("FAIL: 修改后缓存应失效") end
  if s3 ~= 1 or e3 ~= 3 then pass = false; print("FAIL: 重新匹配[0]应为1-3") end
  if cached3 ~= false then pass = false; print("FAIL: 重新匹配不应命中缓存") end
  if cached4 ~= true then pass = false; print("FAIL: 再次获取应命中缓存") end

  if pass then
    print("PASS: 实时重新匹配机制正确")
  end

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

run_test()

return M