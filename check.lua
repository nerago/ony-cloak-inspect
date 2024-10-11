local addonName = select(1, ...)
local addon = select(2, ...)

NERAGO_ONY_CHECK = addon;

function addon:onEvent(_, event, ...)
	local arg1, arg2 = select(1, ...), select(2, ...);
    if event == "ADDON_LOADED" then
        if arg1 == "NeragoCheckOnyCloak" then
            addon:infoMessage("Loaded");
			SlashCmdList["NERAGO_ONY_CHECK"] = function(...) addon:slashCommand(...) end;
			SLASH_NERAGO_ONY_CHECK1 = "/ony";
			if not NERAGO_ONY_CHECK_SAVED then
				NERAGO_ONY_CHECK_SAVED = {};
			end
			addon.loaded = true;
			addon.checking = false;
        end
	elseif addon.loaded then
		if event == "GROUP_ROSTER_UPDATE" then
			--todo
		elseif event == "PLAYER_TARGET_CHANGED" then
			self:checkTarget();
		elseif event == "INSPECT_READY" then
			addon:inspectReady(arg1);
		end
    end
end

function addon:slashCommand(...)
	self:createFrame();
	--self:startCheck();
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
				self.status[guid] = { guid = guid, name = name };
			end
		end
	elseif IsInGroup() then
		for i = 1, numMembers do
			local unitId = "party" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				self.status[guid] = { guid = guid, name = name };
			end
		end
	else
		infoMessage("Not in group")
	end
	
	self.dataProvider.RemoveIndexRange(1, self.dataProvider:GetSize());
	for guid, tab in pairs(self.status) do
		self.dataProvider:Insert(tab)
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

local nameIndex = 0;

function addon:initRow(frame, data)
	if not frame.left then
		local buttonName = "NeragoCheckOnyCloakCheckButton"..nameIndex;
		nameIndex = nameIndex + 1
		frame.button = CreateFrame("Button", buttonName, frame, "UIPanelButtonTemplate,InsecureActionButtonTemplate")
		
		frame.button:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
		frame.button:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		frame.button:SetText("Check")
		frame.button:SetSize(50, 20)
		
		frame.left = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		frame.left:SetPoint("LEFT", frame)
		frame.left:SetPoint("RIGHT", frame.button, "LEFT")
		
		--frame.right = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		--frame.right:SetPoint("RIGHT")
	end
	
	frame.left:SetText(data.name)
	frame.button:SetAttribute("type", "target")
	frame.button:SetAttribute("target", data.name)
	--frame.right:SetText("123")
	--frame.right:Hide()
	--frame.button:Show()
	--frame:SetScript("OnMouseDown", function() self:pressPlayer(data) end)
end

function addon:pressPlayer(data)
	
end

function addon:createFrame()
	local dialog = self.frame;
	if not dialog then
		dialog = CreateFrame("Frame", "NeragoCheckOnyFrame", UIParent, "BasicFrameTemplateWithInset");
		dialog.TitleText:SetText("Check Onyixa Cloak")
		dialog:SetSize(200, 400); -- todo saved size
		
		local saved = NERAGO_ONY_CHECK_SAVED;
		if saved and saved.point ~= nil and saved.relativePoint ~= nil and saved.offsetX ~= nil and saved.offsetY ~= nil then
			dialog:SetPoint(saved.point, nil, saved.relativePoint, saved.offsetX, saved.offsetY);
		else
			dialog:SetPoint("CENTER");
		end
		
		dialog:SetScript("OnDragStart", function(_, button)
			dialog:StartMoving()
		end)
		dialog:SetScript("OnDragStop", function()
			dialog:StopMovingOrSizing()
			
			local point, relativeTo, relativePoint, offsetX, offsetY = dialog:GetPoint();
			saved.point = point;
			saved.relativePoint = relativePoint;
			saved.offsetX = offsetX;
			saved.offsetY = offsetY;
		end)
		
		local sizer = CreateFrame("Button", nil, dialog);
		sizer:EnableMouse("true");
		sizer:SetPoint("BOTTOMRIGHT");
		sizer:SetSize(24, 24);
		sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
		sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
		sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
		sizer:SetScript("OnMouseDown", function(self)
			dialog:StartSizing("BOTTOMRIGHT") 
		end)
		sizer:SetScript("OnMouseUp", function()
			dialog:StopMovingOrSizing("BOTTOMRIGHT")
		end)
		
		dialog:RegisterForDrag("LeftButton");
		dialog:EnableMouse(true)
		dialog:SetMovable(true);
		dialog:SetResizable(true)
		
		local scrollBox = CreateFrame("Frame", nil, dialog, "WowScrollBoxList")
		--scrollBox:SetAllPoints()
		scrollBox:SetPoint("TOPLEFT", dialog.InsetBg, "TOPLEFT", 4, 0)
		scrollBox:SetPoint("BOTTOMRIGHT", dialog.InsetBg, "BOTTOMRIGHT", -10, 0)

		local scrollBar = CreateFrame("EventFrame", nil, dialog, "MinimalScrollBar")
		scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
		scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
		
		local dataProvider = CreateDataProvider()
		dataProvider:SetSortComparator(function(a, b) if a.name < b.name then return -1 elseif a.name > b.name then return 1 else return 0 end end);
		local scrollView = CreateScrollBoxListLinearView()
		scrollView:SetDataProvider(dataProvider)
		scrollView:SetElementExtent(20)
		scrollView:SetElementInitializer("Frame", function(a, b) self:initRow(a, b) end)
		ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
		
		dataProvider:Insert({name="Nerago"},{name="Average"},{name="Gornek"})
		
		self.dataProvider = dataProvider;
		self.dialog = dialog;
	end
	
	--self:updateButton();
end

function addon:infoMessage(message)
	print("|cFFE533E5[Check Onyixa Cloak]|r "..tostring(message));
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:RegisterEvent("PLAYER_TARGET_CHANGED");
events:RegisterEvent("INSPECT_READY");
events:SetScript("OnEvent", function(...) addon:onEvent(...) end);
