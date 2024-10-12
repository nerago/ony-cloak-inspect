local addonName = select(1, ...)
local addon = select(2, ...)
NERAGO_ONY_CHECK = addon;

local TEXTURE_UNKNOWN = "interface/icons/inv_misc_questionmark";
local TEXTURE_YES = "interface/icons/inv_misc_cape_05";
local TEXTURE_NO = "interface/icons/inv_misc_breadofthedead";
local _nameIndex = 0;

function addon:onEvent(_, event, ...)
	local arg1, arg2 = select(1, ...), select(2, ...);
	print("event="..event);
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
			--todo
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
	self:startCheck();
end

function addon:listGroupMembers()
	local members = {};
	
	if IsInRaid() then
		for i = 1, MAX_RAID_MEMBERS do
			-- GetRaidRosterInfo would get us tank status too
			local unitId = "raid" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				tinsert(members, { guid = guid, name = name });
			end
		end
	elseif IsInGroup() then
		for i = 1, numMembers do
			local unitId = "party" .. i;
			local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
			if name and guid then
				tinsert(members, { guid = guid, name = name });
			end
		end
	else
		local unitId = "player";
		local name, guid = UnitNameUnmodified(unitId), UnitGUID(unitId);
		tinsert(members, { guid = guid, name = name });
		self:infoMessage("Not in group");
	end
	return members;
end

function addon:startCheck()
	self.checking = true;
	
	self:createFrame();
	
	local members = self:listGroupMembers();
	self.status = {};
	self.dataProvider:RemoveIndexRange(1, self.dataProvider:GetSize());
	for _, tab in ipairs(members) do
		tab.cloak = "?";
		self.status[tab.guid] = tab;
		self.dataProvider:Insert(tab)
	end
	
	self.dataProvider:Insert({name="Nerago"},{name="Average"},{name="Gornek"},{name="Neravi"})
	
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
			--print("cloak "..tostring(itemId));
			if item == 15138 then
				tab.cloak = "y"
			else
				tab.cloak = "n"
			end
			--function ScrollBoxListViewMixin:FindFrame(elementData)
			--self:updateButton(tab);
			self.scrollView:DataProviderContentsChanged()
		end
	end
end

function addon:initRow(frame, data)
	if not frame.left then
		local buttonName = "NeragoCheckOnyCloakCheckButton".._nameIndex;
		_nameIndex = _nameIndex + 1
		frame.button = CreateFrame("Button", buttonName, frame, "InsecureActionButtonTemplate");
		
		frame.button:SetPoint("TOPRIGHT", frame, "TOPRIGHT");
		frame.button:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT");
		frame.button:SetText("Check");
		frame.button:SetSize(20, 20);
		
		frame.texure = frame.button:CreateTexture();
		frame.texure:SetAllPoints(frame.button);
		frame.texure:SetTexture(TEXTURE_UNKNOWN);
				
		frame.left = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
		frame.left:SetPoint("LEFT", frame);
		frame.left:SetPoint("RIGHT", frame.button, "LEFT");
	end
	
	frame.left:SetText(data.name)
	if not InCombatLockdown() then
		frame.button:SetAttribute("type", "target");
        frame.button:SetAttribute("unit", data.name);
		self:updateButtonTexture(frame, data)
	end
end

function addon:updateButton(data)
	local frame = self.scrollView:FindFrame(data);
	self:updateButtonTexture(frame, data);
	--self.scrollView:DataProviderContentsChanged()
end

function addon:updateButtonTexture(frame, data)
	if data.cloak == "y" then
		frame.texure:SetTexture(TEXTURE_YES);
	elseif data.cloak == "n" then
		frame.texure:SetTexture(TEXTURE_NO);
	else
		frame.texure:SetTexture(TEXTURE_UNKNOWN);
	end
end

function addon:createFrame()
	local dialog = self.dialog;
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
		scrollBox:SetPoint("TOPLEFT", dialog.InsetBg, "TOPLEFT", 4, 6)
		scrollBox:SetPoint("BOTTOMRIGHT", dialog.InsetBg, "BOTTOMRIGHT", -10, 0)

		local scrollBar = CreateFrame("EventFrame", nil, dialog, "MinimalScrollBar")
		scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
		scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
		
		local dataProvider = CreateDataProvider()
		-- dataProvider:SetSortComparator(function(a, b) if a.name < b.name then return -1 elseif a.name > b.name then return 1 else return 0 end end);
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
