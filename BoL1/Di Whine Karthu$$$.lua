if myHero.charName ~= "Karthus" or not FileExist(LIB_PATH .. "SxOrbWalk.lua") or not FileExist(LIB_PATH .. "VPrediction.lua") then return end
require("VPrediction") require("SxOrbWalk")
local myTs, myMinionHandle, VP, EACtive, rts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_MAGIC), minionManager(MINION_ENEMY, 875, myHero, MINION_SORT_HEALTH_ASC), VPrediction(), false, TargetSelector(TARGET_LOW_HP, 50000, DAMAGE_MAGIC)
rts:SetConditional(function(h) return h.health <  myHero:CalcMagicDamage(h, (100 + (myHero:GetSpellData(SPELL_4).level * 150) + (myHero.ap * 0.6))) end)
local AddMode = function(m, a) m:addParam("IsFight", "FightMode", SCRIPT_PARAM_ONOFF, true)	m:addParam("IsHarass", "HarassMode", SCRIPT_PARAM_ONOFF, true) if a then m:addParam("IsLaneClear", "LaneClear", SCRIPT_PARAM_ONOFF, true) m:addParam("IsLastHit", "LastHit", SCRIPT_PARAM_ONOFF, true) end end
function OnLoad()
	Menu = scriptConfig("King Of Kingz Karthu$$$", "bilbao") Menu:addTS(myTs) SxOrb:LoadToMenu(Menu)
		Menu:addSubMenu("$$$ - Q", "q") AddMode(Menu.q, true)
		Menu:addSubMenu("$$$ - W", "w") AddMode(Menu.w)
		Menu:addSubMenu("$$$ - E", "e") AddMode(Menu.e, true)
		Menu:addSubMenu("$$$ - R", "r")	Menu.r:addParam("ks", "KillSteal", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("huehuehue", "", SCRIPT_PARAM_INFO, "")
		Menu:addParam("bilbao", "$$$  -  i am so pepper  -  $$", SCRIPT_PARAM_LIST, 1, {"rekt", "by", "bilbao"})
end
function OnTick() myTs:update() myMinionHandle:update()
	if myHero:CanUseSpell(_Q) == READY then
		if ((SxOrb.IsFight and Menu.q.IsFight) or (SxOrb.IsHarass and Menu.q.IsHarass)) and ValidTarget(myTs.target, 875) then
			local predPos, hc = VP:GetCircularCastPosition(myTs.target, 0.75, 200, 875, 1700, myHero)
			if hc >= 1 and GetDistance(predPos) < 875 then CastSpell(_Q, predPos.x, predPos.z) end
		elseif ((SxOrb.IsLaneClear and Menu.q.IsLaneClear) or (SxOrb.IsLastHit and Menu.q.IsLastHit)) and ValidTarget(myMinionHandle.objects[1], 875) and ((SxOrb.IsLastHit and myMinionHandle.objects[1].health <  myHero:CalcMagicDamage(myMinionHandle.objects[1], (20 + (myHero:GetSpellData(SPELL_1).level * 20) + (myHero.ap * 0.3)))) or SxOrb.IsLaneClear) then
			local predPos, hc = VP:GetCircularCastPosition(myMinionHandle.objects[1], 0.75, 200, 875, 1700, myHero)
			if hc >= 1 and GetDistance(predPos) < 875 then CastSpell(_Q, predPos.x, predPos.z) end
		end
	end
	if myHero:CanUseSpell(_W) == READY then
		if ((SxOrb.IsFight and Menu.w.IsFight) or (SxOrb.IsHarass and Menu.w.IsHarass)) and ValidTarget(myTs.target, 925) then
			local predPos, hc = VP:GetBestCastPosition(myTs.target, 0.5, myTs.target.boundingRadius, 925, 1600)
			if hc >= 1 then CastSpell(_W, predPos.x, predPos.z) end		
		end	
	end
	if myHero:CanUseSpell(_E) == READY then
		if ((SxOrb.IsFight and Menu.e.IsFight) or (SxOrb.IsHarass and Menu.e.IsHarass)) and not EACtive and ValidTarget(myTs.target, 500) then
			CastSpell(_E)
		elseif ((SxOrb.IsLaneClear and Menu.e.IsLaneClear) or (SxOrb.IsLastHit and Menu.e.IsLastHit)) and not EACtive and ValidTarget(myMinionHandle.objects[1], 525) and ((SxOrb.IsLastHit and myMinionHandle.objects[1].health <  myHero:CalcMagicDamage(myMinionHandle.objects[1], (20 + (myHero:GetSpellData(SPELL_3).level * 20) + (myHero.ap * 0.2)))) or SxOrb.IsLaneClear) then
			CastSpell(_E)
		elseif EACtive then
			CastSpell(_E)
		end
	end
	if Menu.r.ks and myHero:CanUseSpell(_R)  == READY then rts:update()
		if ValidTarget(rts.target) then CastSpell(_R) end
	end
end
function OnDraw()
	DrawCircle3D(myHero.x, myHero.y, myHero.z, 800, 1, ARGB(255,0,0,255))
	DrawCircle3D(myHero.x, myHero.y, myHero.z, 925, 1, ARGB(255,255,0,0))
	DrawCircle3D(myHero.x, myHero.y, myHero.z, 500, 1, ARGB(255,0,255,0))
end
function OnApplyBuff(source, unit, buff) if source.isMe and buff.name == "KarthusDefile" then EACtive = true end end
function OnRemoveBuff(unit,buff)if unit.isMe and buff.name == "KarthusDefile" then EACtive = false end end
