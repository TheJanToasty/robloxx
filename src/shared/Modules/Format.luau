--!strict
-- Number and text formatting for UI.

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- 1234567 -> "1,234,567"
function Format.Commas(value: number): string
	local whole = math.floor(math.abs(value))
	local text = tostring(whole)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return if value < 0 then "-" .. formatted else formatted
end

-- 999 -> "999", 12500 -> "12.5K", 3400000 -> "3.4M"
function Format.Short(value: number): string
	local absolute = math.abs(value)
	if absolute < 10000 then
		return Format.Commas(value)
	end
	local index = 0
	while absolute >= 1000 and index < #SUFFIXES do
		absolute /= 1000
		index += 1
	end
	local text = if absolute >= 100 then string.format("%d", absolute) else string.format("%.1f", absolute)
	text = text:gsub("%.0$", "")
	return (if value < 0 then "-" else "") .. text .. SUFFIXES[index]
end

function Format.Weight(kilograms: number): string
	return string.format("%.2f kg", kilograms)
end

return Format
