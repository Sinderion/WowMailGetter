-- Debug
WMGEVERBOSE = 0;
WMGEDEBUG = 4;
LRLASTMEM = 0;

WMG_DEBUG_TAKECOUNT = 0;
WMG_DEBUG_RECIEVECOUNT = 0;
WMG_PROFILE = {};
WMG_CHECKED = {};


function WMGE(sError, iDebug, iVerbose)

	iDebug = iDebug or 4;
	iVerbose = iVerbose or 0;



	sError = sError or "UNKNOWN_ERROR_AMG";

	-- This should mean WMGE("Broken Link", 1) will show at level debug 1 and above
	--    and WMGE("Odd Exception occurance in roster.", 0, 2) should work at debug 
	if (iVerbose > 0 and iVerbose <= WMGEVERBOSE) or (iDebug > 0 and iDebug <= WMGEDEBUG) or iDebug == 4 then
		DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000Live Roster Error:\124r".. tostring(sError));
	end
		
end

-- In init code
WMG_FRAME = CreateFrame("Frame"); -- Don't think it needs a name. In the event functions, 'self' should point to the frame if necessary.
local events = {};  -- Store event functions named/categorized by their event text, differentiated by event: tag.
ZLM_iHoover_SmartNozzle = {};


  -- Sketchy structure to make things pretty in the editor.
function Generic_EventLoader()

	-- *** Events Framework header --
					-- Event:PLAYER_ENTERING_WORLD   takes the place of a custom named function for readability and automated event registration.
					-- events object and frame would be created here, I just moved them outside the function. 
	-- *** /Events Framework header --

	-- ** Events ** Declared here, to be tallied after.

	function events:MAIL_SHOW(...)
		
		WMGE("2. MAIL_SHOW caught.",1);
		C_Timer.After(2,function() ZLM_iHoover_Start(frame) end);

		

	end

	function events:BAG_UPDATE(...)
		
		WMGE("BAG_UPDATE",1);
	--	ZLM_iHoover_Oscillator(frame,...);
		WMG_FRAME:UnregisterEvent("BAG_UPDATE");
		ZLM_iHoover_Juggle(self);
	end

	-- ** /Events

	-- ** Events framework tail.
	WMG_FRAME:SetScript("OnEvent", function(self, event, ...)
		events[event](self, ...); -- call one of the functions above
		end);


	for k, v in pairs(events) do

		-- Skip some events if necessary for now.	
		if k == "BAG_UPDATE" then

		else

			WMG_FRAME:RegisterEvent(k); -- Register all events for which handlers have been defined. Ezpz since they're named after their event string aWMGEady.
		end
	end
	WMGE("1. Events loaded.",1);
-- ** /Events framework tail.

end


-- ** Utility functions.

 function ZLM_NoBagSpace()
	local s=0 
	for i=1,5 do
		s=s+GetContainerNumFreeSlots(i-1)
	end
	return s < 13;
 end

  -- Only activate on the correct BAG_UPDATE event. Only let stuff in when we're ready to process.
  -- Suddenly appears unecessary. Not sure why.
function ZLM_iHoover_Oscillator(eventframe,...)
	-- grab the tracking object.
	local ball = ZLM_iHoover_SmartNozzle;

	if ball.countToTwo == -1 then
			-- -1 means we're not waiting for update, do nothing.
			WMGE("Caught BAG_UPDATE when not waiting for an update. Check logic flow.");
		-- The BAG_UPDATE event gets called twice when recieving items from mail. Make sure we only work after the second of the two calls.
	elseif ball.countToTwo == 1 then			
			self:UnregisterEvent("BAG_UPDATE");
			ball.countToTwo = -1;
			-- Mark our current mail message profile(snapshot of what attachments are in the current message) as having this item removed.
			ball.currentProfile[ball.itemIndex] = nil;
			-- I use 'return' to call juggle (continue processing) so it'll quit this current function. I don't think the event stack will care about a return value.

		return ZLM_iHoover_Juggle(eventframe);
		-- increment if we're on the 1st BAG_UPDATE call
	elseif ball.countToTwo == 0 then
			ball.countToTwo = 1;
		-- ball.countToTwo should only ever be 0 or 1 or -1(for not counting yet). If the value is different we've got errors to catch.
	else
			WMGE("Count error: Counter says ".. ball.countToTwo);	
	end

end

  -- Mail info doesn't adjust dynamically. You've gotta paint yourself a picture, holes, treasure and all.
function ZLM_MessageProfile(Index)

	WMGE("4.2 Profiling message.");
	local ball = ZLM_iHoover_SmartNozzle;
	--Target mailbox item/index CAN be passed to this function as a utility, otherwise it just uses the async tracking variable.
	local Index = Index or ball.Index;
	local i;
	local profile = {};

	local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, 
			textCreated, canReply, isGM = GetInboxHeaderInfo(ball.Index);
	if hasItem and hasItem > 0 then
	WMG_PROFILE[Index] = {}; -- debug.
		for i=1, 12 do
			
			local name, itemID, itemTexture, count, canUse, quality = GetInboxItem(Index, i)
			if itemID then
				WMGE("Mail "..Index.." item "..i.." = "..name);
				profile[i] = {sender, itemID, count, name};  -- for easy unpack()'ing into the tallywhacker function arguments. 
				WMG_PROFILE[Index][i] = 1; -- debug
			else
				WMGE("Mail "..Index.." item slot "..i.." is empty.");
				profile[i] = 0; -- nil might mess things up for array?
				WMG_PROFILE[Index][i] = 0; -- debug
			end
		end

	else
		return 0; -- Message has no attachments.
	end
	--print(unpack(profile));
	return profile; -- Return a 12 element array w/ the info needed for tallywacker recording of all items within. nil is returned if no attachments.
end


-- ** Process functions.

  -- Kick things off. Called by MAIL_SHOW Event, which is called when the mailbox is opened. To start test, just check your mail!
 function ZLM_iHoover_Start(eventframe, ...)
 
		-- initialize the tracking structure - ZLM_iHoover_SmartNozzle. Mail and bag events are asyncronous so we've gotta play a little sloppy, almost like multithread but not as neat.
		WMGE("3. Starting",1);
		local ball = ZLM_iHoover_SmartNozzle;
		-- ball = {}; -- Always initialize to nothing. Just in case.
		ball.countToTwo = -1; -- -1 means we're not ready to count yet, not waiting for an update.
		ball.inbox_items = GetInboxNumItems();
		
		-- debug WMG_CHECKED variable initialization. 2D array, length: number of inbox items. each item has a 12 element array of it's own initialized with zeroes to be filled in later for debug purposes.
		local i;
		local j;
		for i=1, ball.inbox_items do
			WMG_CHECKED[i] = {};
			for j = 1, 12 do
				WMG_CHECKED[i][j] = 0;
			end
		end

		if (ball.inbox_items > 0) then
			WMGE("3.5 We've got "..ball.inbox_items.." mail(s)!",1);
			ball.Index = 0; -- Starting at 0 for loop purposes. 1 is the first mail.
			ball.itemIndex = 1;
			WMGE("3.6 itemIndex = " .. ZLM_iHoover_SmartNozzle.itemIndex, 1);
			
			-- initial priming of juggling.
			
			 ZLM_iHoover_Juggle(eventframe);
		end

end

  -- ACT II, our champion heroicly sorts the mail while the uncanny Zatenkein takes notes on a gleaming tallywhacker.
function ZLM_iHoover_Juggle(eventframe)



	-- Grab a shorthand version of the tracking object we have to use cuz asyncronous.
	local ball = ZLM_iHoover_SmartNozzle;
	ball.itemIndex = ball.itemIndex or -1;

	--WMGE("4. Juggling. Index: "..ball.Index.." itemIndex: "..ball.itemIndex,1);
	-- If we're starting a new mail, check bag space and get the profile of the next mail message with attachments.			
	if ball.itemIndex == 1 or (type(ball.currentProfile) ~= "table") then
		WMGE("4.1 Starting a new mail.",1);
		if ZLM_NoBagSpace() then
			WMGE("5.0 Not enough room in bags.");
			-- Reset	
			return ZLM_iHoover_Cleanup(eventframe); -- using return as a break.
		end

		-- Dig till we find something shiney or hit bedrock.
		repeat
			WMGE("4.2In profiling loop.",1);
			ball.Index = ball.Index + 1;
			ball.currentProfile = ZLM_MessageProfile(); -- could call it with ball.Index argument, but it uses the async tracking variable automatically anyways.
		until (type(ball.currentProfile) == "table") or ball.Index > ball.inbox_items; -- 'currentprofile' is nil if there are no attachments, and if we reach the end we're done.



		-- If we're done, bail.
		if ball.Index > ball.inbox_items then
			WMGE("ball.Index > ball.inbox_items",1);
			return ZLM_iHoover_Cleanup(eventframe);
		end
	end



	-- SHOULD always find the first available attachment. BAG_UPDATE handler will mark this spot in the profile as cleared/nil once it's actually taken.
	ball.itemIndex = -1 -- To track if we've found anything.
	if (type(ball.currentProfile) ~= "table") then
			WMGE("ERR: Got nil profile.");
			return ZLM_iHoover_Cleanup(eventframe);
		--return;
	else
		for k, v in pairs(ball.currentProfile) do
			if (type(v) == "table") then
				WMGE("4.3 Found item at Index "..ball.Index.." position: "..k);
				WMGE(unpack(ball.currentProfile[k]),1);
				ball.itemIndex = k;
				--ball.currentProfile[k] = nil;
				break;
			else
				WMGE("No value key: "..k.." = "..tostring(v));
			
			end
			WMGE("Digging..");
		end
	end
	if ball.itemIndex > 0 then
		--Record, register for BAG_UPDATE, take item. End. The action of recieving the item(event:BAG_UPDATE) will kick the process off again.
		--ZLM_TallyWhacker:REcordDonation(unpack(ball.currentProfile[ball.itemIndex]));
		WMGE("4.4 Registering BAG_UPDATE and taking item ".. ball.itemIndex.." from inbox item ".. ball.Index,1);
		ball.countToTwo = 1; -- Prime the oscillator.
		WMG_CHECKED[ball.Index][ball.itemIndex] = 1;
		ball.itemIndex = -1; -- reset

		--C_Timer.After(0.1,function() events:BAG_UPDATE(eventframe) end); -- DEBUG ONLY
		eventframe:RegisterEvent("BAG_UPDATE");
		TakeInboxItem(ball.Index,ball.itemIndex);
		-- if we're at the end of the message

	else
		
		ball.itemIndex = 1;
		WMGE("4.5 itemIndex not > 0.");
		ZLM_iHoover_Juggle(eventframe);
	end

end


  -- The end... for now.
function ZLM_iHoover_Cleanup(eventframe)

	ball = ZLM_iHoover_SmartNozzle;
	WMGE("5.2 Cleaning up. Index: "..ball.Index.." Item: " .. ball.itemIndex,1);
	WMG_FRAME:UnregisterEvent("BAG_UPDATE");
	ZLM_iHoover_SmartNozzle = {};

	-- debug output
	local Index = 1;
	local Report = "Missed (mail/slot): \n";

	if WMGEDEBUG > 0 then
		for k, v in ipairs(WMG_PROFILE) do
	
			local itemIndex = 1;
			for i, j in ipairs(WMG_PROFILE[Index]) do

				if WMG_PROFILE[Index][itemIndex] == WMG_CHECKED[Index][itemIndex] then
					-- G2G
				else
					if WMG_PROFILE[Index][itemIndex] > WMG_CHECKED[Index][itemIndex] then
						Report = Report .. Index .. "/" .. itemIndex .. " " 
					else
					
					end
				end

				if itemIndex < 12 then
					itemIndex = itemIndex + 1;
				elseif itemIndex == 12 then
					Report = Report .. "\n";
				end
			end

			Index = Index + 1;

		end
		WMGE(Report);
	end

	return 1; -- in case lua wants a return value for a function called with return :P
	-- UNREGISTER FOR BAG UPDATE.
	-- reset tracking variable
end

C_Timer.After(4,function() Generic_EventLoader() end);



