if not myHero.charName:lower():find("fortune") then return end
function OnLoad()
	qts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 645, DAMAGE_PHYSICAL)
	ets = TargetSelector(TARGET_LESS_CAST_PRIORITY, 795, DAMAGE_PHYSICAL)
	Menu = scriptConfig("ESL MF", "bilbao")
		Menu:addParam("w", "W if Combo", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("e", "E if Combo", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("q", "Q if Combo", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Menu:addParam("drawq", "Draw Q Range", SCRIPT_PARAM_ONOFF, false)
end

function OnTick()
	if myHero:CanUseSpell(_Q) == READY and Menu.key then	
		qts:update()
		if ValidTarget(qts.target, 645) then CastSpell(_Q, qts.target) end	
	end
end

function OnProcessSpell(Unit, Spell)
	if Unit.isMe and Menu.key and Spell and Spell.name:lower():find("attack") then		
		if Menu.e and myHero:CanUseSpell(_E) == READY then
			ets:update()
			if ValidTarget(ets.target) then
				CastSpell(_E, ets.target.x, ets.target.z)
			end
		end
		if Menu.w and myHero:CanUseSpell(_W) == READY then CastSpell(_W) end		
	end
end

function OnDraw()
	if not myHero.dead and Menu.drawq then
		DrawCircle(myHero.x, myHero.y, myHero.z, 645, (myHero:CanUseSpell(_Q) == READY) and RGB(7, 7, 250) or RGB(7, 7, 75))
	end
end
