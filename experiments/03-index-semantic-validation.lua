-- Experiment 03: Index Semantic Validation
-- 验证嵌套{}下索引正确性及倒序[-N]反向扫描
--
-- 测试环境：
-- 1. 正常环境：括号匹配正常，验证正向/倒序索引
-- 2. 失配环境：括号失配，验证错误检测

-- 运行方式：nvim -l experiments/03-index-semantic-validation.lua

local M = {}

--- 嵌套匹配（带失配检测）
---@param lines string[]
---@param start_delim string
---@param end_delim string
---@param index number
---@return number|nil start_line, number|nil end_line, string|nil error
function M.nested_match(lines, start_delim, end_delim, index)
  index = index or 0
  local count = 0
  local nesting = 0
  local start_line = nil
  local first_unclosed = nil

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
        first_unclosed = first_unclosed or { line = i, col = j }
        nesting = nesting + 1
      elseif char == end_delim then
        nesting = nesting - 1
        if nesting < 0 then
          return nil, nil, "unmatched closing delimiter at line " .. i
        end
        if nesting == 0 then
          first_unclosed = nil
          if start_line then
            return start_line, i, nil
          end
        end
      end
    end
  end

  if nesting > 0 then
    return nil, nil, "unclosed delimiter starting at line " .. (first_unclosed and first_unclosed.line or "?")
  end

  return nil, nil, "index out of range"
end

--- 反向扫描：从文件末尾开始找第N个块（-1表示最后一个）
function M.reverse_nested_match(lines, start_delim, end_delim, reverse_index)
  local target_index = reverse_index * -1
  local blocks = {}
  local nesting = 0
  local current_start = nil
  local current_start_line = nil

  for i, line in ipairs(lines) do
    for j = 1, #line do
      local char = line:sub(j, j)
      if char == start_delim then
        if nesting == 0 then
          current_start_line = i
          current_start = #blocks + 1
        end
        nesting = nesting + 1
      elseif char == end_delim then
        nesting = nesting - 1
        if nesting == 0 and current_start_line then
          blocks[current_start] = { start_line = current_start_line, end_line = i }
          current_start_line = nil
        end
      end
    end
  end

  if target_index > #blocks then
    return nil, nil
  end

  local block = blocks[#blocks - target_index + 1]
  return block and block.start_line, block and block.end_line
end

-- ============================================
-- 测试环境1：正常环境
-- ============================================

print("============================================")
print("测试环境1：正常环境")
print("============================================")

local test_code = {
  "function first() {     -- 1",
  "  // first block",
  "}                      -- 3",
  "function second() {    -- 4",
  "  function inner() {   -- 5",
  "  }                    -- 6",
  "}                      -- 7",
  "function third() {     -- 8",
  "}                      -- 9",
}

print("\n=== 正向索引测试 ===")
local s1, e1, err1 = M.nested_match(test_code, "{", "}", 0)
print(string.format("[0] 第1个块: 行%d-%d (期望: 1-3)", s1 or 0, e1 or 0))

local s2, e2, err2 = M.nested_match(test_code, "{", "}", 1)
print(string.format("[1] 第2个块: 行%d-%d (期望: 4-7)", s2 or 0, e2 or 0))

local s3, e3, err3 = M.nested_match(test_code, "{", "}", 2)
print(string.format("[2] 第3个块: 行%d-%d (期望: 8-9)", s3 or 0, e3 or 0))

print("\n=== 倒序索引测试 ===")
local s4, e4 = M.reverse_nested_match(test_code, "{", "}", -1)
print(string.format("[-1] 最后一个块: 行%d-%d (期望: 8-9)", s4 or 0, e4 or 0))

local s5, e5 = M.reverse_nested_match(test_code, "{", "}", -2)
print(string.format("[-2] 倒数第二个块: 行%d-%d (期望: 4-7)", s5 or 0, e5 or 0))

local s6, e6 = M.reverse_nested_match(test_code, "{", "}", -3)
print(string.format("[-3] 倒数第三个块: 行%d-%d (期望: 1-3)", s6 or 0, e6 or 0))

print("\n=== 验证结果 ===")
local pass = true

if s1 ~= 1 or e1 ~= 3 then pass = false; print("FAIL: [0] 不匹配") end
if s2 ~= 4 or e2 ~= 7 then pass = false; print("FAIL: [1] 不匹配") end
if s3 ~= 8 or e3 ~= 9 then pass = false; print("FAIL: [2] 不匹配") end
if s4 ~= 8 or e4 ~= 9 then pass = false; print("FAIL: [-1] 不匹配") end
if s5 ~= 4 or e5 ~= 7 then pass = false; print("FAIL: [-2] 不匹配") end
if s6 ~= 1 or e6 ~= 3 then pass = false; print("FAIL: [-3] 不匹配") end

if pass then
  print("PASS: 所有索引测试通过")
end

-- ============================================
-- 测试环境2：失配环境
-- ============================================

print("\n============================================")
print("测试环境2：失配环境")
print("============================================")

print("\n=== 未闭合 { 测试 ===")
local unclosed_code = {
  "function foo() {",
  "  function inner() {",
  "}",
}
local u1, u2, err4 = M.nested_match(unclosed_code, "{", "}", 0)
print(string.format("结果: 行%d-%d, 错误: %s", u1 or 0, u2 or 0, err4 or "nil"))

print("\n=== 多余 } 测试 ===")
local extra_close_code = {
  "}",
  "function foo() {",
  "}",
}
local e1, e2, err5 = M.nested_match(extra_close_code, "{", "}", 0)
print(string.format("结果: 行%d-%d, 错误: %s", e1 or 0, e2 or 0, err5 or "nil"))

print("\n=== 验证失配检测 ===")
if err4 == nil then print("FAIL: 未闭合应报错") end
if err5 == nil then print("FAIL: 多余}应报错") end

if err4 and err5 then
  print("PASS: 失配检测正确")
end

return M