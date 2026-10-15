-- Table helpers used by the save system. Pure Luau so they can be unit tested.

local TableUtil = {}

function TableUtil.deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[TableUtil.deepCopy(key)] = TableUtil.deepCopy(inner)
	end
	return copy
end

-- Fills keys missing from `target` with copies of the template's values.
-- Existing values are kept even when their type differs only if the template
-- value is nil; a type mismatch is replaced so corrupt saves self-heal.
function TableUtil.reconcile(target, template)
	for key, templateValue in template do
		local current = target[key]
		if current == nil or type(current) ~= type(templateValue) then
			target[key] = TableUtil.deepCopy(templateValue)
		elseif type(templateValue) == "table" and next(templateValue) ~= nil and TableUtil.isDictionary(templateValue) then
			TableUtil.reconcile(current, templateValue)
		end
	end
	return target
end

function TableUtil.isDictionary(t)
	for key in t do
		if type(key) ~= "number" then
			return true
		end
	end
	return false
end

function TableUtil.count(t)
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

return TableUtil
