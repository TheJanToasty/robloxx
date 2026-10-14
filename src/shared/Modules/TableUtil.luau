--!strict
-- Table helpers used by player data.

local TableUtil = {}

function TableUtil.DeepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value :: any do
		copy[key] = TableUtil.DeepCopy(child)
	end
	return copy :: any
end

-- Adds any keys from `template` that are missing in `target`, recursively.
-- Existing values are never overwritten. Arrays and empty tables in the template
-- are copied only when the key is missing entirely, so saved lists stay as they are.
function TableUtil.Reconcile(target: { [any]: any }, template: { [any]: any })
	for key, templateValue in template do
		local current = target[key]
		if current == nil then
			target[key] = TableUtil.DeepCopy(templateValue)
		elseif type(current) == "table" and type(templateValue) == "table" then
			if next(templateValue) ~= nil and #templateValue == 0 then
				TableUtil.Reconcile(current, templateValue)
			end
		end
	end
end

return TableUtil
