local string = require('string')
local fs = require('fs')
-- local table = require('table')

local JSON = require('json')
local pathJoin = require('path').join
local createServer = require('web').createServer

local config = JSON.parse(fs.readFileSync('config.json'), {
  use_null = true,
  allow_comments = true
})

local resolve = require('url-resolver')
local page_renderer = require('utils/page-renderer')

function render(res, page)
  return res(200, {
    ["Content-Type"] = "text/html",
    ["Content-Length"] = string.len(page),
    ["Cache-Control"] = config.cache_control
  }, page)
end

-- Define a simple custom app
local function app(req, res)
  -- returns false is no md file is found
  local target = resolve(req.url.path)
  if target then
    return render(res, page_renderer(target, config))
  else
    -- nothing was found, serve the 404 markdown file
    return render(res, page_renderer('content/404.md', config))
  end
end

-- Serve static files and index directories
app = require('static')(app, {
  -- the root is our theme path, we serve all public files from there
  root = pathJoin(__dirname, config.theme_path)
})

-- Log all requests
app = require('log')(app)

-- Add in missing Date and Server headers, auto chunked encoding, etc..
app = require('cleanup')(app)

local server = createServer("0.0.0.0", config.port, app)
p("http server listening on ", server:getsockname())
