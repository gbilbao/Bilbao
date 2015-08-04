class 'CFiora'
function CFiora:__init() print("a")
	self.TSQ = TargetSelector(TARGET_LESS_CAST_PRIORITY, 600, DAMAGE_PHYSICAL)
	self.TSR = TargetSelector(TARGET_LESS_CAST_PRIORITY, 400, DAMAGE_PHYSICAL)
	self.Menu = scriptConfig("AdvX Fiora", "bilbao")
			SxOrb:LoadToMenu(self.Menu)	
	self.Menu:addSubMenu("Q Settings", "Q")
		self.Menu.Q:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)
		self.Menu.Q:addParam("Draw", "Draw Range", SCRIPT_PARAM_ONOFF , true)
	self.Menu:addSubMenu("W Settings", "W")
		self.Menu.W:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)
		self.Menu.W:addParam("Always", "Always Active", SCRIPT_PARAM_ONOFF , true)
	self.Menu:addSubMenu("E Settings", "E")
		self.Menu.E:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)
		self.Menu.E:addParam("LaneClear", "Use in LaneClear", SCRIPT_PARAM_ONOFF , true)		
	self.Menu:addSubMenu("R Settings", "R")
		self.Menu.R:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)		
		self.Menu.R:addParam("slider", "Min. Enemys", SCRIPT_PARAM_SLICE, 1, 5, 1, 0)
		self.Menu.R:addParam("Draw", "Draw Range", SCRIPT_PARAM_ONOFF , true)
	SxOrb:RegisterAfterAttackCallback(function(target) 
		if myHero:CanUseSpell(_E) == READY and ValidTarget(target) then
			if (target.type == myHero.type and (SxOrb.isFight and self.Menu.E.FightMode)) or (target.type ~= myHero.type and (SxOrb.isLaneClear and self.Menu.E.LaneClear)) then
				CastSpell(_E)
			end
		end	
	end)
	AddProcessSpellCallback(function(unit, spell) 
		if (myHero:CanUseSpell(_W) == READY and ((self.Menu.W.FightMode and SxOrb.isFight) or self.Menu.W.Always)) and ValidTarget(unit) and unit.type == myHero.type and spell.target and spell.target.isMe and not spell.name:lower():find("attack") then
			CastSpell(_W)
		end
	end)
	AddTickCallback(function()
		if myHero:CanUseSpell(_Q) == READY and (self.Menu.W.FightMode and SxOrb.isFight) then
			self.TSQ:update()
			if ValidTarget(self.TSQ.target) then
				CastSpell(_Q, self.TSQ.target)
			end
		end
		if myHero:CanUseSpell(_R) == READY and (self.Menu.R.FightMode and SxOrb.isFight) and CountEnemyHeroInRange(400) >= self.Menu.R.slider then
			self.TSR:update()
			if ValidTarget(self.TSR.target) then
				CastSpell(_R, self.TSR.target)
			end
		end
	end)
	AddDrawCallback(function()
		DrawCircle3D(myHero.x, myHero.y, myHero.z, 600, 1, ARGB(0xFF, 0xFF, 0x00, 0x00))
		DrawCircle3D(myHero.x, myHero.y, myHero.z, 400, 1, ARGB(0xFF, 0x00, 0x00, 0xFF))
	end)
end
if FileExist(LIB_PATH .. "SxOrbWalk.lua") then
	require("SxOrbWalk")
	CFiora()
end
