-- Experiment 01: Nested Bracket Matching
-- 验证嵌套括号匹配算法 vs 贪心匹配
--
-- 问题：如何区分两种匹配模式
-- - 贪心匹配(|)：找第一个开始标记，找下一个结束标记（不计数）
-- - 嵌套匹配(=)：找第一个开始标记，通过nesting计数找到对应结束标记

local M = {}

--- 贪心匹配：找第一个start，然后找下一个end（不计数）
---@param lines string[] 文件内容
---@param start_delim string 开始标记
---@param end_delim string 结束标记
---@param index number 第N个开始标记（0-based）
---@return number|nil start_line, number|nil end_line
function M.greedy_match(lines, start_delim, end_delim, index)
  index = index or 0
  local count = 0

  -- 找第N个开始标记
  local start_line = nil
  for i, line in ipairs(lines) do
    local pos = line:find(start_delim, 1, true)
    if pos then
      count = count + 1
      if count == index + 1 then
        start_line = i
        break
      end
    end
  end

  if not start_line then
    return nil, nil
  end

  -- 找下一个结束标记（从start_line开始）
  local end_line = nil
  for i = start_line, #lines do
    local pos = lines[i]:find(end_delim, 1, true)
    if pos then
      end_line = i
      break
    end
  end

  return start_line, end_line
end

--- 嵌套匹配：通过nesting计数找到对应结束标记
---@param lines string[] 文件内容
---@param start_delim string 开始标记（单字符）
---@param end_delim string 结束标记（单字符）
---@param index number 第N个开始标记（0-based）
---@return number|nil start_line, number|nil end_line
function M.nested_match(lines, start_delim, end_delim, index)
  index = index or 0
  local count = 0
  local nesting = 0

  -- 找第N个开始标记，同时记录位置
  local start_line = nil
  local start_col = nil

  for i, line in ipairs(lines) do
    for j = 1, #line do
      local char = line:sub(j, j)
      if char == start_delim then
        if nesting == 0 then
          count = count + 1
          if count == index + 1 then
            start_line = i
            start_col = j
          end
        end
        nesting = nesting + 1
      elseif char == end_delim then
        nesting = nesting - 1
        if nesting == 0 and start_line then
          return start_line, i
        end
      end
    end
  end

  return start_line, nil
end

-- 测试代码
local test_code = {
  "function outer() {       // 1",
  "  function inner() {     // 2",
  "  }                      // 3",
  "}                        // 4",
  "function other() {       // 5",
  "}                        // 6",
}

print("=== 贪心匹配测试 ===")
local s1, e1 = M.greedy_match(test_code, "{", "}", 0)
print(string.format("第1个{贪心匹配: 行%d 到 行%d", s1 or 0, e1 or 0))

local s2, e2 = M.greedy_match(test_code, "{", "}", 1)
print(string.format("第2个{贪心匹配: 行%d 到 行%d", s2 or 0, e2 or 0))

print("\n=== 嵌套匹配测试 ===")
local s3, e3 = M.nested_match(test_code, "{", "}", 0)
print(string.format("第1个{嵌套匹配: 行%d 到 行%d", s3 or 0, e3 or 0))

local s4, e4 = M.nested_match(test_code, "{", "}", 1)
print(string.format("第2个{嵌套匹配: 行%d 到 行%d", s4 or 0, e4 or 0))

print("\n=== 同一行多个括号测试 ===")
local same_line_code = {
  "let obj = { a: { b: 1 }, c: { d: 2 } };",
}

local s5, e5 = M.greedy_match(same_line_code, "{", "}", 0)
print(string.format("贪心匹配: 行%d 到 行%d", s5 or 0, e5 or 0))

local s6, e6 = M.nested_match(same_line_code, "{", "}", 0)
print(string.format("嵌套匹配: 行%d 到 行%d", s6 or 0, e6 or 0))

return M