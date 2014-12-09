if myHero.charName ~= "MasterYi" then return end
function OnLoad()
	qts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 599, DAMAGE_PHYSICAL)
	Menu = scriptConfig("ESL Yi", "bilbao")
		Menu:addParam("r", "R if Combo", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("e", "E if Combo", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("q", "Q if Combo", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Menu:addParam("drawq", "Draw Q Range", SCRIPT_PARAM_ONOFF, false)
end

function OnTick()
	if myHero:CanUseSpell(_Q) == READY and Menu.key then	
		qts:update()
		if ValidTarget(qts.target, 599) then CastSpell(_Q, qts.target)	end	
	end
end

function OnProcessSpell(Unit, Spell)
	if Unit.isMe and Menu.key and Spell and Spell.name:lower():find("attack") then		
		if Menu.e and myHero:CanUseSpell(_E) == READY then CastSpell(_E) end
		if Menu.r and myHero:CanUseSpell(_R) == READY then CastSpell(_R) end		
	end
end

function OnDraw()
	if not myHero.dead and Menu.drawq then
		DrawCircle(myHero.x, myHero.y, myHero.z, 600, (myHero:CanUseSpell(_Q) == READY) and RGB(7, 7, 250) or RGB(7, 7, 75))
	end
end
