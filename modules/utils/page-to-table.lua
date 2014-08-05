local string = require('string')
local io = require('io')
local table = require('table')

local markdown = require('../markdown/markdown')
local memoize = require('./memoize')

local replace = string.gsub

local function trim(str, what)
  if what == nil then
    what = '%s+'
  end
  str = replace(str, '^' .. what, '')
  str = replace(str, what .. '$', '')
  return str
end

local function readAll(fname)
  local f = io.open(fname, "rb")
  local flines = io.lines(fname)
  local lines = {}
  for line in flines do
    lines[#lines + 1] = line
  end
  local results = {
    content = f:read("*all"),
    lines = lines,
    lineCount = table.getn(lines)
  }
  -- local content = f:read("*all")
  f:close()
  return results
end

markdown = memoize(markdown)

local function getMeta(file)
  -- start a table
  local metaTable = {}
  local match = string.match

  -- print all line numbers and their contents
  for k,v in pairs(file.lines) do
    -- ignore first and last lines
    if k ~= 1 and k ~= file.lineCount then
      -- stop when we reach the end of the comment block
      if v ~= "-->" then
        local key = match(v, '(%a+):')
        local value = match(v, ':%s*(.+)')
        -- matches Key: Value
        if key ~= nil and value ~= nil then
          -- metaTable[string.lower(string.match(v, '(%a+):'))] = string.match(v, ':%s*(.+)')
          metaTable[string.lower(key)] = value
        end
      else
        break
      end
    end
  end
  return metaTable
end

getMeta = memoize(getMeta)

return function(filename, render)
  local file = readAll(filename)

  local meta = getMeta(file)
  -- make sure there is a template set
  if meta.template == nil then
    meta.template = "index"
  end
  if meta.title == nil then
    error("No Title set in the markdown file.")
  end

  if render then
    -- strips out comments
    local remaining = replace(file.content, "<!%-%-(.-)%-%->", '')
    -- get rid of the new lines we created when stripping the meta info
    remaining = trim(remaining, "\n\n\n")

    -- finds the end of the top comment
    -- local topComment = string.find(file.content, '\n%-%->', 0) + 3
    -- print out the stripped top comment
    -- local topCommentStripped = string.sub(file.content, 0, topComment)
    -- p('Top Comment:', topCommentStripped)

    -- give me the markdown
    meta.content = markdown(remaining)
  end

  return meta
end