if myHero.charName ~= "Ezreal" then return end
if FileExist(LIB_PATH .. "VPrediction.lua") and FileExist(LIB_PATH .. "SxOrbWalk.lua") then require("SxOrbWalk") require("VPrediction") end
local myTs, myMinionHandle, VP = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1200, DAMAGE_PHYSICAL), minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_HEALTH_ASC), VPrediction()
function OnLoad()
	Menu = scriptConfig("Easy Ez", "bilbao")
		Menu:addParam("fightmode", "Fight Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("P"))
		Menu:addParam("farmmode", "Farm Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("T"))
		Menu:addParam("pushmode", "Push Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("C"))	
		Menu:addParam("drawq", "Q Range", SCRIPT_PARAM_ONOFF, false)
	Menu:addTS(myTs) SxOrb:LoadToMenu()
end
function OnTick()
	if not myHero:CanUseSpell(_Q) == READY or myHero.dead then return end
	if Menu.fightmode then myTs:update() if ValidTarget(myTs.target) and CastQOn(myTs.target) then return end end
	if Menu.farmmode or Menu.pushmode then  myMinionHandle:update()
		for i, minion in pairs(myMinionHandle.objects) do
			if ValidTarget(myMinionHandle.objects[i]) and (Menu.pushmode or (myMinionHandle.objects[i].health < (getDmg("Q", myMinionHandle.objects[i], myHero) + ((myHero.damage)*1.1) + ((myHero.ap)*0.4)) * 0.95)) and CastQOn(myMinionHandle.objects[i]) then return end		
		end
	end	
end
function CastQOn(Unit)
	local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Unit, 0.25, 60, 1200,2000, myHero, true)
	if HitChance >= 1 then CastSpell(_Q, CastPosition.x, CastPosition.z) return true end
end
function OnDraw() if not myHero.dead and Menu.drawq then DrawCircle(myHero.x, myHero.y, myHero.z, 1200,RGB(7, 7, 250)) end end
