local sltluv = require('./sltluv')
local string = require('string')
local io = require('io')

local user = {
	name = '<world>',
	location = 'Earth'
}

function escapeHTML(str)
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

-- apply the function into the global namespace
_G.escapeHTML = escapeHTML

local tmpl = sltluv.loadstring([[<span>
#{ if user ~= nil then }#
<!-- an html comment -->
<p>Hello, #{= escapeHTML(user.name) }#!</p>
<p>Welcome to #{= user.location }#!</p>
#{ else }#
<a href="/login">login</a>
#{ end }#
</span>
]])

io.write(sltluv.render(tmpl, {user = user}))
