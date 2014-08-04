local fs = require('fs')

return function(url)
  -- start with false
  local target = false
  -- handle home page special case
  if url == "/" then
    return "content/index.md"
  else
    -- check to see if this url resolves to a md file
    if fs.existsSync("content" .. url .. ".md") then
      return "content" .. url .. ".md"
    else
      -- trim trailing slash on all requests at this point
      url = (url:gsub("$%/*", ""))
      -- check to see if an index exists in this folder, added slash default
      if fs.existsSync("content" .. url .. "/index.md") then
        -- return that filename
        return "content" .. url .. "/index.md"
      end
    end
  end
end