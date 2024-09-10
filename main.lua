local function nested(table, index, new_value)
	local origin = table
	local last_idx, last_table = nil, nil
  
	for s in index:gmatch("[^%.]+") do
		if (type(table) == 'table') then
			last_table = table
		end
  
		table = table[s]
		last_idx = s
  	end
  
	if (new_value) then
		last_table[last_idx] = new_value
	end

	return table
end

patch = patch or {}

patch.INTERRUPT = 'INTERRUPT'

patch.prefix = function(name, fn)
	assert(fn ~= nil, 'Function is not specified')

	local target = nested(_G, name);
	if (type(target) ~= 'function') then
	  error('Patch target is not a function')
	end
	
	local override = function(...)
	  local code, value = fn({params = ... and ... or {}})
	  if (code == patch.INTERRUPT) then
		return value
	  end
	  target(...)
	end
	
	nested(_G, name, override)
end

patch.postfix = function(name, fn, manual)
	assert(fn ~= nil, 'Function is not specified')

	local target = nested(_G, name);
	if (type(target) ~= 'function') then
		error('Patch target is not a function')
	end

	local override = nil
	
	if not manual then
		override = function(...)
			local result = target(...)
			fn(..., result)
			return result
		end
	else
		override = fn
	end
	
	nested(_G, name, override)
end

local function select_card(n)
	if not G.hand then
		return
	end

	if not G.hand.cards then
		return
	end

	if G.hand.cards[n] then
		G.hand.cards[n]:click()
	end
end

patch.postfix('love.load', function()
  	local old_fn = G.CONTROLLER.key_press_update

	patch.postfix('G.CONTROLLER.key_press_update', function(self, key, dt)
		old_fn(self, key, dt)

		if key == 'backspace' and G.hand then
			G.hand:unhighlight_all()
		end

		local key = tonumber(key)

		if key then
			select_card(key)
		end
	end, true)
end)