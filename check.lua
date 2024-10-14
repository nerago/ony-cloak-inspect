local addonName = select(1, ...)
local addon = select(2, ...)
NERAGO_ONY_CHECK = addon;

local TEXTURE_UNKNOWN = "interface/icons/inv_misc_questionmark";
local TEXTURE_YES = "interface/icons/inv_misc_cape_05";
local TEXTURE_NO = "interface/icons/inv_misc_bone_humanskull_01";
local _nameIndex = 0;

function addon:onEvent(_, event, ...)
	local arg1, arg2 = select(1, ...), select(2, ...);
    if event == "ADDON_LOADED" then
        if arg1 == "NeragoCheckOnyCloak" then
            self:infoMessage("Loaded");
			SlashCmdList["NERAGO_ONY_CHECK"] = function(...) self:slashCommand(...) end;
			SLASH_NERAGO_ONY_CHECK1 = "/ony";
			if not NERAGO_ONY_CHECK_SAVED then
				NERAGO_ONY_CHECK_SAVED = {};
			end
			self.loaded = true;
			self.checking = false;
			self.status = {};
        end
	elseif self.loaded and self.checking then
		if event == "GROUP_ROSTER_UPDATE" then
			self:updateRoster();
		elseif event == "PLAYER_REGEN_DISABLED" then
			self.checking = false;
			if self.dialog then
				self.dialog:Hide();
			end
		elseif event == "PLAYER_TARGET_CHANGED" then
			self:checkTarget();
		elseif event == "INSPECT_READY" then
			self:inspectReady(arg1);
		end
    end
end

function addon:slashCommand(...)
	if InCombatLockdown() then
		self:infoMessage("Not available in combat");
	else
		self:startCheck();
	end
end

function addon:listGroupMembers()
	local members = {};
	if IsInRaid() then
		for i = 1, MAX_RAID_MEMBERS do
			local unitId = "raid" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				members[guid] = { guid = guid, name = name };
			end
		end
	elseif IsInGroup() then
		for i = 1, numMembers do
			local unitId = "party" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				members[guid] = { guid = guid, name = name };
			end
		end
	else
		local unitId = "player";
		local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
		members[guid] = { guid = guid, name = name };
	end
	return members;
end

function addon:startCheck()
	self.checking = true;
	
	self:createFrame();
	
	local members = self:listGroupMembers();
	self.status = {};
	self.dataProvider:RemoveIndexRange(1, self.dataProvider:GetSize());
	for _, tab in pairs(members) do
		if tab then
			tab.cloak = "?";
			self.status[tab.guid] = tab;
			self.dataProvider:Insert(tab)
		end
	end
end

function addon:updateRoster(inspecteeGUID)
	local members = self:listGroupMembers();
	
	-- remove old
	for guid, tab in pairs(self.status) do
		if tab and not members[guid] then
			self.status[guid] = nil
			self.dataProvider:Remove(tab)
		end
	end
	
	-- add new
	for _, tab in pairs(members) do
		if not self.status[tab.guid] then
			tab.cloak = "?";
			self.status[tab.guid] = tab;
			self.dataProvider:Insert(tab)
		end
	end
	
	self.scrollView:SetDataProvider(self.dataProvider)
end

function addon:checkTarget()
	local guid = UnitGUID("target");
	if self.status[guid] and CanInspect("target", false) then
		ClearInspectPlayer();
		NotifyInspect("target");
	end
end

function addon:inspectReady(inspecteeGUID)
	local guid = UnitGUID("target");
	if inspecteeGUID == guid then
		local tab = self.status[guid];
		if tab then
			local itemId = GetInventoryItemID("target", INVSLOT_BACK);
			
			if itemId == 15138 then
				tab.cloak = "y"
			else
				tab.cloak = "n"
			end
			
			self.scrollView:SetDataProvider(self.dataProvider)
		end
	end
end

function addon:initRow(frame, data)
	if not frame.button then
		local buttonName = "NeragoCheckOnyCloakCheckButton".._nameIndex;
		_nameIndex = _nameIndex + 1
		
		local button = CreateFrame("Button", buttonName, frame, "InsecureActionButtonTemplate");
		button:SetPoint("TOPLEFT", frame, 0, -2);
		button:SetPoint("BOTTOMLEFT", frame, 0, 2);
		button:SetWidth(22);
		
		local buttonTexture = button:CreateTexture();
		buttonTexture:SetTexture(TEXTURE_UNKNOWN);
		buttonTexture:SetPoint("TOPLEFT", button, 3, -3);
		buttonTexture:SetPoint("BOTTOMRIGHT", button, -3, 3);
		
		local borderFrame = CreateFrame("Frame", buttonName.."BACK", frame, "BackdropTemplate");
		borderFrame:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4);
		borderFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4);
		borderFrame:SetWidth(20);
		borderFrame:SetBackdrop({
			edgeFile = "Interface\\TutorialFrame\\UI-TutorialFrame-CalloutGlow",
			edgeSize = 16,
			tileEdge = true,
			tileSize = 16,
		});
		borderFrame:SetBackdropBorderColor(0, 0, 0, 0)
				
		local text = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
		text:SetPoint("LEFT", borderFrame, "RIGHT", 6, 0);
		text:SetPoint("RIGHT", frame, "RIGHT");
		
		frame.text = text;
		frame.button = button;
		frame.buttonTexture = buttonTexture;
		frame.borderFrame = borderFrame;
	end
	
	frame.text:SetText(data.name)
	if not InCombatLockdown() then
		frame.button:SetAttribute("type", "target");
        frame.button:SetAttribute("unit", data.name);
		self:updateButtonTexture(frame, data)
	end
end

function addon:updateButton(data)
	local frame = self.scrollView:FindFrame(data);
	self:updateButtonTexture(frame, data);
end

function addon:updateButtonTexture(frame, data)
	if data.cloak == "y" then
		frame.buttonTexture:SetTexture(TEXTURE_YES);
		frame.borderFrame:SetBackdropBorderColor(0, 1, 0, 1);
	elseif data.cloak == "n" then
		frame.buttonTexture:SetTexture(TEXTURE_NO);
		frame.borderFrame:SetBackdropBorderColor(1, 0, 0, 1);
	else
		frame.buttonTexture:SetTexture(TEXTURE_UNKNOWN);
		frame.borderFrame:SetBackdropBorderColor(0, 0, 0, 0);
	end
end

function addon:createFrame()
	local dialog = self.dialog;
	if not dialog then
		dialog = CreateFrame("Frame", "NeragoCheckOnyFrame", UIParent, "BasicFrameTemplateWithInset");
		dialog.TitleText:SetText("Check Onyxia Cloak")
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
		dialog:SetResizable(true);
		
		dialog:SetScript("OnHide", function()
			self.checking = false;
		end);
		
		local scrollBox = CreateFrame("Frame", nil, dialog, "WowScrollBoxList")
		scrollBox:SetPoint("TOPLEFT", dialog.InsetBg, "TOPLEFT", 8, -6)
		scrollBox:SetPoint("BOTTOMRIGHT", dialog.InsetBg, "BOTTOMRIGHT", -10, 0)

		local scrollBar = CreateFrame("EventFrame", nil, dialog, "MinimalScrollBar")
		scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
		scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
		
		local dataProvider = CreateDataProvider()
		dataProvider:SetSortComparator(function(a, b) 
			if a and b and a.name and b.name then
				return strcmputf8i(a.name, b.name) < 0;
			end
		end);
		local scrollView = CreateScrollBoxListLinearView()
		scrollView:SetDataProvider(dataProvider)
		scrollView:SetElementExtent(26)
		scrollView:SetElementInitializer("Frame", function(a, b) self:initRow(a, b) end)
		ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
		
		self.scrollView = scrollView;
		self.dataProvider = dataProvider;
		self.dialog = dialog;
	else
		dialog:Show();
	end
end

function addon:infoMessage(message)
	print("|cFFE533E5[Check Onyixa Cloak]|r "..tostring(message));
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_REGEN_DISABLED");
events:RegisterEvent("PLAYER_TARGET_CHANGED");
events:RegisterEvent("INSPECT_READY");
events:SetScript("OnEvent", function(...) addon:onEvent(...) end);
