

-- In init code
local frame = CreateFrame("Frame"); -- Don't think it needs a name. In the event functions, 'self' should point to the frame if necessary.
local events = {};  -- Store event functions named/categorized by their event text, differentiated by event: tag.




function Generic_EventLoader()

	-- *** Events Framework header --
					-- Event:PLAYER_ENTERING_WORLD   takes the place of a custom named function for readability and automated event registration.
	-- *** /Events Framework header --

	-- ** Events ** Declared here, to be tallied after.
	function events:UPDATE_PENDING_MAIL(...)
		print("OMFG Mail pending from:" .. GetLatestThreeSenders());
	end


	function events:MAIL_SHOW(...)
		
		ZLM_iHoover_Start(...);


	end
	
	function events:MAIL_INBOX_UPDATE(...)
			
			-- mail changes from new to read.

	end

	function events:BAG_UPDATE(...)

		-- next itteration of pull from mail.
		-- don't always have this registered.

	end



	-- ** /Events

	-- ** Events framework tail.
	frame:SetScript("OnEvent", function(self, event, ...)
		events[event](self, ...); -- call one of the functions above
		end);


	for k, v in pairs(events) do
		frame:RegisterEvent(k); -- Register all events for which handlers have been defined. Ezpz since they're named after their event string already.
	end
-- ** /Events framework tail.

end

Generic_EventLoader();

function ZLM_TestMail(...)

	events:MAIL_SHOW(frame);

end




 -- record mail as seen/recieved, recognize old mail.
 ZLM_iHoover_SmartNozzle = {};



 function ZLM_iHoover_Start()
 
		
		local ball = {};
		ball.inbox_items = GetInboxNumItems();
		if (ball.inbox_items > 0) then
			ball.Index = 1;
			ball.itemIndex = 1;
			ZLM_iHoover_SmartNozzle = ball;
			-- REGISTER FOR EVENT, BAG UPDATE;
			-- initial priming of juggling
			ZLM_iHoover_Juggle();
		end
					--  and 
					--- take.

				-- check your math with player inventory?
		-- 
	
end


function ZLM_iHoover_Juggle()


				local ball = ZLM_iHoover_SmartNozzle;
				-- Check one mail item.
				-- If you have enough empty slots...
				-- If we're on a new mail, indicated by itemindex being 1, do initial things.
				if ball.itemIndex == 1 then
					local s=0 
					for i=1,5 do
						s=s+GetContainerNumFreeSlots(i-1)
					end

					-- If we're g2g on bag space, move on.				
					if s > 13 then
						local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, 
							textCreated, canReply, isGM = GetInboxHeaderInfo(inbox_item_index);
						-- sanity check to make sure we can proceed w/ taking item.
						if (hasItem < ball.itemIndex) then
							print("Can't take item number ".. ball.itemIndex.." from ".. hasItem .." items.");
						else
								local itemLink = GetInboxItemLink(ball.Index, ball.itemIndex ); -- Need itemlink, to get Item ID for record
								local name, itemTexture, count, quality, canUse = GetInboxItem(ball.Index, ball.itemIndex ) -- Need count for record.
								local itemID = string.match(itemLink, "item[%-?%d:]+"); -- Need to turn itemLink into an Item ID
								-- Official record.
								ZLM_TallyWhacker:REcordDonation(sender,itemID,count);
								-- Actually take the item. This could go after bag update, or now, whichever. This arrangment is rather trusting.
								TakeInboxItem(ball.Index, ball.itemIndex);
							
						end	
						-- if we're done, cleanup
						if ball.Index == ball.inbox_items then
							ZLM_iHoover_Cleanup();
						end
						
					else
						print("Not enough room in bags.");
						-- Reset
						ZLM_iHoover_Cleanup();
					end
				
				
				end
		



end


function ZLM_iHoover_Cleanup()

-- UNREGISTER FOR BAG UPDATE.
-- reset tracking variable
end



--  local s=0 for i=1,5 do s=s+GetContainerNumFreeSlots(i-1)end print(s)

local itemString = string.match(itemLink, "item[%-?%d:]+")

-- packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, 
--textCreated, canReply, isGM = GetInboxHeaderInfo(index);

-- GetInboxItem
name, itemTexture, count, quality, canUse = GetInboxItem(index, itemIndex)


inbox_items = GetInboxNumItems();
if (inbox_items > 0) then
  for inbox_item_index = 1, inbox_items do
    -- Get the Message Text
    inbox_text = GetInboxText(inbox_item_index);
    -- Get the Attachment Description Text
    inbox_item = GetInboxItem(inbox_item_index, 1);
    if (inbox_text ~= nil) then
      -- Print the message text
      DEFAULT_CHAT_FRAME:AddMessage("Inbox Text: "
        ..  GetInboxText(inbox_item_index), 1, 1, 1);
    end
    if (inbox_item ~= nil) then
      -- Print the attachment description
      DEFAULT_CHAT_FRAME:AddMessage("Inbox Item: "
        .. GetInboxItem(inbox_item_index, 1), 1, 1, 1);
    end
  end
end


 -- MAIL_SHOW -> 



 GetInboxNumItems()

 GetInboxItem(index, itemIndex)
 TakeInboxItem(index, itemIndex)

 -- "itemLink" = GetInboxItemLink(index,attachment)


 AutoLootMailItem(index)?
 ZLM_TallyWhacker:REcordDonation("Zatenkein-Shadow Council",124104,90); 
ZLM_TallyWhacker:REcordDonation("Zatenkein-Shadow Council",124104,200);
ZLM_TallyWhacker:REcordDonation("Zatenkein-Shadow Council",124104,128);
ZLM_TallyWhacker:REcordDonation("Zatenkein-Shadow Council",124104,199);