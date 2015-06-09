if myHero.charName ~= "Nasus" then return end class "ScriptUpdate"
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '3' or '4')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '3' or '4')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:CreateSocket(url)
    if not self.LuaSocket then
		self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.Socket:connect('sx-bol.eu', 80)
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

function ScriptUpdate:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function ScriptUpdate:GetOnlineVersion()
    if self.GotScriptVersion then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        local recv,sent,time = self.Socket:getstats()
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</size>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</s'..'ize>')-1)) + self.File:len()
        end
        self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*self.File:len(),2)..'%)'
    end
    if not (self.Receive or (#self.Snipped > 0)) and self.RecvStarted and self.Size and math.round(100/self.Size*self.File:len(),2) > 95 then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = tonumber(self.File:sub(ContentStart + 1,ContentEnd-1))
            if self.OnlineVersion > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end

function ScriptUpdate:DownloadUpdate()
    if self.GotScriptUpdate then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        local recv,sent,time = self.Socket:getstats()
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1)) + self.File:len()
        end
        self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*self.File:len(),2)..'%)'
    end
    if not (self.Receive or (#self.Snipped > 0)) and self.RecvStarted and math.round(100/self.Size*self.File:len(),2) > 95 then
        self.DownloadStatus = 'Downloading Script (100%)'
        local HeaderEnd, ContentStart = self.File:find('<sc'..'ript>')
        local ContentEnd, _ = self.File:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local f = io.open(self.SavePath,"w+b")
            f:write(self.File:sub(ContentStart + 1,ContentEnd-1))
            f:close()
            if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
            end
        end
        self.GotScriptUpdate = true
    end
end

class 'SnoopDoggNasus'
function SnoopDoggNasus:__init()
	if FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		require("SxOrbWalk")
		self:Msg("Start loading -  GG") 
	else 
		self:Msg("No Sx - No Snoop Dogg Nasus -> Get SxOrbwalk!")
		return 
	end
	self.Version = 0.2
	self.Spells = {
		W = { Range = 599 },
		E = { Range = 649, Width = 400, Speed = 0x62696c62616f, Delay = 0.5 },
		R = { Range = 340 },	
	}
	self.Stacks = 0
	self:LoadMenu()
	self:Msg("Successfull loaded.")
end

function SnoopDoggNasus:LoadMenu()
	self.TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, self.Spells.E.Range, DAMAGE_PHYSICAL)
	self.Minions = minionManager(MINION_ENEMY, self.Spells.E.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.Menu = scriptConfig("Snoop Dogg Nasus", "bilbao")
		SxOrb:LoadToMenu(self.Menu)		
		self.Menu:addSubMenu("Q Settings", "Q")
			self.Menu.Q:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)
			self.Menu.Q:addParam("HarassMode", "Use in HarassMode", SCRIPT_PARAM_ONOFF , true)
			self.Menu.Q:addParam("LaneClear", "Use in LaneClear", SCRIPT_PARAM_ONOFF , true)
			self.Menu.Q:addParam("LastHit", "Use in LastHit", SCRIPT_PARAM_ONOFF , true)
			self.Menu:addSubMenu("W Settings", "W")
			self.Menu.W:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)
			self.Menu.W:addParam("HarassMode", "Use in HarassMode", SCRIPT_PARAM_ONOFF , true)			
		self.Menu:addSubMenu("E Settings", "E")
			self.Menu.E:addParam("FightMode", "Use in FightMode", SCRIPT_PARAM_ONOFF , true)
			self.Menu.E:addParam("HarassMode", "Use in HarassMode", SCRIPT_PARAM_ONOFF , true)
			self.Menu.E:addParam("LaneClear", "Use in LaneClear", SCRIPT_PARAM_ONOFF , true)			
		self.Menu:addSubMenu("R Settings", "R")
			self.Menu.R:addParam("Automatic", "Automatic Ult", SCRIPT_PARAM_ONOFF , true)
			self.Menu.R:addParam("slider", "Health is below %", SCRIPT_PARAM_SLICE, 35, 1, 100, 0)	
	SxOrb:RegisterBeforeAttackCallback(function(target) 
		if ValidTarget(target) and myHero:CanUseSpell(_Q) == READY then				
				if (SxOrb.isLastHit and self.Menu.Q.LastHit) or ((SxOrb.isLaneClear and self.Menu.Q.LaneClear) and (target.health < (getDmg("Q", target, myHero) + myHero.totalDamage + self.Stacks))) or (SxOrb.isFight  and self.Menu.Q.FightMode) or (SxOrb.isHarass  and self.Menu.Q.HarassMode) then
					CastSpell(_Q)
				end				
			if SxOrb.isFight then for i, id in pairs({3128, 3146, 3144, 3142, 3153, 3077, 3074}) do CastItem(id, target) end	end
		end	
	end)
	AddCreateObjCallback(function(obj) if obj.name == "DeathsCaress_nova.troy" then self.Stacks = self.Stacks + 3 end end)
	AddTickCallback(function() 
		if myHero:CanUseSpell(_W) == READY and ((SxOrb.isFight and self.Menu.W.FightMode) or (SxOrb.isHarass and self.Menu.W.HarassMode)) then
			self.TS:update()
			if self.TS.target then CastSpell(_W, self.TS.target) end		
		end
		if myHero:CanUseSpell(_E) == READY and ((SxOrb.isFight and self.Menu.E.FightMode) or (SxOrb.isHarass and self.Menu.E.HarassMode)) then
			self.TS:update()
			if self.TS.target then CastSpell(_E, self.TS.target.x, self.TS.target.z) end		
		end
		if myHero:CanUseSpell(_R) == READY and self.Menu.R.Automatic and (((myHero.health / myHero.maxHealth) * 100) < self.Menu.R.slider) then
			CastSpell(_R)
		end
		if SxOrb.isLaneClear and self.Menu.E.LaneClear and  myHero:CanUseSpell(_E) == READY then
			self.Minions:update()
			local Best, Count = nil, -1
			for i, minion in pairs(self.Minions.objects) do
				local c = self:CountEnemyMinionsAround(minion, self.Spells.E.Width)
				if c >= Count then
					Best, Count = minion, c
				end
			end
			if Best then
				CastSpell(_E, Best.x, Best.z)
			end		
		end	
	end)
end

function SnoopDoggNasus:Msg(m)
	PrintChat("<font color='#40FF00'>SnoopDoggNasus: " .. tostring(m) .. "</font>")
end

function SnoopDoggNasus:CountEnemyMinionsAround(target, range)
	Count = 0
	for i, minion in pairs(self.Minions.objects) do
		if minion and minion.valid and minion.team == TEAM_ENEMY and not minion.dead and not minion.dead and minion.visible and GetDistance(minion, target) < range then Count = Count + 1 end
	end
	return Count
end SnoopDoggNasus()

function OnLoad()
    local ToUpdate = {}
    ToUpdate.Version = 0.2
    ToUpdate.UseHttps = true
    ToUpdate.Host = "raw.githubusercontent.com"
    ToUpdate.VersionPath = "/gbilbao/Bilbao/master/BoL1/SnoopDoggNasus.Version"
    ToUpdate.ScriptPath = "/gbilbao/Bilbao/master/BoL1/SnoopDoggNasus.lua"
    ToUpdate.SavePath = BOL_PATH.."/SnoopDoggNasus.lua"
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#FF794C\"><b>SnoopDoggNasus: </b></font> <font color=\"#FFDFBF\">Updated to "..NewVersion..". Please Reload with 2x F9</b></font>") end
    ToUpdate.CallbackNoUpdate = function(OldVersion) end
    ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#FF794C\"><b>SnoopDoggNasus: </b></font> <font color=\"#FFDFBF\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
    ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#FF794C\"><b>SnoopDoggNasus: </b></font> <font color=\"#FFDFBF\">Error while Downloading. Please try again.</b></font>") end
    ScriptUpdate(ToUpdate.Version,ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
end
assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("VILKHHIMJKN") 
