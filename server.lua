local fs = require('fs')
-- local table = require('table')

local JSON = require('json')
local pathJoin = require('path').join
local utopia = require('luvit-utopia')
local static = require('luvit-static')
local lico = require('luvit-lico')

local config = JSON.parse(fs.readFileSync('config.json'), {
  use_null = true,
  allow_comments = true
})

local app = utopia:new()

-- we serve files from our theme directory
local publicDir = pathJoin(__dirname, config.theme_path)
app:use(static(publicDir))

-- the main render function
app:use(function (req, res)
  res:finish(lico(req, publicDir, config))
end)

-- listen on our config port
app:listen(config.port)
p("http server listening on ", config.port)
