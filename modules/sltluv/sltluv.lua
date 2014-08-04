--[[
-- sltluv - Simple Luvit Template
--
-- Project page: https://github.com/james2doyle/sltluv
--
-- @License
-- MIT License
--]]

-- require lua modules
local table = require('table')
local string = require('string')
local io = require('io')
local coroutine = require('coroutine')

-- apply the coroutine function into the global namespace
_G.coroutine = coroutine

local sltluv = {}

-- save some helpers
local replace = string.sub
local find = string.find
local insert = table.insert
local concat = table.concat

-- a tree fold on inclusion tree
-- @param init_func: must return a new value when called
local function include_fold(template, start_tag, end_tag, fold_func, init_func)
	local result = init_func()

	start_tag = start_tag or '#{'
	end_tag = end_tag or '}#'
	local start_tag_inc = start_tag .. 'include:'

	local start1, end1 = find(template, start_tag_inc, 1, true)
	local start2 = nil
	local end2 = 0

	while start1 ~= nil do
		if start1 > end2 + 1 then -- for beginning part of file
			result = fold_func(result, replace(template, end2 + 1, start1 - 1))
		end
		start2, end2 = find(template, end_tag, end1 + 1, true)
		assert(start2, 'end tag "' .. end_tag .. '" missing')
		do -- recursively include the file
			local filename = assert(loadstring('return ' .. replace(template, end1 + 1, start2 - 1)))()
			assert(filename)
			local fin = assert(io.open(filename))
			-- TODO: detect cyclic inclusion?
			result = fold_func(result, include_fold(fin:read('*a'), start_tag, end_tag, fold_func, init_func), filename)
			fin:close()
		end
		start1, end1 = find(template, start_tag_inc, end2 + 1, true)
	end
	result = fold_func(result, replace(template, end2 + 1))
	return result
end

-- preprocess included files
-- @return string
function sltluv.precompile(template, start_tag, end_tag)
	return concat(include_fold(template, start_tag, end_tag, function(acc, v)
		if type(v) == 'string' then
			insert(acc, v)
		elseif type(v) == 'table' then
			insert(acc, concat(v))
		else
			error('Unknown type: ' .. type(v))
		end
		return acc
	end, function() return {} end))
end

-- unique a list, preserve order
local function stable_uniq(t)
	local existed = {}
	local res = {}
	for _, v in ipairs(t) do
		if not existed[v] then
			insert(res, v)
			existed[v] = true
		end
	end
	return res
end

-- @return { string }
function sltluv.get_dependency(template, start_tag, end_tag)
	return stable_uniq(include_fold(template, start_tag, end_tag, function(acc, v, name)
		if type(v) == 'string' then
		elseif type(v) == 'table' then
			if name ~= nil then
				insert(acc, name)
			end
			for _, subname in ipairs(v) do
				insert(acc, subname)
			end
		else
			error('Unknown type: ' .. type(v))
		end
		return acc
	end, function() return {} end))
end

-- @return { name = string, code = string / function}
function sltluv.loadstring(template, start_tag, end_tag, tmpl_name)
	-- compile it to lua code
	local lua_code = {}

	start_tag = start_tag or '#{'
	end_tag = end_tag or '}#'

	local output_func = "coroutine.yield"

	template = sltluv.precompile(template, start_tag, end_tag)

	local start1, end1 = find(template, start_tag, 1, true)
	local start2 = nil
	local end2 = 0

	local cEqual = string.byte('=', 1)

	while start1 ~= nil do
		if start1 > end2 + 1 then
			insert(lua_code, output_func .. '(' .. string.format("%q", replace(template, end2 + 1, start1 - 1)) .. ')')
		end
		start2, end2 = find(template, end_tag, end1 + 1, true)
		assert(start2, 'end_tag "' .. end_tag .. '" missing')
		if string.byte(template, end1 + 1) == cEqual then
			insert(lua_code, output_func .. '(' .. replace(template, end1 + 2, start2 - 1) .. ')')
		else
			insert(lua_code, replace(template, end1 + 1, start2 - 1))
		end
		start1, end1 = find(template, start_tag, end2 + 1, true)
	end
	insert(lua_code, output_func .. '(' .. string.format("%q", replace(template, end2 + 1)) .. ')')

	local ret = { name = tmpl_name or '=(sltluv.loadstring)' }
	if setfenv == nil then -- lua 5.2
		ret.code = concat(lua_code, '\n')
	else -- lua 5.1
		ret.code = assert(loadstring(concat(lua_code, '\n'), ret.name))
	end
	return ret
end

-- @return { name = string, code = string / function }
function sltluv.loadfile(filename, start_tag, end_tag)
	local fin = assert(io.open(filename))
	local all = fin:read('*a')
	fin:close()
	return sltluv.loadstring(all, start_tag, end_tag, filename)
end

local mt52 = { __index = _ENV }
local mt51 = { __index = _G }

-- @return a coroutine function
function sltluv.render_co(t, env)
	local f
	if setfenv == nil then -- lua 5.2
		if env ~= nil then
			setmetatable(env, mt52)
		end
		f = assert(load(t.code, t.name, 't', env or _ENV))
	else -- lua 5.1
		if env ~= nil then
			setmetatable(env, mt51)
		end
		f = setfenv(t.code, env or _G)
	end
	return f
end

-- @return string
function sltluv.render(t, env)
	local result = {}
	local co = coroutine.create(sltluv.render_co(t, env))
	while coroutine.status(co) ~= 'dead' do
		local ok, chunk = coroutine.resume(co)
		if not ok then
			error(chunk)
		end
		insert(result, chunk)
	end
	return concat(result)
end

return sltluv
