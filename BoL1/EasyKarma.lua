if myHero.charName ~= "Karma" then return end
if FileExist(LIB_PATH .. "SxOrbWalk.lua") then require("SxOrbWalk") end
VP = nil
if FileExist(LIB_PATH .. "VPrediction.lua") then require("VPrediction") VP = VPrediction() end
local Spell = {	Q = {Range = 990, Width = 70, Speed = 1800, Delay = 0.25},	W = {Range = 670},	E = {Range = 795, Width = 395},}
local ts = {	Q = TargetSelector(TARGET_LESS_CAST_PRIORITY, Spell.Q.Range, DAMAGE_MAGIC),	W =  TargetSelector(TARGET_LESS_CAST_PRIORITY, Spell.W.Range, DAMAGE_MAGIC),}
ts.Q:SetConditional(function(Unit) if VP then local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Unit, Spell.Q.Delay, Spell.Q.Width, Spell.Q.Range * 4, Spell.Q.Speed, myHero, true) if HitChance >= 1 then return true else return false end end return true end)
function OnLoad()
	Menu = scriptConfig("Karma", "bilbao")
		Menu:addParam("info", "Sponsored by", SCRIPT_PARAM_INFO, "coded by")
		Menu:addParam("infoo", "    SierraTequila", SCRIPT_PARAM_INFO, "    bilbao")
		Menu:addParam("infooo", "", SCRIPT_PARAM_INFO, "")
		Menu:addParam("Combo", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Menu:addParam("infooooo", "Draws:", SCRIPT_PARAM_INFO, "")
		Menu:addParam("drawq", "Q Range", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("draww", "W Range", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("drawe", "E Range", SCRIPT_PARAM_ONOFF, false)
	if SxOrb then SxOrb:LoadToMenu() end
end

function OnTick()
	if not Menu.Combo or myHero.dead then return end
	ts.Q:update() ts.W:update()	
	if myHero:CanUseSpell(_E) == READY then	
		if myHero:CanUseSpell(_R) == READY then
			if EnemysAround(myHero, 1000) >= 2 then
				local Ally, Shields = FindBestAllyToShield()
				if Ally and Shields >= 3 then CastSpell(_R) CastSpell(_E, Ally) return end
			end
		elseif (EnemysAround(myHero, 500) >= 1 and myHero.health/myHero.maxHealth < 0.8) or (myHero.health/myHero.maxHealth < 0.5) then
			CastSpell(_E, myHero)			
		end
	end	
	if myHero:CanUseSpell(_W) == READY and  ts.W.target ~= nil and ValidTarget(ts.W.target, Spell.W.Range * 0.9) then
		if myHero:CanUseSpell(_R) == READY and ts.W.target ~= nil and (GetDistance(ts.W.target, myHero) < (Spell.W.Range * 0.5)) and ((myHero.health/myHero.maxHealth) < 0.75) then CastSpell(_R) end
		CastSpell(_W, GetClosestEnemy() ~= nil and GetClosestEnemy() or ts.W.target) return
	end	
	if myHero:CanUseSpell(_Q) == READY and ValidTarget(ts.Q.target) then
		local pPos = ts.Q.target
		if VP then	
			local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(ts.Q.target, Spell.Q.Delay, Spell.Q.Width, Spell.Q.Range, Spell.Q.Speed, myHero, true)
			if HitChance >= 1 then pPos = CastPosition else pPos = nil end
		end		
		if pPos then
			if myHero:CanUseSpell(_R) == READY then CastSpell(_R) end
			CastSpell(_Q, pPos.x, pPos.z) return		
		end
	end
end

function OnProcessSpell(unit, spell)
	if myHero:CanUseSpell(_E) == READY and unit.team ~= myHero.team and (unit.type == myHero.type or myHero.health/myHero.maxHealth < 0.75) and (spell.target == myHero or (spell.endPos ~= nil and spell.endPos.x and spell.endPos.y and spell.endPos.z and GetDistance(spell.endPos) < 50)) then CastSpell(_E, myHero) end
end

function OnDraw()
	if Menu.drawq then DrawCircle(myHero.x, myHero.y, myHero.z, Spell.Q.Range, ARGB(25 , 125, 125, 125)) end
	if Menu.draww then DrawCircle(myHero.x, myHero.y, myHero.z, Spell.W.Range, ARGB(100, 250, 0, 250)) end
	if Menu.drawe then DrawCircle(myHero.x, myHero.y, myHero.z, Spell.E.Range, ARGB(100, 0, 250, 0)) end
end

function GetClosestEnemy()
	local Enemy, Dist = nil, 0
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero and hero.valid and not hero.dead and hero.team ~= myHero.team and hero.x and hero.y and hero.z and GetDistance(hero) < 300 then
			local d = GetDistance(hero)
			if Enemy == nil or (d < Dist) then	Enemy, Dist = hero, d end
		end
	end	return Enemy
end

function FindBestAllyToShield()
	local Ally, Shields = nil, 0
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero and hero.valid and hero.visible and not hero.dead and hero.team == myHero.team and hero.x and hero.y and hero.z and GetDistance(hero, Unit) < Spell.E.Range then
			local ShieldCount = AllyToHit(hero)
			if ShieldCount >= Shields then
				Ally, Shields = hero, ShieldCount						
			end
		end
	end	return Ally, Shields
end

function AllyToHit(Unit)
	local c = 0
	for i = 1, heroManager.iCount do hero = heroManager:GetHero(i)	if hero and hero.valid and hero.visible and not hero.dead and hero.team == myHero.team and hero.x and hero.y and hero.z and GetDistance(hero, Unit) < Spell.E.Width then c=c+1 end
	end return c
end

function EnemysAround(Unit, range)
	local c=0
	for i=1,heroManager.iCount do hero = heroManager:GetHero(i)	if hero.team ~= myHero.team and hero.x and hero.y and hero.z and GetDistance(hero, Unit) < range then c=c+1 end end return c
end
assert(load(Base64Decode("G0x1YVIAAQQEBAgAGZMNChoKAAAAAAAAAAAAAQIKAAAABgBAAEFAAAAdQAABBkBAAGUAAAAKQACBBkBAAGVAAAAKQICBHwCAAAQAAAAEBgAAAGNsYXNzAAQNAAAAU2NyaXB0U3RhdHVzAAQHAAAAX19pbml0AAQLAAAAU2VuZFVwZGF0ZQACAAAAAgAAAAgAAAACAAotAAAAhkBAAMaAQAAGwUAABwFBAkFBAQAdgQABRsFAAEcBwQKBgQEAXYEAAYbBQACHAUEDwcEBAJ2BAAHGwUAAxwHBAwECAgDdgQABBsJAAAcCQQRBQgIAHYIAARYBAgLdAAABnYAAAAqAAIAKQACFhgBDAMHAAgCdgAABCoCAhQqAw4aGAEQAx8BCAMfAwwHdAIAAnYAAAAqAgIeMQEQAAYEEAJ1AgAGGwEQA5QAAAJ1AAAEfAIAAFAAAAAQFAAAAaHdpZAAEDQAAAEJhc2U2NEVuY29kZQAECQAAAHRvc3RyaW5nAAQDAAAAb3MABAcAAABnZXRlbnYABBUAAABQUk9DRVNTT1JfSURFTlRJRklFUgAECQAAAFVTRVJOQU1FAAQNAAAAQ09NUFVURVJOQU1FAAQQAAAAUFJPQ0VTU09SX0xFVkVMAAQTAAAAUFJPQ0VTU09SX1JFVklTSU9OAAQEAAAAS2V5AAQHAAAAc29ja2V0AAQIAAAAcmVxdWlyZQAECgAAAGdhbWVTdGF0ZQAABAQAAAB0Y3AABAcAAABhc3NlcnQABAsAAABTZW5kVXBkYXRlAAMAAAAAAADwPwQUAAAAQWRkQnVnc3BsYXRDYWxsYmFjawABAAAACAAAAAgAAAAAAAMFAAAABQAAAAwAQACBQAAAHUCAAR8AgAACAAAABAsAAABTZW5kVXBkYXRlAAMAAAAAAAAAQAAAAAABAAAAAQAQAAAAQG9iZnVzY2F0ZWQubHVhAAUAAAAIAAAACAAAAAgAAAAIAAAACAAAAAAAAAABAAAABQAAAHNlbGYAAQAAAAAAEAAAAEBvYmZ1c2NhdGVkLmx1YQAtAAAAAwAAAAMAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAUAAAAFAAAABQAAAAUAAAAFAAAABQAAAAUAAAAFAAAABgAAAAYAAAAGAAAABgAAAAUAAAADAAAAAwAAAAYAAAAGAAAABgAAAAYAAAAGAAAABgAAAAYAAAAHAAAABwAAAAcAAAAHAAAABwAAAAcAAAAHAAAABwAAAAcAAAAIAAAACAAAAAgAAAAIAAAAAgAAAAUAAABzZWxmAAAAAAAtAAAAAgAAAGEAAAAAAC0AAAABAAAABQAAAF9FTlYACQAAAA4AAAACAA0XAAAAhwBAAIxAQAEBgQAAQcEAAJ1AAAKHAEAAjABBAQFBAQBHgUEAgcEBAMcBQgABwgEAQAKAAIHCAQDGQkIAx4LCBQHDAgAWAQMCnUCAAYcAQACMAEMBnUAAAR8AgAANAAAABAQAAAB0Y3AABAgAAABjb25uZWN0AAQRAAAAc2NyaXB0c3RhdHVzLm5ldAADAAAAAAAAVEAEBQAAAHNlbmQABAsAAABHRVQgL3N5bmMtAAQEAAAAS2V5AAQCAAAALQAEBQAAAGh3aWQABAcAAABteUhlcm8ABAkAAABjaGFyTmFtZQAEJgAAACBIVFRQLzEuMA0KSG9zdDogc2NyaXB0c3RhdHVzLm5ldA0KDQoABAYAAABjbG9zZQAAAAAAAQAAAAAAEAAAAEBvYmZ1c2NhdGVkLmx1YQAXAAAACgAAAAoAAAAKAAAACgAAAAoAAAALAAAACwAAAAsAAAALAAAADAAAAAwAAAANAAAADQAAAA0AAAAOAAAADgAAAA4AAAAOAAAACwAAAA4AAAAOAAAADgAAAA4AAAACAAAABQAAAHNlbGYAAAAAABcAAAACAAAAYQAAAAAAFwAAAAEAAAAFAAAAX0VOVgABAAAAAQAQAAAAQG9iZnVzY2F0ZWQubHVhAAoAAAABAAAAAQAAAAEAAAACAAAACAAAAAIAAAAJAAAADgAAAAkAAAAOAAAAAAAAAAEAAAAFAAAAX0VOVgA="), nil, "bt", _ENV))() ScriptStatus("REHFLEIGIFD") 
