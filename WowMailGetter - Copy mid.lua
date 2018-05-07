Profile mailbox

Starting work = 1;



	inbox_items = getinboxitems();

	local slots taken up = 0;

	for i= 1-inbox_items do   -- all mail items

		, , , hasitems = getmessage(#)
		if hasItems
			
			for j= 1-12 do
				profile[i][j] = {ItemId, quantity};
				if mailProfilebyID[ItemID] then
					mailProfilebyID[ItemID] = mailProfilebyID[ItemID] + quantity;
				else
					mailProfilebyID[ItemID] = quantity;
				end
				slots taken up ++;
			end
		end
	end

return mailProfilebyID; -- since the loop might want new versions.

profile bags




for i= 1-#bag do

	for for j = 1-#slots do

		itemID, quantity = get ID()
		if localbagprofilebyID[itemId] then
			localbagprofilebyname[itemId] = quantity
		end

	end

end

return localbagprofilebyname  -- since this is used both to get a starting profile, and an evaluation profile.





predicted bags afterwards

for k, v in pairs(mailProfilebyID[ItemID]) do

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