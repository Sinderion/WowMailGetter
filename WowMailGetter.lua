-- =========
--   Fake environment faking ZLM addon environment
-- =========

ZLM = LibStub("AceAddon-3.0"):NewAddon("ZatenkeinsLotteryManager", "AceConsole-3.0", "AceEvent-3.0");
ZLM_OptionsTable = {
    type = "group",
    chidlGroups = "tab",
    args = {
        config = {
            name = "Config",
            type="group",
            args = {
                enable = {
                    name = "Enable",
                    desc = "Enables/disables the addon",
                    type = "toggle",
                    set = "SetEnabled",
                    get = "GetEnabled"
                },
                debug = {
                    name = "Debug Print Level",
                    desc = "Displays addon output messages.  Lower values show only urgent messages.  Higher values show all messages.",
                    type = "range",
                    min = 0,
                    max = 4,
                    step = 1,
                    bigStep = 1,
                    set = "SetPrintLevel",
                    get = "GetPrintLevel"
                },
                lotteryMethod = {
                    name = "Lottery Method",
                    desc = "The method of determining the winners.  Raffle assigns a proportional chance of winning based on total points.  Competition determines winner exclusively by point values.",
                    type = "select",
                    set = "SetLotteryMethod",
                    get = "GetLotteryMethod",
                    values = ZLM_LotteryMethod
                },
                numberOfWinners = {
                    name = "Number of Winners",
                    desc = "The number of winners you wish to get.",
                    type = "range",
                    min = 1,
                    max = 100,
                    step = 1,
                    bigStep = 1,
                    set = "SetWinnerCount",
                    get = "GetWinnerCount"
                },
                exclusiveWinners = {
                    name = "Exclusive Winners",
                    desc = "[Raffle Method Only]Can the same person win more than once per drawing?",
                    type = "toggle",
                    set = "SetExclusiveWinners",
                    get = "GetExclusiveWinners"
                },
            }
        }
        
    }
}

function ZLM:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ZatenkeinsLotteryManagerDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("ZatenkeinsLotteryManager", ZLM_OptionsTable, {"zlm"})
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ZatenkeinsLotteryManager", "ZLM")
    self:Print("ZLM Loaded");
end



function ZLM:Debug(message,severity)
    if self.db.profile.PrintLevel > severity then
        self.Print(message);
    end
end

function ZLM:OnEnable()
    --Register events here.
    ZLM:RegisterEvent("MAIL_SHOW",function (optionalArg,eventName) ZLM.Mail:VerifiedTakeInboxItem("INIT"); end);
end



-- Fake functions
function ZLM:RecordDonation() print("You recorded shit"); end
function ZLM:UpdateScoreboard() print("Scoreboard Updated!"); end

-- Temporary event handler just to get stuff happening.

--[[
WMG_FRAME = CreateFrame("Frame");
WMG_FRAME:SetScript("OnEvent", 
function(self, event, ...)

	if event == "MAIL_SHOW" then

		ZLM.Mail:VerifiedTakeInboxItem("INIT");

	elseif event == "BAG_UPDATE" then

		ZLM.Mail:VerifyReciept();

	end


end 

);




]]--

--temp thing for the debug function. Overkill but who cares.
ZLM.db = ZLM.db or {};
ZLM.db.profile = ZLM.db.profile or {};
ZLM.db.profile.PrintLevel = ZLM.db.profile.PrintLevel or 2;
function ZLM:Debug(message,severity)
	severity = severity or 0;
	message = message or "Undefined debug message. Check your call.";
    if 5 > severity then
        print(message);
    end
	-- ZLM:Debug(": " .. string.format("%s",value),1);
end

-- =========
--   End of fake environment.
-- =========


-- ==========================================================================
--					Mail crap for Zatenkeins Lottery Manager
-- ==========================================================================
ZLM.Mail = {};
ZLM.Mail.MailDelay = 0.1; -- Timer delay for taking mail. May need tuning.
ZLM.Mail.NoDelay = 0.001; -- Timer delay for general multi-threaded work.
ZLM.Mail.Snapshots = {};
ZLM.Mail.Snapshots.Bags = {};
ZLM_TOTALATTEMPTS = 0;
ZLM_TOTALSUCCESSES = 0;
ZLM_TOTALRETRIES = 0;
function ZLM.Mail:FullName(name)
-- Sinderion -> Sinderion-ShadowCouncil (add server name to same-server sender);   Xaionics-BlackwaterRaiders -> Xaionics-BlackwaterRaiders (no change if it's already full)
	if type(name) ~= "string" then
		return nil;
	end
	if string.match(name," ") then
		name = nil;  -- not a character, skip it.
	elseif string.match(name,"-") then -- Name already full, do nothing :)
	else
		name = name .. "-" .. GetRealmName(); -- Name needs some TLC. Might accidentally get NPC's with one name. Oh well lol.
	end
	ZLM:Debug(name, 2);
	return name;
end
function ZLM.Mail:NoBagSpace()
	local s=0 
	for i=1,5 do
		s=s+GetContainerNumFreeSlots(i-1)
	end
	return s < 4;
end
function ZLM.Mail:BagsSnapshot()
	local Snapshot = {};
	for i= 1, 5 do
		numberOfSlots = GetContainerNumSlots(i);
		for j = 1, numberOfSlots do
			itemId = GetContainerItemID(i, j);
			if itemId then
				Snapshot[itemId] = Snapshot[itemId] or 0;
				Snapshot[itemId] = Snapshot[itemId] + select(2, GetContainerItemInfo(i,j)); -- select the 2nd return value (itemcount)
			end
		end
	end
	return Snapshot;
end
function ZLM.Mail:FindValidInboxItem()
-- Blindly finds the first attachment available and sent from someone without a space in their name(probably a player).
	inbox_items = GetInboxNumItems();
	for i = 1, inbox_items do
		local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, 
textCreated, canReply, isGM = GetInboxHeaderInfo(i);
		if sender then
			sender = ZLM.Mail:FullName(sender); -- Returns name-server, of whatever you feed it. Nil if there's a space.
		end
		if hasItem and hasItem > 0 and not not sender then
			for j = 1, 12 do
				local name, itemID, texture, count, quality, canUse  = GetInboxItem(i, j);
				if itemID then
					print(sender .. name);
					return { sender, count, itemID, i, j };
				end
			end
		end
	end
	return nil;
end
function ZLM.Mail:PitchMail(Index,itemIndex)

			ZLM:RegisterEvent("BAG_UPDATE",function (optionalArg,eventName) ZLM.Mail:VerifyReciept(); end);
			takeinboxitem(Index, itemIndex);
end
function ZLM.Mail:VerifiedTakeInboxItem(status)
	Status = status or "INIT"
	ZLM.Mail.Current = ZLM.Mail.Current or {};
		ZLM.Mail.Snapshots.Bags.Before = ZLM.Mail:BagsSnapshot();
		if ZLM.Mail:NoBagSpace() then  
			ZLM.Mail.Current.ItemID = nil; -- Full bags, no item to grab.
			print("Bags full!"); -- Maybe change, or add a normal red middle of screen frame warning using standard error method.
		elseif status == "RETRY" then -- just use the current tracking variables,ZLM.Mail.Current.ItemID, etc.
			ZLM_TOTALRETRIES = ZLM_TOTALRETRIES + 1;
		else -- Set tracking variables to the next bit of mail. 
			local sender, count, itemID, Index, itemIndex = ZLM.Mail:FindValidInboxItem();
			if sender then
				ZLM.Mail.Current = {
				ItemID = itemID,
				Count = count,
				Sender = sender,
				Index = Index,
				ItemIndex = itemIndex
				}
				print(ZLM.Mail.Current.ItemID);
			else
			    ZLM:Debug("Can't find anymore mail.", 1);
			end
		end -- nil if no mail left, or no bag space. Otherwise there's SOMETHING to check, so check.
		if not not ZLM.Mail.Current.ItemID then 
		    ZLM_TOTALATTEMPTS = ZLM_TOTALATTEMPTS + 1;
			ZLM.Mail:PitchMail(ZLM.Mail.Current.Index, ZLM.Mail.Current.ItemIndex);
		else --end?
			ZLM:UpdateScoreboard();
			ZLM:Debug("Total: ".. ZLM_TOTALATTEMPTS .." Retries: " .. ZLM_TOTALRETRIES.. " Success: ".. ZLM_TOTALSUCCESSES, 1);
			ZLM:Debug("itemID = nil for whatever reason. Exiting.", 1);
		end

end
function ZLM.Mail:VerifyReciept()
		ZLM:UnregisterEvent("BAG_UPDATE"); --
		ZLM.Mail.Snapshots.Bags.Before[ZLM.Mail.Current.ItemID] = ZLM.Mail.Snapshots.Bags.Before[ZLM.Mail.Current.ItemID] or 0;
		ZLM.Mail.Snapshots.Bags.After = ZLM.Mail:BagsSnapshot();
		if ZLM.Mail.Snapshots.After[ZLM.Mail.Current.ItemID] == ZLM.Mail.Snapshots.Bags.Before[ZLM.Mail.Current.ItemID] + ZLM.Mail.Current.Count then
			ZLM:RecordDonation(ZLM.Mail:FullName(ZLM.Mail.Current.Sender),ZLM.Mail.Current.ItemID,ZLM.Mail.Current.Count);
			ZLM.Mail.Current.ItemID = nil;
			ZLM_TOTALSUCCESSES = ZLM_TOTALSUCCESSES + 1;
			C_Timer.After(ZLM.Mail.NoDelay, function() ZLM.Mail:VerifiedTakeInboxItem("INIT") end);  
		else
			ZLM:Debug("Debug: Failed to get mail at ".. ZLM.Mail.Current.Index.." item " ..ZLM.Mail.Current.ItemIndex.." retrying...",0);
			C_Timer.After(ZLM.Mail.MailDelay, function() ZLM.Mail:VerifiedTakeInboxItem("RETRY") end);
		end
end

-- =================================================================
--						End of actual lua code
-- =================================================================







