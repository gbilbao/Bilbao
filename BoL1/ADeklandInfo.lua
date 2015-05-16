-- Dekland info script. Most of this is Grey's work, we just added a few bits to help.
--[[ KEYS!
    RANGE KEYS:
        Add 25 to range = "=" (no shift button)
        Subtract 25 from range = "-"
        Add 1 to range = "+" (numperbad +)
        Subtract 1 from range = "-" (number pad -)

    Width Keys
        Add 10 to width = "]" 
        Subtract 10 from width = "["
        Add 1 to width = " ' " (button to the left of enter)
        Subtract 1 from width = ";" 
    ]]--
function OnLoad()
    LoadVariables()
    LoadMenus()
end
function LoadVariables()
    savedText = {}
    savedCoordinates = {}
    particlespeeds = {}
    saveToParticleLog = {}
    saveToBuffLog = {}
    spells = {}
    count = 0
    range = 250   -- Config.Drawings.circularRange
    width = 80   --Config.Drawings.editWidth

    detectorRange = 200
    state = 1
    LOGParticles = false
    LOGBuffs = false
    FindBasicAttack = false
    player = GetMyHero()
end
function LoadMenus()
    Config = scriptConfig("Dekland Info", "Dekland Info")

    Config:addParam("myHero", "My Hero Name: ", SCRIPT_PARAM_INFO, myHero.charName)

    Config:addSubMenu("Spell", "Spells")
    Config.Spells:addParam("q", "Activate (Q) F1", SCRIPT_PARAM_ONKEYTOGGLE, false, 112)
    Config.Spells:addParam("w", "Activate (W) F2", SCRIPT_PARAM_ONKEYTOGGLE, false, 113)
    Config.Spells:addParam("e", "Activate (E) F3", SCRIPT_PARAM_ONKEYTOGGLE, false, 114)
    Config.Spells:addParam("r", "Activate (R) F4", SCRIPT_PARAM_ONKEYTOGGLE, false, 115)
    Config.Spells:addParam("i", "Activate (Items)", SCRIPT_PARAM_ONKEYTOGGLE, false, 73)

    Config:addSubMenu("Print", "Prints")
    Config.Prints:addParam("break0", "--------Self----------", SCRIPT_PARAM_INFO, "")
    Config.Prints:addParam("GainedBuff", "Print Gained buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("LostBuff", "Print Lost buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("UpdateBuff", "Print Updated buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("break", "--------Ally----------", SCRIPT_PARAM_INFO, "")
    Config.Prints:addParam("allyGainedBuff", "Print Ally Gained buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("allyLostBuff", "Print Ally Lost buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("allyUpdateBuff", "Print Ally Updated buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("allyRange", "Only Allies In Range", SCRIPT_PARAM_SLICE, 1000, 1, 25000, 0)
    Config.Prints:addParam("break1", "--------Enemy----------", SCRIPT_PARAM_INFO, "")
    Config.Prints:addParam("enemyGainedBuff", "Print Enemy Gained buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("enemyLostBuff", "Print Enemy Lost buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("enemyUpdateBuff", "Print Enemy Updated buffs", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("enemyRange", "Only Enemies In Range", SCRIPT_PARAM_SLICE, 1000, 1, 25000, 0)
    Config.Prints:addParam("break2", "---------All---------", SCRIPT_PARAM_INFO, "")
    Config.Prints:addParam("OnProcessSpell", "Print My Processed Spells", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("OnProcessSpellOthers", "Print Other Processed Spells", SCRIPT_PARAM_ONOFF, false)
    Config.Prints:addParam("processRange", "Only Process Spells in Range", SCRIPT_PARAM_SLICE, 1000, 1, 25000, 0)

    Config:addSubMenu("Drawing", "Drawings")
    Config.Drawings:addParam("rangeOnMouse", "Draw Range on Mouse POS", SCRIPT_PARAM_ONOFF, false)

    Config.Drawings:addSubMenu("Circular Ranges", "Ranges")
    Config.Drawings.Ranges:addParam("drawRange", "Draw Circular Range", SCRIPT_PARAM_ONOFF, false)
    Config.Drawings.Ranges:addParam("currentRange", "Current Range",  SCRIPT_PARAM_INFO, range)
    Config.Drawings.Ranges:addParam("addRangeBig", "Add 25 Range",  SCRIPT_PARAM_INFO, "=")
    Config.Drawings.Ranges:addParam("subRangeBig", "Subtract 25 Range",  SCRIPT_PARAM_INFO, "-")
    Config.Drawings.Ranges:addParam("addRangeSmall", "Add 1 Range",  SCRIPT_PARAM_INFO, "+ Numpad")
    Config.Drawings.Ranges:addParam("subRangeSmall", "Subtract 1 Range",  SCRIPT_PARAM_INFO, "- Numpad")

    Config.Drawings:addSubMenu("Line Width", "Width")
    Config.Drawings.Width:addParam("drawWidth", "Draw Spell Width Indicator", SCRIPT_PARAM_ONOFF, false)
    Config.Drawings.Width:addParam("currentWidth", "Current Width",  SCRIPT_PARAM_INFO, width)
    Config.Drawings.Width:addParam("addWidthBig", "Add 25 Width",  SCRIPT_PARAM_INFO, "]")
    Config.Drawings.Width:addParam("subWidthBig", "Subtract 25 Width",  SCRIPT_PARAM_INFO, "[")
    Config.Drawings.Width:addParam("addWidthmall", "Add 1 Width",  SCRIPT_PARAM_INFO, "'")
    Config.Drawings.Width:addParam("subWidthmall", "Subtract 1 Width",  SCRIPT_PARAM_INFO, ";")


end

function table.copy(from)
    if from == nil or type(from) ~= "table" then return end
    local to = {}
    for k, v in pairs(from) do
        to[k] = v
    end
    return to
end

function math.round(num, idp)
    if type(num)~="number" then return end
    local mult = math.floor(10 ^ (idp or 0))
    local value = (num >= 0 and math.floor(num * mult + 0.5) / mult or math.ceil(num * mult - 0.5) / mult)
    return tonumber(string.format("%." .. (idp or 0) .. "f", value))
end

local function getDistance(xo, zo, x1, z1)
    return math.sqrt((xo - x1) ^ 2 + (zo - z1) ^ 2)
end

local function getObjects(x, z, range)
    local objects = {}
    for i = 1, objManager.maxObjects, 1 do
        local object = objManager:getObject(i)
        if object and (getDistance(object.x, object.z, x, z) or math.huge) < range then
            table.insert(objects, object)
        end
    end
    return objects
end

local function getHeros()
    local heros = {}
    for i = 1, heroManager.iCount, 1 do
        local hero = heroManager:getHero(i)
        if hero then
            table.insert(heros, hero)
        end
    end
    return heros
end

local function findname(table, name)
    for i, v in ipairs(table) do
        if v[1] == name then return true, i end
    end
    return false, nil
end

local function isBuffValid(buff)
    return buff.startT<=GetGameTimer() and buff.endT>=GetGameTimer()
end
local function saveBuffs()
    local function inBuffList(charName, buffname)
        for i, v in ipairs(saveToBuffLog) do
            if v[1] == charName then
                for i, k in ipairs(v) do
                    if k == buffname then return true end
                end
            end
        end
        return false
    end
    for i, hero in ipairs(getHeros()) do
        for i = 1, hero.buffCount, 1 do
            local buff = hero:getBuff(i)
            if isBuffValid(buff) then
                local foundname, index = findname(saveToBuffLog, hero.charName)
                if not foundname then table.insert(saveToBuffLog, { hero.charName, buff.name })
                else if not inBuffList(hero.charName, buff) then table.insert(saveToBuffLog[index], buff.name) end
                end
            end
        end
    end
end


local function DrawHitBox(object, linesize, linecolor)
    local linesize, linecolor = linesize or 1, linecolor or 4294967295
    if object and object.minBBox then
        local x1,y1, onscreen = get2DFrom3D(object.minBBox.x,object.minBBox.y,object.minBBox.z)
        if onscreen then
            local x2,y2 = get2DFrom3D(object.minBBox.x,object.minBBox.y,object.maxBBox.z)
            local x3,y3 = get2DFrom3D(object.maxBBox.x,object.minBBox.y,object.maxBBox.z)
            local x4,y4 = get2DFrom3D(object.maxBBox.x,object.minBBox.y,object.minBBox.z)
            local x5,y5 = get2DFrom3D(object.minBBox.x,object.maxBBox.y,object.minBBox.z)
            local x6,y6 = get2DFrom3D(object.minBBox.x,object.maxBBox.y,object.maxBBox.z)
            local x7,y7 = get2DFrom3D(object.maxBBox.x,object.maxBBox.y,object.maxBBox.z)
            local x8,y8 = get2DFrom3D(object.maxBBox.x,object.maxBBox.y,object.minBBox.z)
            DrawLine(x1,y1,x2,y2,linesize,linecolor)
            DrawLine(x2,y2,x3,y3,linesize,linecolor)
            DrawLine(x3,y3,x4,y4,linesize,linecolor)
            DrawLine(x4,y4,x1,y1,linesize,linecolor)
            DrawLine(x1,y1,x5,y5,linesize,linecolor)
            DrawLine(x2,y2,x6,y6,linesize,linecolor)
            DrawLine(x3,y3,x7,y7,linesize,linecolor)
            DrawLine(x4,y4,x8,y8,linesize,linecolor)
            DrawLine(x5,y5,x6,y6,linesize,linecolor)
            DrawLine(x6,y6,x7,y7,linesize,linecolor)
            DrawLine(x7,y7,x8,y8,linesize,linecolor)
            DrawLine(x8,y8,x5,y5,linesize,linecolor)
        end
    end
end
function OnGainBuff(unit, buff)
    if unit.isMe and Config.Prints.GainedBuff then
        print(buff.name..": Gained Buff")
    end
    if unit and not unit.isMe and unit.team == myHero.team and Config.Prints.allyGainedBuff and GetDistance(unit)<=Config.Prints.allyRange then
        print(buff.name..": Ally Gained Buff")
    end
    if unit and unit.team == TEAM_ENEMY and Config.Prints.enemyGainedBuff and GetDistance(unit)<=Config.Prints.enemyRange then
        print(buff.name..": Enemy Gained Buff")
    end
end
function OnLoseBuff(unit, buff)
    if unit.isMe and Config.Prints.LostBuff then
        print(buff.name..": Lose Buff")
    end
    if unit and not unit.isMe and unit.team == myHero.team and Config.Prints.allyLostBuff and GetDistance(unit)<=Config.Prints.allyRange then
        print(buff.name..": Ally Lost Buff")
    end
    if unit and unit.team == TEAM_ENEMY and Config.Prints.enemyLostBuff and GetDistance(unit)<=Config.Prints.enemyRange then
        print(buff.name..": Enemy Lost Buff")
    end
end
function OnUpdateBuff(unit, buff)
    if unit.isMe and Config.Prints.UpdateBuff then
        print(buff.stack..": Buff Stack Update")
        print(buff.name..": Buff Update")
    end
    if unit and not unit.isMe and unit.team == myHero.team  and Config.Prints.allyUpdateBuff and GetDistance(unit)<=Config.Prints.allyRange then
        print(buff.stack..": Ally Buff Stack Update")
        print(buff.name..": Ally Buff Update")
    end
    if unit and unit.team == TEAM_ENEMY  and Config.Prints.enemyUpdateBuff and GetDistance(unit)<=Config.Prints.enemyRange then
        print(buff.stack..": Enemy Buff Stack Update")
        print(buff.name..": Enemy Buff Update")
    end
end
function OnDraw()
    local function drawWindow(x, y)
        local function getText()
            savedText = {}
            local function saveText(STRING, ARGB)
                local textTable = { STRING, ARGB }
                table.insert(savedText, textTable)
            end
            DrawCircle(mousePos.x, mousePos.y, mousePos.z, detectorRange, 0xFFFFFF)
            for i, object in ipairs(getObjects(mousePos.x, mousePos.z, detectorRange)) do
                local ps = 0
                local vector = {}
                for i, v in ipairs(particlespeeds) do
                    if v[1] == object.name then ps = v[3] vector = v[2] break end
                end
                local teams = { [TEAM_NONE] = "TEAM_NONE", [TEAM_NEUTRAL] = "TEAM_NEUTRAL", [TEAM_BLUE] = "TEAM_BLUE", [TEAM_RED] = "TEAM_RED" }
                local team = teams[object.team] or ""
                saveText(string.format("%s %s Type:%s", object.name, team, object.type), 0xFFD61123)
                if object.charName and #object.charName < 30 and #object.charName > 1 and not string.find(object.name, "Particles") then
                    saveText(string.format("charName:%s", object.charName), 0xFFD61123)
                end
                if object.type == player.type and object.buffCount then
                    local widht = 0
                    for i = 1, object.buffCount, 1 do
                        local buff = object:getBuff(i)
                        if isBuffValid(buff) then saveText(buff.name, 0xFF9EDC24) end
                    end
                end

                local ARGB = 0xFFF3FD00
                if ps and ps ~= 0 then
                    saveText(string.format("currentSpeed: %s X:%s Z:%s", math.round(ps), math.round(vector[1], 3), math.round(vector[2], 3)), ARGB)
                end

                if object.x and object.y and object.z then
                    saveText(string.format("x:%s y:%s z:%s", math.round(object.x), math.round(object.y), math.round(object.z)), ARGB)
                end
                if (object.health and object.health ~= 0) or (object.maxHealth and object.maxHealth ~= 0) then
                    saveText(string.format("HP:%s / %s +%s/s", math.round(object.health) or "?", math.round(object.maxHealth) or "?", math.round(object.hpRegen) or "?"), ARGB)
                end

                if (object.mana and object.mana > 1) or (object.maxMana and object.maxMana) > 1 then
                    saveText(string.format("Mana:%s / %s", math.round(object.mana) or "?", math.round(object.maxMana) or "?"), ARGB)
                end
                if object.ap and object.damage and object.addDamage and (object.ap > 1 or object.damage > 1 or object.addDamage > 1) and not string.find(object.name, "Particles") and not string.find(object.name, "DrawFX") then
                    saveText(string.format("AP:%s DMG:%s addDMG:%s", math.round(object.ap) or "?", math.round(object.damage) or "?", math.round(object.addDamage) or "?"), ARGB)
                end
                if object.magicArmor and object.armor and (object.magicArmor > 1 or object.armor > 1) and not string.find(object.name, "Particles") then
                    saveText(string.format("magicArmor:%s armor:%s", math.round(object.magicArmor) or "?", math.round(object.armor) or "?"), ARGB)
                end
                if object.armorPen and object.armorPenPercent and (object.armorPenPercent > 0 or object.armorPen > 1) and not string.find(object.name, "Particles") then
                    saveText(string.format("armorPen:%s armorPenPercent:%s", math.round(object.armorPen) or "?", object.armorPenPercent * 100) or "?", ARGB)
                end
                if object.magicPen and object.magicPenPercent and (object.magicPenPercent > 0 or object.magicPen > 1) and not string.find(object.name, "Particles") then
                    saveText(string.format("magicPen:%s magicPenPercent:%s", math.round(object.magicPen) or "?", object.magicPenPercent * 100) or "?", ARGB)
                end
                if object.range and object.range > 1 then
                    saveText(string.format("range:%s", math.round(object.range)), ARGB)
                end
            end
        end

        local function printSavedText(xm, ym)
            local height = 0
            for i, v in ipairs(savedText) do
                DrawText(v[1], 12, xm + 40, ym + height, v[2])
                height = height + 11
            end
        end
        if state == 2 then
            getText()
        end
        if state == 2 or state == 3 then
            printSavedText(x, y)
        end
    end

    if LOGParticles == true then DrawText("Particle LOG activated (range=2000), press * to save", 12, 10, 10, 0xFFFFFF00) end
    drawWindow(GetCursorPos().x, GetCursorPos().y)
    --------------------------------------Skill information-----------------------------------------------------------------
    if Config.Spells.q then
        DrawText(tostring("Q Stats"),15,100,110,ARGB(255,10,255,20))
        DrawText(tostring("Q Spell Name >> "..myHero:GetSpellData(_Q).name),15,100,125,ARGB(255,248,255,20))
        DrawText(tostring("Q Spell Range >> "..myHero:GetSpellData(_Q).range),15,100,140,ARGB(255,248,255,20))
        DrawText(tostring("Q Spell Range + minBox >> "..myHero:GetSpellData(_Q).range + GetDistance(myHero.minBBox)/2),15,100,155,ARGB(255,248,255,20))
        DrawText(tostring("Missile Speed >> "..myHero:GetSpellData(_Q).missileSpeed),15,100,170,ARGB(255,248,255,20))
        DrawText(tostring("Line width >> "..myHero:GetSpellData(_Q).lineWidth),15,100,185,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Speed >> "..myHero:GetSpellData(_Q).missileMinSpeed),15,100,200,ARGB(255,248,255,20))
        DrawText(tostring("Missile Max Speed >> "..myHero:GetSpellData(_Q).missileMaxSpeed),15,100,215,ARGB(255,248,255,20))
        DrawText(tostring("Missile Fixed Travel Time >> "..myHero:GetSpellData(_Q).missileFixedTravelTime),15,100,230,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Travel Time >> "..myHero:GetSpellData(_Q).missileMinTravelTime),15,100,245,ARGB(255,248,255,20))
        DrawText(tostring("Missile LifeTime >> "..myHero:GetSpellData(_Q).missileLifeTime),15,100,260,ARGB(255,248,255,20))
        DrawText(tostring("Missile Accel >> "..myHero:GetSpellData(_Q).missileAccel),15,100,275,ARGB(255,248,255,20))
        DrawText(tostring("Missile Perception Bubble Radius >> "..myHero:GetSpellData(_Q).missilePerceptionBubbleRadius),15,100,290,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius >> "..myHero:GetSpellData(_Q).castRadius),15,100,305,ARGB(255,248,255,20))
        DrawText(tostring("Cast Range Display Overide >> "..myHero:GetSpellData(_Q).castRangeDisplayOverride),15,100,320,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius Secondary >> "..myHero:GetSpellData(_Q).castRadiusSecondary),15,100,335,ARGB(255,248,255,20))
        DrawText(tostring("Cast Type >> "..myHero:GetSpellData(_Q).castType),15,100,350,ARGB(255,248,255,20))
        DrawText(tostring("Cast Frame >> "..myHero:GetSpellData(_Q).castFrame),15,100,365,ARGB(255,248,255,20))
        DrawText(tostring("Delay Cast Off Set Percent >> "..myHero:GetSpellData(_Q).delayCastOffsetPercent),15,100,380,ARGB(255,248,255,20))
        DrawText(tostring("Delay Total Time Percent >> "..myHero:GetSpellData(_Q).delayTotalTimePercent),15,100,395,ARGB(255,248,255,20))
        DrawText(tostring("Cast Target Additional Units Radius >> "..myHero:GetSpellData(_Q).castTargetAdditionalUnitsRadius),15,100,410,ARGB(255,248,255,20))
        DrawText(tostring("Line Drag Length >> "..myHero:GetSpellData(_Q).lineDragLength),15,100,425,ARGB(255,248,255,20))
        DrawText(tostring("Toggle State >> "..myHero:GetSpellData(_Q).toggleState),15,100,440,ARGB(255,248,255,20))
        DrawText(tostring("Total Cooldown >> "..myHero:GetSpellData(_Q).totalCooldown),15,100,455,ARGB(255,248,255,20))
    end
    if Config.Spells.w then
        DrawText(tostring("W Stats"),15,450,110,ARGB(255,10,255,20))
        DrawText(tostring("W Spell Name >> "..myHero:GetSpellData(_W).name),15,450,125,ARGB(255,248,255,20))
        DrawText(tostring("W Spell Range >> "..myHero:GetSpellData(_W).range),15,450,140,ARGB(255,248,255,20))
        DrawText(tostring("W Spell Range + minBox >> "..myHero:GetSpellData(_W).range + GetDistance(myHero.minBBox)/2),15,450,155,ARGB(255,248,255,20))
        DrawText(tostring("Missile Speed >> "..myHero:GetSpellData(_W).missileSpeed),15,450,170,ARGB(255,248,255,20))
        DrawText(tostring("Line width >> "..myHero:GetSpellData(_W).lineWidth),15,450,185,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Speed >> "..myHero:GetSpellData(_W).missileMinSpeed),15,450,200,ARGB(255,248,255,20))
        DrawText(tostring("Missile Max Speed >> "..myHero:GetSpellData(_W).missileMaxSpeed),15,450,215,ARGB(255,248,255,20))
        DrawText(tostring("Missile Fixed Travel Time >> "..myHero:GetSpellData(_W).missileFixedTravelTime),15,450,230,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Travel Time >> "..myHero:GetSpellData(_W).missileMinTravelTime),15,450,245,ARGB(255,248,255,20))
        DrawText(tostring("Missile LifeTime >> "..myHero:GetSpellData(_W).missileLifeTime),15,450,260,ARGB(255,248,255,20))
        DrawText(tostring("Missile Accel >> "..myHero:GetSpellData(_W).missileAccel),15,450,275,ARGB(255,248,255,20))
        DrawText(tostring("Missile Perception Bubble Radius >> "..myHero:GetSpellData(_W).missilePerceptionBubbleRadius),15,450,290,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius >> "..myHero:GetSpellData(_W).castRadius),15,450,305,ARGB(255,248,255,20))
        DrawText(tostring("Cast Range Display Overide >> "..myHero:GetSpellData(_W).castRangeDisplayOverride),15,450,320,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius Secondary >> "..myHero:GetSpellData(_W).castRadiusSecondary),15,450,335,ARGB(255,248,255,20))
        DrawText(tostring("Cast Type >> "..myHero:GetSpellData(_W).castType),15,450,350,ARGB(255,248,255,20))
        DrawText(tostring("Cast Frame >> "..myHero:GetSpellData(_W).castFrame),15,450,365,ARGB(255,248,255,20))
        DrawText(tostring("Delay Cast Off Set Percent >> "..myHero:GetSpellData(_W).delayCastOffsetPercent),15,450,380,ARGB(255,248,255,20))
        DrawText(tostring("Delay Total Time Percent >> "..myHero:GetSpellData(_W).delayTotalTimePercent),15,450,395,ARGB(255,248,255,20))
        DrawText(tostring("Cast Target Additional Units Radius >> "..myHero:GetSpellData(_W).castTargetAdditionalUnitsRadius),15,450,410,ARGB(255,248,255,20))
        DrawText(tostring("Line Drag Length >> "..myHero:GetSpellData(_W).lineDragLength),15,450,425,ARGB(255,248,255,20))
        DrawText(tostring("Toggle State >> "..myHero:GetSpellData(_W).toggleState),15,450,440,ARGB(255,248,255,20))
        DrawText(tostring("Total Cooldown >> "..myHero:GetSpellData(_W).totalCooldown),15,450,455,ARGB(255,248,255,20))
    end
    if Config.Spells.e then
        DrawText(tostring("E Stats"),15,800,110,ARGB(255,10,255,20))
        DrawText(tostring("E Spell Name >> "..myHero:GetSpellData(_E).name),15,800,125,ARGB(255,248,255,20))
        DrawText(tostring("E Spell Range >> "..myHero:GetSpellData(_E).range),15,800,140,ARGB(255,248,255,20))
        DrawText(tostring("E Spell Range + minBox >> "..myHero:GetSpellData(_E).range + GetDistance(myHero.minBBox)/2),15,800,155,ARGB(255,248,255,20))
        DrawText(tostring("Missile Speed >> "..myHero:GetSpellData(_E).missileSpeed),15,800,170,ARGB(255,248,255,20))
        DrawText(tostring("Line width >> "..myHero:GetSpellData(_E).lineWidth),15,800,185,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Speed >> "..myHero:GetSpellData(_E).missileMinSpeed),15,800,200,ARGB(255,248,255,20))
        DrawText(tostring("Missile Max Speed >> "..myHero:GetSpellData(_E).missileMaxSpeed),15,800,215,ARGB(255,248,255,20))
        DrawText(tostring("Missile Fixed Travel Time >> "..myHero:GetSpellData(_E).missileFixedTravelTime),15,800,230,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Travel Time >> "..myHero:GetSpellData(_E).missileMinTravelTime),15,800,245,ARGB(255,248,255,20))
        DrawText(tostring("Missile LifeTime >> "..myHero:GetSpellData(_E).missileLifeTime),15,800,260,ARGB(255,248,255,20))
        DrawText(tostring("Missile Accel >> "..myHero:GetSpellData(_E).missileAccel),15,800,275,ARGB(255,248,255,20))
        DrawText(tostring("Missile Perception Bubble Radius >> "..myHero:GetSpellData(_E).missilePerceptionBubbleRadius),15,800,290,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius >> "..myHero:GetSpellData(_E).castRadius),15,800,305,ARGB(255,248,255,20))
        DrawText(tostring("Cast Range Display Overide >> "..myHero:GetSpellData(_E).castRangeDisplayOverride),15,800,320,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius Secondary >> "..myHero:GetSpellData(_E).castRadiusSecondary),15,800,335,ARGB(255,248,255,20))
        DrawText(tostring("Cast Type >> "..myHero:GetSpellData(_E).castType),15,800,350,ARGB(255,248,255,20))
        DrawText(tostring("Cast Frame >> "..myHero:GetSpellData(_E).castFrame),15,800,365,ARGB(255,248,255,20))
        DrawText(tostring("Delay Cast Off Set Percent >> "..myHero:GetSpellData(_E).delayCastOffsetPercent),15,800,380,ARGB(255,248,255,20))
        DrawText(tostring("Delay Total Time Percent >> "..myHero:GetSpellData(_E).delayTotalTimePercent),15,800,395,ARGB(255,248,255,20))
        DrawText(tostring("Cast Target Additional Units Radius >> "..myHero:GetSpellData(_E).castTargetAdditionalUnitsRadius),15,800,410,ARGB(255,248,255,20))
        DrawText(tostring("Line Drag Length >> "..myHero:GetSpellData(_E).lineDragLength),15,800,425,ARGB(255,248,255,20))
        DrawText(tostring("Toggle State >> "..myHero:GetSpellData(_E).toggleState),15,800,440,ARGB(255,248,255,20))
        DrawText(tostring("Total Cooldown >> "..myHero:GetSpellData(_E).totalCooldown),15,800,455,ARGB(255,248,255,20))
    end
    if Config.Spells.r then
        DrawText(tostring("R Stats"),15,1200,110,ARGB(255,10,255,20))
        DrawText(tostring("R Spell Name >> "..myHero:GetSpellData(_R).name),15,1200,125,ARGB(255,248,255,20))
        DrawText(tostring("R Spell Range >> "..myHero:GetSpellData(_R).range),15,1200,140,ARGB(255,248,255,20))
        DrawText(tostring("R Spell Range + minBox >> "..myHero:GetSpellData(_R).range + GetDistance(myHero.minBBox)/2),15,1200,155,ARGB(255,248,255,20))
        DrawText(tostring("Missile Speed >> "..myHero:GetSpellData(_R).missileSpeed),15,1200,170,ARGB(255,248,255,20))
        DrawText(tostring("Line width >> "..myHero:GetSpellData(_R).lineWidth),15,1200,185,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Speed >> "..myHero:GetSpellData(_R).missileMinSpeed),15,1200,200,ARGB(255,248,255,20))
        DrawText(tostring("Missile Max Speed >> "..myHero:GetSpellData(_R).missileMaxSpeed),15,1200,215,ARGB(255,248,255,20))
        DrawText(tostring("Missile Fixed Travel Time >> "..myHero:GetSpellData(_R).missileFixedTravelTime),15,1200,230,ARGB(255,248,255,20))
        DrawText(tostring("Missile Min Travel Time >> "..myHero:GetSpellData(_R).missileMinTravelTime),15,1200,245,ARGB(255,248,255,20))
        DrawText(tostring("Missile LifeTime >> "..myHero:GetSpellData(_R).missileLifeTime),15,1200,260,ARGB(255,248,255,20))
        DrawText(tostring("Missile Accel >> "..myHero:GetSpellData(_R).missileAccel),15,1200,275,ARGB(255,248,255,20))
        DrawText(tostring("Missile Perception Bubble Radius >> "..myHero:GetSpellData(_R).missilePerceptionBubbleRadius),15,1200,290,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius >> "..myHero:GetSpellData(_R).castRadius),15,1200,305,ARGB(255,248,255,20))
        DrawText(tostring("Cast Range Display Overide >> "..myHero:GetSpellData(_R).castRangeDisplayOverride),15,1200,320,ARGB(255,248,255,20))
        DrawText(tostring("Cast Radius Secondary >> "..myHero:GetSpellData(_R).castRadiusSecondary),15,1200,335,ARGB(255,248,255,20))
        DrawText(tostring("Cast Type >> "..myHero:GetSpellData(_R).castType),15,1200,350,ARGB(255,248,255,20))
        DrawText(tostring("Cast Frame >> "..myHero:GetSpellData(_R).castFrame),15,1200,365,ARGB(255,248,255,20))
        DrawText(tostring("Delay Cast Off Set Percent >> "..myHero:GetSpellData(_R).delayCastOffsetPercent),15,1200,380,ARGB(255,248,255,20))
        DrawText(tostring("Delay Total Time Percent >> "..myHero:GetSpellData(_R).delayTotalTimePercent),15,1200,395,ARGB(255,248,255,20))
        DrawText(tostring("Cast Target Additional Units Radius >> "..myHero:GetSpellData(_R).castTargetAdditionalUnitsRadius),15,1200,410,ARGB(255,248,255,20))
        DrawText(tostring("Line Drag Length >> "..myHero:GetSpellData(_R).lineDragLength),15,1200,425,ARGB(255,248,255,20))
        DrawText(tostring("Toggle State >> "..myHero:GetSpellData(_R).toggleState),15,1200,440,ARGB(255,248,255,20))
        DrawText(tostring("Total Cooldown >> "..myHero:GetSpellData(_R).totalCooldown),15,1200,455,ARGB(255,248,255,20))
    end
    if Config.Spells.i then
        DrawText(tostring("Item Slot Stats"),15,100,470,ARGB(255,10,255,20))
        if myHero:getItem(ITEM_1) ~=nil then
            DrawText(tostring("Item Slot 1: "..myHero:getItem(ITEM_1).name.." - ID: "..myHero:getItem(ITEM_1).id),15,100,485,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 1 is Empty"),15,100,485,ARGB(255,10,255,20))
        end
        if myHero:getItem(ITEM_2) ~=nil then
            DrawText(tostring("Item Slot 2: "..myHero:getItem(ITEM_2).name.." - ID: "..myHero:getItem(ITEM_2).id),15,100,500,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 2 is Empty"),15,100,500,ARGB(255,10,255,20))
        end
        if myHero:getItem(ITEM_3) ~=nil then
            DrawText(tostring("Item Slot 3: "..myHero:getItem(ITEM_3).name.." - ID: "..myHero:getItem(ITEM_3).id),15,100,515,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 3 is Empty"),15,100,515,ARGB(255,10,255,20))
        end
        if myHero:getItem(ITEM_4) ~=nil then
            DrawText(tostring("Item Slot 4: "..myHero:getItem(ITEM_4).name.." - ID: "..myHero:getItem(ITEM_4).id),15,100,530,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 4 is Empty"),15,100,530,ARGB(255,10,255,20))
        end
        if myHero:getItem(ITEM_5) ~=nil then
            DrawText(tostring("Item Slot 5: "..myHero:getItem(ITEM_5).name.." - ID: "..myHero:getItem(ITEM_5).id),15,100,545,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 5 is Empty"),15,100,545,ARGB(255,10,255,20))
        end
        if myHero:getItem(ITEM_6) ~=nil then
            DrawText(tostring("Item Slot 6: "..myHero:getItem(ITEM_6).name.." - ID: "..myHero:getItem(ITEM_6).id),15,100,560,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 6 is Empty"),15,100,560,ARGB(255,10,255,20))
        end
        if myHero:getItem(ITEM_7) ~=nil then
            DrawText(tostring("Item Slot 7: "..myHero:getItem(ITEM_7).name.." - ID: "..myHero:getItem(ITEM_7).id),15,100,575,ARGB(255,10,255,20))
        else
            DrawText(tostring("Item Slot 7 is Empty"),15,100,575,ARGB(255,10,255,20))
        end
    end
    if Config.Drawings.Width.drawWidth then
        DrawLine3D(myHero.x, myHero.y, myHero.z, mousePos.x, mousePos.y, mousePos.z, width, ARGB(150,240,50,255))
    end
    if Config.Drawings.rangeOnMouse then
        local Distance = math.ceil(GetDistance(myHero.visionPos, mousePos))
        DrawText3D("Range: "..Distance, mousePos.x, mousePos.y-200, mousePos.z, 20, ARGB(255,240,50,50), true)
    end
    if Config.Drawings.Ranges.drawRange then
        DrawCircle(myHero.x, myHero.y, myHero.z, range, ARGB(255,154,125,36))
    end
end

function OnWndMsg(msg, key)
    --Mouse
    if msg == WM_LBUTTONDOWN and state == 2 then state = 3 return end
    if msg == WM_LBUTTONDOWN and state == 3 then state = 1 return end
    --Keboard (Numpad)
    if key == 96 and msg == KEY_DOWN and state ~= 3 then state = 2 -- 0
    elseif key == 96 and msg == KEY_UP and state == 2 then state = 1 -- 0
    elseif key == 107 and msg == KEY_DOWN and state == 2 and detectorRange <= 800 then detectorRange = detectorRange + 50 -- +
    elseif key == 109 and msg == KEY_DOWN and state == 2 and detectorRange >= 100 then detectorRange = detectorRange - 50 -- -
    elseif key == 110 and msg == KEY_DOWN then -- ,
        if #savedText > 0 then
            local file, error = assert(io.open(SCRIPT_PATH .. "detector.log", "a+"))
            if error then return error end
            file:write("------------" .. os.date("%c") .. "------------\n")
            for i, v in ipairs(savedText) do
                file:write(v[1] .. "\n")
            end
            file:close()
            PrintChat("Saved Information To File")
        end
    elseif key == 111 and msg == KEY_DOWN then -- /
        PrintChat("Saved Buffs to File")
        saveBuffs()
        if #saveToBuffLog > 0 then
            local file, error = assert(io.open(SCRIPT_PATH .. "detectorbuffs.log", "a+"))
            if error then return error end
            file:write("------------" .. os.date("%c") .. "------------\n")
            for i, v in ipairs(saveToBuffLog) do
                for i, v in ipairs(v) do
                    file:write(v)
                    if i == 1 then file:write(" : ") else file:write("; ") end
                end
                file:write("\n")
            end
            file:close()
            saveToBuffLog = {}
        end
    elseif key == 106 and msg == KEY_DOWN then -- *
        if LOGParticles == false then LOGParticles = true
        else
            LOGParticles = false
            if #saveToParticleLog > 0 then
                local file, error = assert(io.open(SCRIPT_PATH .. "detectorparticles.log", "a+"))
                if error then return error end
                file:write("------------" .. os.date("%c") .. "------------\n")
                for i, v in ipairs(saveToParticleLog) do
                    for i, v in ipairs(v) do
                        file:write(v)
                        if i == 1 then file:write(" : ") else file:write("; ") end
                    end
                    file:write("\n")
                end
                file:close()
                saveToParticleLog = {}
            end
        end
    end
    if msg == KEY_DOWN then
        ----------------Range--------------
        if key == 187 then 
            range = range + 25
            print("New Range: "..tostring(range))
        end 
        if key == 189 then
            range = range - 25
            print("New Range: "..tostring(range))
        end
        if key == 107 then 
            range = range + 1
            print("New Range: "..tostring(range))
        end 
        if key == 109 then
            range = range - 1
            print("New Range: "..tostring(range))
        end
        ---------------Width-----------------
        if key == 221 then 
            width = width + 10
            print("New Width: "..tostring(width))
        end 
        if key == 219 then
            width = width - 10
            print("New Width: "..tostring(width))
        end
        if key == 222 then 
            width = width + 1
            print("New Width: "..tostring(width))
        end 
        if key == 186 then
            width = width - 1
            print("New Width: "..tostring(width))
        end
    end
end

function OnTick()
    if not lastUpdated or os.clock() - lastUpdated > 0.25 then
        lastUpdated = os.clock()
        if state == 2 or LOGParticles then
            local oldCoordinates = table.copy(savedCoordinates)
            savedCoordinates = {}
            particlespeeds = {}
            for i, object in ipairs(getObjects(mousePos.x, mousePos.z, 2000)) do
                for i, v in ipairs(oldCoordinates) do
                    if v[1] == object.name then
                        local distance = getDistance(object.x, object.z, v[4], v[6])
                        local particlespeed = distance / (os.clock() - v[3])
                        local nvector = { (v[4] - object.x) / distance, (v[6] - object.z) / distance }
                        if particlespeed < 5000 then table.insert(particlespeeds, { object.name, nvector, particlespeed, distance }) break end
                    end
                end
                table.insert(savedCoordinates, { object.name, object.networkId, os.clock(), object.x, object.y, object.z })
            end
        end
        if LOGParticles == true then
            local particlespeeds = table.copy(particlespeeds)
            for i, particle in ipairs(particlespeeds) do
                if particle[3] > 10 then
                    local foundname, index = findname(saveToParticleLog, particle[1])
                    if not foundname then table.insert(saveToParticleLog, { particle[1], math.round(particle[3]) })
                    else table.insert(saveToParticleLog[index], math.round(particle[3]))
                    end
                end
            end
        end
        if LOGBuffs == true then saveBuffs() end
    end
    if width ~= Config.Drawings.Width.currentWidth then
        Config.Drawings.Width.currentWidth = width
    end
    if range ~= Config.Drawings.Ranges.currentRange then
        Config.Drawings.Ranges.currentRange = range
    end
end

function OnDeleteObj(object)
    if LOGParticles then
        for k, v in pairs(spells) do
            if v.particles[object.name] and not v.particles[object.name].speed then
                spells[k].particles[object.name].speed = getDistance(object.x, object.z, v.particles[object.name].x, v.particles[object.name].z) / (GetTickCount() - v.particles[object.name].t)
                PrintChat("Speed: " .. spells[k].particles[object.name].speed .. " (" .. object.name .. ")")
                PrintChat("Range: " .. math.floor(getDistance(object.x, object.z, v.particles[object.name].x , v.particles[object.name].z )) .. " (" .. object.name .. ")")
            end
        end
    end
end

function OnCreateObj(object)
    if LOGParticles then
        for k, v in pairs(spells) do
            if not spells[k].particles[object.name] and GetTickCount() - v.t < 1200 and (getDistance(player.x, player.z, object.x, object.z) or math.huge) < 300 and not string.find(object.name, "/a") and not string.find(object.name, "DrawFX") then
                spells[k].particles[object.name] = { t = GetTickCount(), x = object.x, z = object.z, delay = GetTickCount() - v.t }
                PrintChat("Delay: " .. spells[k].particles[object.name].delay .. " (" .. object.name .. ")")
            end
        end
    end
end

function OnProcessSpell(object, spellProc)
    if LOGParticles then
        if object.name == player.name and (FindBasicAttack or not string.find(spellProc.name, "BasicAttack")) then
            spells[spellProc.name] = { t = GetTickCount(), particles = {} }
            PrintChat(spellProc.name)
        end
    end
    if object.isMe and Config.Prints.OnProcessSpell then
        print(spellProc.name.. ": Spell processed")
    end
    if not object.isMe and Config.Prints.OnProcessSpellOthers and GetDistance(object)<=Config.Prints.processRange then
        print(spellProc.name.. ": Spell processed")
    end
end
