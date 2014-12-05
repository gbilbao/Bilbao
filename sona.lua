if myHero.charName ~= "Sona" then return end



function OnLoad()
	qRange, rRange = 822, 900
	QREADY, WREADY, EREADY, RREADY = false, false, false, false
	SkillR = {spellKey = _R, range = rRange, speed = 2.0, delay = 250}
	qts = TargetSelector(TARGET_LESS_CAST_PRIORITY, qRange, DAMAGE_MAGIC)
	rts = TargetSelector(TARGET_LESS_CAST_PRIORITY, rRange, DAMAGE_MAGIC)

	Menu = scriptConfig("ESL SONA", "bilbao")
		Menu:addParam("info", "Ultimate:", SCRIPT_PARAM_INFO, "")
		Menu:addParam("autoult", "AutoUlt if condiction:", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("count", "Min Enemies(also combo mode)",SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	
	
		Menu:addParam("info2", "Combo:", SCRIPT_PARAM_INFO, "")
		Menu:addParam("q", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("r", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		
	
		Menu:addParam("info3", "Draws:", SCRIPT_PARAM_INFO, "")
		Menu:addParam("drawq", "Q Range", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("drawr", "R Range", SCRIPT_PARAM_ONOFF, false)
end

function OnTick()	
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	if QREADY then qts:update() end
	if RREADY then rts:update() end
	
	if Menu.key then
		if QREADY and Menu.q and ValidTarget(qts.target, qRange * 0.99) then
			CastSpell(_Q)
		end
		if RREADY and Menu.r and ValidTarget(rts.target) then
			castR(rts.target)
		end
	end
	if Menu.autoult and RREADY and ValidTarget(rts.target) then
		castR(rts.target)
	end
		
end

function OnDraw()
	if myHero.dead then return end
		if QREADY and Menu.drawq then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange,RGB(7, 7, 250))
		end
		if RREADY and Menu.drawr then
			DrawCircle(myHero.x, myHero.y, myHero.z, rRange, RGB(250, 7, 250))
		end
end



function castR(target)
if not ValidTarget(target) then return end
        local ultPos = GetAoESpellPosition(350, target, 200)
        if ultPos and GetDistance(ultPos) <= rRange - (target.ms * 0.5) then
            if CountEnemyHeroInRange(350, ultPos) >= Menu.count then 
                CastSpell(_R, ultPos.x, ultPos.z)
            end
		end    
end


--[[
AoE_Skillshot_Position 2.0 by monogato
GetAoESpellPosition(radius, main_target, [delay]) returns best position in order to catch as many enemies as possible with your AoE skillshot, making sure you get the main target.
Note: You can optionally add delay in ms for prediction (VIP if avaliable, normal else).
]]

function GetCenter(points)
        local sum_x = 0
        local sum_z = 0        
        for i = 1, #points do
                sum_x = sum_x + points[i].x
                sum_z = sum_z + points[i].z
        end        
        local center = {x = sum_x / #points, y = 0, z = sum_z / #points }       
        return center
end

function ContainsThemAll(circle, points)
        local radius_sqr = circle.radius*circle.radius
        local contains_them_all = true
        local i = 1        
        while contains_them_all and i <= #points do
                contains_them_all = GetDistanceSqr(points[i], circle.center) <= radius_sqr
                i = i + 1
        end        
        return contains_them_all
end

-- The first element (which is gonna be main_target) is untouchable.
function FarthestFromPositionIndex(points, position)
        local index = 2
        local actual_dist_sqr
        local max_dist_sqr = GetDistanceSqr(points[index], position)        
        for i = 3, #points do
                actual_dist_sqr = GetDistanceSqr(points[i], position)
                if actual_dist_sqr > max_dist_sqr then
                        index = i
                        max_dist_sqr = actual_dist_sqr
                end
        end        
        return index
end

function RemoveWorst(targets, position)
        local worst_target = FarthestFromPositionIndex(targets, position)        
        table.remove(targets, worst_target)        
        return targets
end

function GetInitialTargets(radius, main_target)
        local targets = {main_target}
        local diameter_sqr = 4 * radius * radius        
        for i=1, heroManager.iCount do
                target = heroManager:GetHero(i)
                if target.networkID ~= main_target.networkID and ValidTarget(target) and GetDistanceSqr(main_target, target) < diameter_sqr then table.insert(targets, target) end
        end        
        return targets
end

function GetPredictedInitialTargets(radius, main_target, delay)
        if VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
        local predicted_main_target = VIP_USER and vip_target_predictor:GetPrediction(main_target) or GetPredictionPos(main_target, delay)
        local predicted_targets = {predicted_main_target}
        local diameter_sqr = 4 * radius * radius        
        for i=1, heroManager.iCount do
                target = heroManager:GetHero(i)
                if ValidTarget(target) then
                        predicted_target = VIP_USER and vip_target_predictor:GetPrediction(target) or GetPredictionPos(target, delay)
                        if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
                end
        end        
        return predicted_targets
end

function GetAoESpellPosition(radius, main_target, delay)
        local targets = delay and GetPredictedInitialTargets(radius, main_target, delay) or GetInitialTargets(radius, main_target)
        local position = GetCenter(targets)
        local best_pos_found = true
        local circle = Circle(position, radius)
        circle.center = position        
        if #targets > 2 then best_pos_found = ContainsThemAll(circle, targets) end        
        while not best_pos_found do
                targets = RemoveWorst(targets, position)
                position = GetCenter(targets)
                circle.center = position
                best_pos_found = ContainsThemAll(circle, targets)
        end        
        return position, #targets
end
