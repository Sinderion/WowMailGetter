
ZLM = LibStub("AceAddon-3.0"):NewAddon("ZatenkeinsLotteryManager", "AceConsole-3.0", "AceEvent-3.0");
ZLM.Mail = {};
ZLM.Mail.MailDelay = 0.1; -- Timer delay for taking mail. May need tuning.
ZLM.Mail.NoDelay = 0.001; -- Timer delay for general multi-threaded work.
-- Fake function
function ZLM:RecordDonation() print("You recorded shit"); end


-- ==========================================================================
--					Mail crap for Zatenkeins Lottery Manager
-- ==========================================================================

ZLM.Mail = {};
ZLM.Mail.MailDelay = 0.1; -- Timer delay for taking mail. May need tuning.
ZLM.Mail.NoDelay = 0.001; -- Timer delay for general multi-threaded work.
ZLM.Mail.Snapshots = {};
ZLM.Mail.Snapshots.Bags = {};
--ZLM.Mail.CheckStatus = "IDLE";   -- "IDLE"  "WAITING" "CONFIRMED" "PROCESSING"
ZLM.Mail.Current = {};
ZLM.Mail.Current.ItemID = 0;
ZLM.Mail.Current.Count = 0;       -- count of said item in processing.
ZLM.Mail.Current.Sender = 0;
ZLM.Mail.Current.Index = 0;
ZLM.Mail.Current.ItemIndex = 0;
ZLM.Mail.Snapshots.Bags.Before = 0;
ZLM.Mail.Snapshots.Bags.After = 0;

-- Sinderion -> Sinderion-ShadowCouncil (add server name to same-server sender);   Xaionics-BlackwaterRaiders -> Xaionics-BlackwaterRaiders (no change if it's already full)
function ZLM.Mail:Fullname(name)

		--insert code here to return the name-server name no matter the name given, assuming the argument is a real name, return nil if not a real player name.
		-- Possibly tuck legit name validation in here, since RP and other mail usuallly has spaces in the name.

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
	Snapshot = {};
	for i= 1-5 do
		numberOfSlots = GetContainerNumSlots(bagID);
		for for j = 1-numberOfSlots do
			itemId = GetContainerItemID(i, j);
			if itemId then
				Snapshot[itemId] = Snapshot[itemId] or 0;
				Snapshot[itemId] = snapshot[itemId] + select(2, GetContainerItemInfo(i,j))); -- select the 2nd return value (itemcount)
			end
		end
	end
	return Snapshot  
end



-- Blindly finds the first attachment available and sent from someone without a space in their name(probably a player).
function ZLM.Mail:FindValidInboxItem()
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
					return { sender, count, itemID, i, j };
				end
			end
		end
	end
	return nil;
end





function ZLM.Mail:VerifiedTakeInboxItem(status)


		Status = status or "INIT";

	-- INIT and RETRY mean try and take the next item. RETRY, obviously, means try the same thing again.
	if status == "INIT" or status == "RETRY" then

		if ZLM.Mail:NoBagSpace() then return 2; end -- Not using the error code 2 at the moment, but it's there :P

		ZLM.Mail.Snapshots.Bags.Before = ZLM.Mail:BagsSnapshot(); -- So that ZLM.BagsAfterSnapshot[ZLM.Mail:Current.ItemID] = ZLM.Mail.BeforeBagsSnapshot[ZLM.Mail.Current.ItemID] + ZLM.Mail.Current.Count  -- assuming bags before count was:    count or 0;

		-- for INIT we have to get info for the next available item. RETRY doesn't need this step, so we do nothing, and try to take the same item again.
		if status == "RETRY" then
			-- just use the current tracking variables,ZLM.Mail.Current.ItemID, etc.
		else 
			-- Set tracking variables to the next bit of mail. 
			local sender, count, itemID, Index, itemIndex = ZLM.Mail:FindValidInboxItem();
			if sender then
					ZLM.Mail.Current.ItemID = itemID;
					ZLM.Mail.Current.Count = count;
					ZLM.Mail.Current.Sender = sender;
					ZLM.Mail.Current.Index = Index;
					ZLM.Mail.Current.ItemIndex = itemIndex;
			end
		end

		-- A successful retrieval leaves ZLM.Mail.Current.ItemID as nil. 
		-- Only a newly located mail object, or a retry of an unverified retrieval would re-fill the variable.
		-- Therefore if the variable .ItemID is not nil, we're good to try.
		if not not ZLM.Mail.Current.ItemID then 
			ZLM:RegisterEvent("BAG_UPDATE",function (optionalArg,eventName) ZLM.Mail:VerifyReciept(); end);
			takeinboxitem(ZLM.Mail.Current.Index, ZLM.Mail.Current.ItemIndex);
		end
end
	-- Check the math, if it doesn't pan out, do it over again.
	--elseif status == "CONFIRM" 

function ZLM.Mail:VerifyReciept()

		ZLM:UnregisterEvent("BAG_UPDATE"); --
		ZLM.Mail.Snapshots.Bags.Before[ZLM.Mail.Current.ItemID] = ZLM.Mail.Snapshots.Bags.Before[ZLM.Mail.Current.ItemID] or 0;
		ZLM.Mail.Snapshots.Bags.After = ZLM.Mail:BagsSnapshot();

		if ZLM.Mail.Snapshots.After[ZLM.Mail.Current.ItemID] == ZLM.Mail.Snapshots.Bags.Before[ZLM.Mail.Current.ItemID] + ZLM.Mail.Current.Count then

			-- record transaction.
			ZLM:RecordDonation(ZLM.Mail:FullName(ZLM.Mail.Current.Sender),ZLM.Mail.Current.ItemID,ZLM.Mail.Current.Count);
			ZLM.Mail.Current.ItemID = nil;
			C_Timer.After(ZLM.Mail.NoDelay, function() ZLM.Mail:VerifiedTakeInboxItem("INIT") end);  -- Continue taking stuff if possible.
			return 1;

			--- make mail object nil.

		else
			
			print("Debug: Failed to get mail at ".. ZLM.Mail.Current.Index.." item " ZLM.Mail.Current.ItemIndex.." retrying...");
			C_Timer.After(ZLM.Mail.MailDelay, function() ZLM.Mail:VerifiedTakeInboxItem("RETRY") end);


		end

	end
end




-- =================================================================
--						End of actual lua code
-- =================================================================





-- Snapshot mailbox

Starting work = 1;

function ZLM.Mail:

	inbox_items = getinboxitems();

	local slots taken up = 0;

	for i= 1-inbox_items do   -- all mail items

		, , , hasitems = getmessage(#)
		if hasItems
			
			for j= 1-12 do
				profile[i][j] = {ItemId, quantity};
				if mailSnapshotbyID[ItemID] then
					mailSnapshotbyID[ItemID] = mailSnapshotbyID[ItemID] + quantity;
				else
					mailSnapshotbyID[ItemID] = quantity;
				end
				slots taken up ++;
			end
		end
	end


return mailSnapshotbyID; -- since the loop might want new versions.

profile bags





predicted bags afterwards

for k, v in pairs(mailSnapshotbyID[ItemID]) do

	bagprofilebyID[itemID] = bagprofilebyID[itemID]) or 0;
	predictedprofilebyID[itemID] = bagprofilebyID[itemID] + v;
	
end







pull all items


if slots taken up => get bag space() then

	take items(get bag space() - 3);

end


function take items()

	for k, v in pairs(profile) do

		for i, j in pairs(profile[k]) do
			
			if (type(j) == "table") then
				
				take inboxitem(i, j);	

			end

		end


	end

end


evaluate

-- possibly the most complicated part.
local discrepancies = 0;
local newbagprofilebyID = getbagprofile();


for k, v in predictedprofilebyID do

	newbagprofilebyID[k] = newbagprofilebyID[k] or 0;
	if v == newbagprofilebyID[k] then

		ZLM:RecordDonation(nameRealmCombo,itemId,quantity)
	
	elseif v == startingbagprofile[k] then

		--not taken

	else

		discrepancies = discrepancies + 1;
	end

		

end






pull all items


evaluate


pull all items


evaluate


Loop in progress tracking variable.


ZLM:UpdateScoreboard()