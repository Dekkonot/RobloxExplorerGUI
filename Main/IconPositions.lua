-- Full disclosure I stole this from SteadyOn because I could not be bothered to write it myself
-- Check out his plugin here: https://www.roblox.com/library/2256681875/SteadyOns-Instance-Scanner
-- Documentation here: https://devforum.roblox.com/t/steadyons-instance-scanner/170422

local ImageData = {} 
local Data

local Success = pcall(function()
	Data = game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Anaminus/anaminus.github.io/master/api/search-db.json"))
end)
if not Success then
	Data = game:GetService("HttpService"):JSONDecode(require(script.DataJSON))
end

for _, ClassInfo in pairs(Data) do
	if ClassInfo.m == nil then
		local RealIcon = ClassInfo.i
		ImageData[ClassInfo.c] = Vector2.new((RealIcon%10)*16, (math.floor(RealIcon/10)*16))
	end
end

return ImageData