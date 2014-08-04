local fs = require('fs')
local string = require('string')
local table = require('table')

local page_maker = require('./page-to-table')

function getFiles(dir, list)
  list = list or {}
  local replace = string.gsub
  local files = fs.readdirSync(dir)
  local fcount = table.getn(files)
  for i = 1, fcount do
      local name = dir .. '/' .. files[i]
      if (fs.statSync(name).is_directory) then
        -- recursive call
        getFiles(name, list)
      else
        local isfof = string.find(name, '404')
        if isfof == nil then
          -- get the page, but do not render the content
          local page = page_maker(name, false)
          page.url = replace(replace(name, ".md", ""), "content/", "")
          table.insert(list, page)
        end
      end
  end
  return list
end

-- this fn is recusive so it needs to be named
return getFiles