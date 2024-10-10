local addonName = select(1, ...)
local addon = select(2, ...)

NERAGO_ONY_CHECK = addon;

function addon:onEvent(event, ...)
	local arg1, arg2 = select(1, ...), select(2, ...);
    if event == "ADDON_LOADED" then
        if arg1 == "NeragoCheckOnyCloak" then
            addon:infoMessage("Loaded");
			SlashCmdList["NERAGO_ONY_CHECK"] = function(...) addon:slashCommand(...) end;
			NERAGO_ONY_CHECK1 = "/ony";
			addon.loaded = true;
			addon.checking = false;
        end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if addon.loaded then
			--todo
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		self:checkTarget();
	elseif event == "INSPECT_READY" then
		if addon.loaded then
			addon:inspectReady(arg1);
		end
    end
end

function addon:slashCommand(...)
	self:startCheck();
end

function addon:startCheck()
	local numMembers = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME);
	
	self.status = {};
	
	if IsInRaid() then
		for i = 1, MAX_RAID_MEMBERS do
			-- GetRaidRosterInfo would get us tank status too
			local unitId = "raid" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				-- GetPlayerInfoByGUID
				self.status[guid] = { name = name };
			end
		end
	elseif IsInGroup() then
		for i = 1, numMembers do
			local unitId = "party" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				self.status[guid] = { name = name };
			end
		end
	else
		infoMessage("Not in group")
	end
	
	-- show UI
end

-- TODO not in combat lockdown

function addon:checkTarget()
	local guid = UnitGUID("target");
	if self.checking and self.status[guid] and CanInspect("target", false) then
		ClearInspectPlayer();
		NotifyInspect("target");
	end
end

function addon:inspectReady(inspecteeGUID)
	local itemId = GetInventoryItemID("target", INVSLOT_BACK);
	print("cloak "..tostring(itemId));
end

function addon:createFrame()
	local frame = self.frame;
	if not frame then
		frame = CreateFrame("ScrollFrame", "NeragoCheckOnyFrame", UIParent)
		frame:SetSize(200, 400);
		
		local saved = NERAGO_ONY_CHECK_SAVED;
		if saved and saved.point ~= nil and saved.relativePoint ~= nil and saved.offsetX ~= nil and saved.offsetY ~= nil then
			frame:SetPoint(saved.point, nil, saved.relativePoint, saved.offsetX, saved.offsetY);
		else
			frame:SetPoint("CENTER");
		end
				
		
		frame:SetScript("OnDragStart", function(_, button)
			frame:StartMoving()
		end)
		frame:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing()
			
			local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint();
			NERAGO_ONY_CHECK_SAVED.point = point;
			NERAGO_ONY_CHECK_SAVED.relativePoint = relativePoint;
			NERAGO_ONY_CHECK_SAVED.offsetX = offsetX;
			NERAGO_ONY_CHECK_SAVED.offsetY = offsetY;
		end)
		
		local sizer = CreateFrame("Button", nil, frame);
		sizer:EnableMouse("true");
		sizer:SetPoint("BOTTOMRIGHT");
		sizer:SetSize(16, 16);
		sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
		sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
		sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
		sizer:SetScript("OnMouseDown", function(self)
			frame:StartSizing("BOTTOMRIGHT") 
		end)
		sizer:SetScript("OnMouseUp", function()
			frame:StopMovingOrSizing("BOTTOMRIGHT")
		end)
		
		
		frame:RegisterForDrag("LeftButton");
		frame:EnableMouse(true)
		frame:SetMovable(true);
		frame:SetResizable(true)
		
		self.frame = frame;
	end
	
	self:updateButton();
end

function addon:infoMessage(message)
	print("|cFFE533E5[NeragoPetFood]|r "..tostring(message));
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:RegisterEvent("PLAYER_TARGET_CHANGED");
events:RegisterEvent("INSPECT_READY");
events:SetScript("OnEvent", function(...) self:onEvent(...));
