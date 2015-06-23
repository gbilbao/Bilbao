if myHero.charName ~= "Ryze" then return end
if FileExist(LIB_PATH .. "VPrediction.lua") and FileExist(LIB_PATH .. "SxOrbWalk.lua") then require("SxOrbWalk") require("VPrediction") end
local myTs, myMinionHandle, VP = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1200, DAMAGE_MAGIC), minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_HEALTH_ASC), VPrediction()

function OnLoad()
	Menu = scriptConfig("RectifyRyze", "bilbao")--dem fake update xD
		Menu:addParam("fightmode", "Fight Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("P"))
		Menu:addParam("farmmode", "Farm Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("T"))
		Menu:addParam("pushmode", "Push Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("C"))	
		Menu:addParam("draw", "Draw Range", SCRIPT_PARAM_ONOFF, false)
	Menu:addTS(myTs) SxOrb:LoadToMenu()
end

function OnTick()
	if myHero.dead then return end
	if Menu.fightmode then
		myTs:update() 
		if ValidTarget(myTs.target) then 
			if myHero:CanUseSpell(_Q) == READY then
				local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(myTs.target, 0.25, 60, 1700, 900, myHero, true)
				if HitChance >= 1 then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				end	
			end
			if GetDistance(myTs.target) < 600 then
				if myHero:CanUseSpell(_W) == READY then
					CastSpell(_W, myTs.target)				
				end
				if myHero:CanUseSpell(_E) == READY then
					CastSpell(_E, myTs.target)				
				end
				if GetDistance(myTs.target) < 475 then
					CastSpell(_R)
				end
			end
		end
	end
	if Menu.farmmode or Menu.pushmode then
		myMinionHandle:update()
		for i, minion in pairs(myMinionHandle.objects) do
			if ValidTarget(myMinionHandle.objects[i]) then
				if myHero:CanUseSpell(_Q) == READY and Menu.pushmode or (Menu.farmmode and (myMinionHandle.objects[i].health < myHero:CalcMagicDamage(myMinionHandle.objects[i], ((35 + (myHero:GetSpellData(_Q).level * 25)) + myHero.ap * 0.55 + )(0.015 + myHero:GetSpellData(_Q).level * 0.05) * myHero.maxMana))) then
 					local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(myMinionHandle.objects[i], 0.25, 60, 1700, 900, myHero, true)
					if HitChance >= 1 then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end					
				end
				if myHero:CanUseSpell(_W) == READY and GetDistance(myMinionHandle.objects[i]) < 600 and Menu.pushmode or (Menu.farmmode and (myMinionHandle.objects[i].health < myHero:CalcMagicDamage(myMinionHandle.objects[i], (((30 + (myHero:GetSpellData(_W).level * 30)) + myHero.ap * 0.4) + myHero.maxMana * 0.025)))) then
					CastSpell(_W, myMinionHandle.objects[i])
				end
				if myHero:CanUseSpell(_E) == READY and GetDistance(myMinionHandle.objects[i]) < 600 and Menu.pushmode or (Menu.farmmode and (myMinionHandle.objects[i].health < myHero:CalcMagicDamage(myMinionHandle.objects[i], (((34 + (myHero:GetSpellData(_W).level * 16)) + myHero.ap * 0.3) + myHero.maxMana * 0.02)))) then
					CastSpell(_E, myMinionHandle.objects[i])
				end
			end		
		end
	end	
end

function OnDraw() 
	if not myHero.dead and Menu.draw then 
		DrawCircle(myHero.x, myHero.y, myHero.z, 900, RGB(7, 200, 7)) 
		DrawCircle(myHero.x, myHero.y, myHero.z, 600, RGB(7, 7, 200)) 
	end
end
