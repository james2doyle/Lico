local table = require 'table'

-- import utility functions
local map, sanitize, split = require('./markdown/util.lua')()

-- protected line storage
local protected = {}

-----------------------------------------------------------------------------
-- Classifies a line to a Markdown type.
--
-- @param   line
-- @return  line
-----------------------------------------------------------------------------
local function classify(line)
  -- rule detection helper
  local function is_rule(line)
    for _,c in ipairs({'*', '-', '_'}) do
      if line:match('^ ? ? ?%' .. c .. '[ %' .. c .. ']') and
         line:gsub('[^ %' .. c .. ']', ''):len() == line:len() then
        return true
      end
    end

    return false
  end

  -- protected lines
  if protected[line] then
    return {
      type = 'raw',
      text = line
    }
  end

  -- blank
  if line == '' then
    return {type = 'blank'}
  end

  -- rules
  if line:match('^[%=]+$') then
    return {
      type  = 'rule_header',
      level = 1
    }
  end

  if line:match('^[%-]+$') then
    return {
      type  = 'rule_header',
      level = 2
    }
  end

  if is_rule(line) then
    return {type = 'rule'}
  end

  -- headers
  local h_level, h_text = line:match('^(#+) *(.-) *#* *$')
  if h_level and 1 <= h_level:len() and h_level:len() <= 6 and h_text then
    return {
      type       = 'header',
      level      = h_level:len(),
      text       = h_text,
      unmodified = line
    }
  end

  -- lists
  local ol_text = line:match('^ ? ? ?%d+%. +(.+)')
  if ol_text then
    return {
      type       = 'list',
      style      = 'numeric',
      text       = ol_text,
      unmodified = line
    }
  end

  local ul_text = line:match('^ ? ? ?[%*%+%-] +(.+)')
  if ul_text then
    return {
      type       = 'list',
      style      = 'bullet',
      text       = ul_text,
      unmodified = line
    }
  end

  -- blockquotes
  local bq_text = line:match('^> ?(.*)$')
  if bq_text then
    return {
      type = 'blockquote',
      text = bq_text
    }
  end

  -- codeblocks
  local cb_text = line:match('^    (.*)$')
  if cb_text then
    return {
      type = 'codeblock',
      text = cb_text
    }
  end

  -- line breaks
  local br_text = line:match('^.*  $')
  if br_text then
    return {
      type = 'linebreak',
      text = br_text
    }
  end

  -- regular lines
  return {
    type = 'regular',
    text = line
  }
end

-----------------------------------------------------------------------------
-- Converts Markdown emphasis in a line to corresponding HTML tags.
--
-- @param   line
-- @return  line
-----------------------------------------------------------------------------
local function emphasize(line)
  if line.type == 'blank' or line.type == 'raw' or not line.text then
    return line
  end

  emphasis = {
    strong = {'%*%*', '%_%_'},
    em     = {'%*', '%_'}
  }

  for _, strong in ipairs(emphasis.strong) do
    local patterns = {
      strong .. '([^%s][%*%_]?)' .. strong,
      strong .. '([^%s][^<>]-[^%s][%*%_]?)' .. strong
    }

    for _, pattern in ipairs(patterns) do
      line.text = line.text:gsub(pattern, '<strong>%1</strong>')
    end
  end

  for _, em in ipairs(emphasis.em) do
    local patterns = {
      em .. '([^%s_])' .. em,
      em .. '(<strong>[^%s_]</strong>)' .. em,
      em .. '([^%s][^<>_]-[^%s])' .. em,
      em .. '([^<>_]-<strong>[^<>_]-</strong>[^<>_]-)' .. em
    }

    for _, pattern in ipairs(patterns) do
      line.text = line.text:gsub(pattern, '<em>%1</em>')
    end
  end

  return line
end

-----------------------------------------------------------------------------
-- Converts table of Markdown lines to table of HTML lines.
--
-- @param   lines
-- @return  lines
-----------------------------------------------------------------------------
local function htmlize(lines)
  local htmlized = {}
  local formats = {
    blockquote_start   = '<blockquote>\n%s',
    blockquote_end     = '%s\n</blockquote>',
    codeblock_start    = '<pre><code>%s',
    codeblock_end      = '%s\n</code></pre>',
    header             = '<h%u>%s</h%u>',
    list_numeric_start = '<ol>',
    list_numeric_end   = '</ol>',
    list_bullet_start  = '<ul>',
    list_bullet_end    = '</ul>',
    list_item          = '<li>%s</li>',
    linebreak          = '%s<br />',
    paragraph_start    = '<p>%s',
    paragraph_end      = '%s</p>',
    rule               = '<hr />'
  }

  -- list tag helper
  local function list_line(index, line)
    local elements = {}
    local prev_line = lines[index-1]
    local cur_line  = lines[index]
    local next_line = lines[index+1]

    if not prev_line or
       prev_line.type ~= cur_line.type or
       prev_line.style ~= cur_line.style then
      table.insert(elements, formats['list_' .. cur_line.style .. '_start'])
    end

    table.insert(elements, formats.list_item:format(line))

    if not next_line or
       next_line.type ~= cur_line.type or
       next_line.style ~= cur_line.style then
      table.insert(elements, formats['list_' .. cur_line.style .. '_end'])
    end

    return elements
  end

  -- paragraph tag helper
  local function paragraph_line(index, line)
    local paragraphs = {
      linebreak  = 1,
      regular    = 1
    }

    local prev_line = lines[index-1]
    local cur_line  = lines[index]
    local next_line = lines[index+1]

    if not prev_line or not (paragraphs)[prev_line.type] then
      line = formats.paragraph_start:format(line)
    end

    if cur_line.type == 'linebreak' and
       next_line and ((paragraphs)[next_line.type] or 'blockquote' == next_line.type) then
      line = formats.linebreak:format(line)
    elseif not next_line or
           not (paragraphs)[next_line.type] or
           (lines[index+2] and 'rule_header' == lines[index+2].type) then
      line = formats.paragraph_end:format(line)
    end

    return line
  end

  -- blockquote tag helper
  local function blockquote_line(index, line)
    if 0 == line:len() then
      return ''
    end

    local paragraphs = {
      blockquote = 1,
      linebreak  = 1,
      regular    = 1
    }

    local prev_line = lines[index-1]
    local cur_line  = lines[index]
    local next_line = lines[index+1]

    if line:match('^.*  $') then
      lines[index].type = 'linebreak'
    end

    line = paragraph_line(index, line)

    if not prev_line or not (paragraphs)[prev_line.type] then
      line = formats.blockquote_start:format(line)
    end

    if next_line and (paragraphs)[next_line.type] then
      lines[index+1].type = 'blockquote'
    end

    if not next_line or next_line.type ~= 'blockquote' then
      line = formats.blockquote_end:format(line)
    end

    return line
  end

  -- codeblock tag helper
  local function codeblock_line(index, line)
    local prev_line = lines[index-1]
    local cur_line  = lines[index]
    local next_line = lines[index+1]

    if not(prev_line) or prev_line.type ~= 'codeblock' then
      line = formats.codeblock_start:format(line)
    end

    if not(next_line) or next_line.type ~= 'codeblock' then
      line = formats.codeblock_end:format(line)
    end

    return line
  end

  -- convert lines to html
  for index, line in ipairs(lines) do
    -- header_rule detection
    if lines[index+1] and lines[index+1].type == 'rule_header' then
      line.type  = 'header'
      line.level = lines[index+1].level

      if line.unmodified then
        line.text = line.unmodified
      end
    end

    -- rules
    if line.type == 'rule' then
      table.insert(htmlized, formats.rule)
    end

    -- header
    if line.type == 'header' then
      table.insert(
        htmlized,
        formats.header:format(line.level, line.text, line.level)
      )
    end

    -- lists
    if line.type == 'list' then
      for _,l in ipairs(list_line(index, line.text)) do
        table.insert(htmlized, l)
      end
    end

    -- paragraphs and linebreaks
    if line.type == 'regular' or line.type == 'linebreak' then
      table.insert(
        htmlized,
        paragraph_line(index, line.text)
      )
    end

    -- blockquotes
    if line.type == 'blockquote' then
      table.insert(
        htmlized,
        blockquote_line(index, line.text)
      )
    end

    -- codeblocks
    if line.type == 'codeblock' then
      table.insert(
        htmlized,
        codeblock_line(index, line.text)
      )
    end

    -- raw lines
    if line.type == 'raw' then
      table.insert(htmlized, line.text)
    end
  end

  return htmlized
end

-----------------------------------------------------------------------------
-- Converts link references to inline links.
--
-- @param   text
-- @return  text
-----------------------------------------------------------------------------
local function anchorize(text)
  local references = {}
  local linkdef = ' ? ? ?(%b[]): *([^%s]+)[ \n]'
  local patterns = {
    linkdef .. ' *["]([^\n]+)["] *',
    linkdef .. ' *[\']([^\n]+)[\'] *',
    linkdef .. ' *[(]([^\n]+)[)] *',
    linkdef
  }

  -- reference indexer
  local function get_references(id, url, title)
    id = id:match('%[(.+)%]'):lower()

    references[id] = {
      url = url,
      title = title
    }

    return ''
  end

  -- reference converter
  local function set_references(id)
    if '[]' == id then
      return '[]'
    end

    id = id:match('%[(.+)%]'):lower()

    if not references[id] then
      return '[' .. id .. ']'
    end

    if not references[id].title then
      return ('[%s](%s)'):format(id, references[id].url)
    end

    return ('[%s](%s "%s")'):format(id, references[id].url, references[id].title)
  end

  -- inline converter
  local function set_inlines(text, def)
    text = text:match('%[(.+)%]'):lower()
    local patterns = {
      '%((.-) *"(.-)"%)',
      '%((.-) *\'(.-)\'%)',
      '%((.-)%)',
    }

    for _, pattern in ipairs(patterns) do
      local url, title = def:match(pattern)

      if url and title then
        return ('<a href="%s" title="%s">%s</a>'):format(url, title, text)
      end

      if url then
        return ('<a href="%s">%s</a>'):format(url, text)
      end
    end

    return ''
  end

  -- parse references
  for _,pattern in ipairs(patterns) do
    text = text:gsub(pattern, get_references)
  end

  text = text:gsub('(%b[])[^(\n]?', set_references)

  -- parse anchors
  return text:gsub('(%b[])(%b())', set_inlines)
end

-----------------------------------------------------------------------------
-- Detects plain HTML prior to conversion and protectes these blocks.
--
-- @param   text
-- @return  text
-----------------------------------------------------------------------------
local function protect(text)
  local tags = {
    'blockquote', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'pre', 'table'
  }

  for _, tag in pairs(tags) do
    local tag_text = text:match('\n ? ? ?<' .. tag .. '.-</' .. tag .. '> *\n\n')

    if tag_text then
      block_text = tag_text:gsub(' ? ? ?(.+) *\n\n', '%1')
      local block_lines = split(block_text)

      for _, block_line in pairs(block_lines) do
        protected[block_line] = true
      end

      text:gsub(tag_text, block_text)
    end
  end

  return text
end

-----------------------------------------------------------------------------
-- Converts text from Markdown to HTML.
--
-- @param   text
-- @return  text
-----------------------------------------------------------------------------
local function convert(text)
  local lines = split(text)

  lines = map(lines, classify)
  lines = map(lines, emphasize)

  lines = htmlize(lines)

  return table.concat(lines, '\n')
end

-----------------------------------------------------------------------------
-- Converts Markdown to HTML.
--
-- @param   text
-- @return  text
-----------------------------------------------------------------------------
return function(text)
  if not text or not text:len() then
    return text
  end

  text = sanitize(text)
  text = anchorize(text)
  text = protect(text)
  text = convert(text)

  return text:gsub('^[ \n]*', '')
end
