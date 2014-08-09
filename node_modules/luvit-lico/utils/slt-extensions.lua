local string = require('string')
local os = require('os')
local table = require('table')

local sltluv = require('sltluv')

return function(config)
  -- we need to bind these functions to global otherwise they won't be exposed in our templates
  _G.escape = function(str)
    local tt = {
      ['&'] = '&amp;',
      ['<'] = '&lt;',
      ['>'] = '&gt;',
      ['"'] = '&quot;',
      ["'"] = '&#39;',
    }
    local r = string.gsub(str, '[&<>"\']', tt)
    return r
  end

  -- my include function for loading templates relative to the theme folder
  _G.include = function(str)
    return sltluv.render(sltluv.loadfile(config.theme_path .. str), { page = config.page })
  end

  _G.count = function(item)
    if type(item) == 'string' then
      return string.len(item)
    elseif type(item) == 'table' then
      return table.getn(item)
    end
  end

  -- expose a markdown render function
  _G.markdown = function(str)
    return require('markdown')(str)
  end

  _G.lowercase = function(str)
    return string.lower(str)
  end

  _G.uppercase = function(str)
    return string.upper(str)
  end

  _G.trim = function(str, what)
    if what == nil then
      what = '%s+'
    end
    str = string.gsub(str, '^' .. what, '')
    str = string.gsub(str, what .. '$', '')
    return str
  end

  -- snippets from https://github.com/luvit/luvit/wiki/Snippets
  -- N.B. 0-based start/stop
  _G.slice = function(t, start, stop)
    if start == nil then
      start = 0
    end
    if stop == nil then
      stop = #t
    end
    if start < 0 then
      start = start + #t
    end
    if stop < 0 then
      stop = stop + #t
    end
    if type(t) == 'string' then
      return sub(t, start + 1, stop)
    end
    local r = { }
    local n = 0
    local i = 0
    for i = start + 1, stop do
      n = n + 1
      r[n] = t[i]
    end
    return r
  end

  _G.sort = function(t, f)
    return table.sort(t, f)
  end

  _G.join = function(t, s)
    if s == nil then
      s = ','
    end
    return table.concat(t, s)
  end

  _G.has = function(t, s)
    return rawget(t, s) ~= nil
  end

  _G.keys = function(t)
    local r = { }
    local n = 0
    for k, v in pairs(t) do
      n = n + 1
      r[n] = k
    end
    return r
  end

  _G.values = function(t)
    local r = { }
    local n = 0
    for k, v in pairs(t) do
      n = n + 1
      r[n] = v
    end
    return r
  end

  _G.map = function(t, f)
    local r = { }
    for k, v in pairs(t) do
      r[k] = f(v, k, t)
    end
    return r
  end

  _G.filter = function(t, f)
    local r = { }
    for k, v in pairs(t) do
      if f(v, k, t) then
        r[k] = v
      end
    end
    return r
  end

  _G.each = function(t, f)
    for k, v in pairs(t) do
      f(v, k, t)
    end
  end

  _G.curry = function(f, g)
    return function(...)
      return f(g(unpack(arg)))
    end
  end

  _G.indexOf = function(t, x)
    if type(t) == 'string' then
      return find(t, x, true)
    end
    for k, v in pairs(t) do
      if v == x then
        return k
      end
    end
    return nil
  end

  -- aliases
  _G.replace = string.gsub
  _G.date = os.date
  _G.debug = p
end