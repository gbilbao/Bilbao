function OnLoad()
	lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
	range = myHero.range
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, range, DAMAGE_PHYSICAL, false)
	Menu = scriptConfig("MiniOrbwalker", "bilbao")
		Menu:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)	
		Menu:addParam("draw", "Draw AA-Range", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("target", "Draw Circle on target", SCRIPT_PARAM_ONOFF, false)
end

function OnTick()
	range = myHero.range + myHero.boundingRadius - 3
	ts.range = range
	ts:update()
	if not Menu.key then return end
	local myTarget = ts.target
	if myTarget ~=	nil then		
		if timeToShoot() then
			myHero:Attack(myTarget)
		elseif heroCanMove() then
			moveToCursor()
		end
	else		
		moveToCursor() 
	end
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end 
 
function timeToShoot()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end 
 
function moveToCursor()
	if GetDistance(mousePos) > 1 then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()* (300 + GetLatency())
		myHero:MoveTo(moveToPos.x, moveToPos.z)
	end 
end

function OnDraw()
    if not myHero.dead then
		if Menu.draw then DrawCircle(myHero.x, myHero.y, myHero.z, range, 0x19A712) end
        if ts.target ~= nil and Menu.target then DrawCircle(ts.target.x, ts.target.y, ts.target.z, ts.target.boundingRadius + 50, 0x19A712) end
    end
end

function OnProcessSpell(object, spell)
	if object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end 
	end
end
