local table = require 'table'

-----------------------------------------------------------------------------
-- Maps each entry of a table "t{i=v}" to a local function "f(v)".
--
-- @param   t
-- @param   f
-- @return  table
-----------------------------------------------------------------------------
local function map(t, f)
  local mapped = {}

  for _, value in ipairs(t) do
    table.insert(mapped, f(value))
  end

  return mapped
end

-----------------------------------------------------------------------------
-- Sanitizes text before conversion.
--
-- @param   text
-- @return  text
-----------------------------------------------------------------------------
local function sanitize(text)
  if not text or not text:len() then
    return text
  end

  text = text:gsub('\r\n', '\n')
  text = text:gsub('\r', '\n')
  text = text:gsub('\n[ \t\n]*\n', '\n\n')

  text = text:gsub('\t', '    ')
  text = text:gsub(' +  $', '  ')

  if not text:match('^\n.*') then
    text = '\n' .. text
  end

  return text
end

-----------------------------------------------------------------------------
-- Splits text to table of lines.
--
-- @param   text
-- @return  lines
-----------------------------------------------------------------------------
local function split(text)
  local lines = {}
  local pos = 1

  while true do
    local left, right = text:find('\n', pos)

    if not left then
      table.insert(lines, text:sub(pos))
      break
    end

    table.insert(lines, text:sub(pos, left - 1))
    pos = right + 1
  end

  return lines
end

-----------------------------------------------------------------------------
-- Returns initializer function.
--
-- @return  function
-----------------------------------------------------------------------------
return function()
  return map, sanitize, split
end
