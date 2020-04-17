

local raid_snapshot = {};
local roll_list = {};
local isRolling = false;
local isLeaderJoin = false;
local high_range_limit = 1000;
local low_range_limit = 1;
local roll_phrase = "Roll!";
local player_frame_font_strings = {};

local EventFrame = CreateFrame("frame", "EventFrame");
EventFrame:RegisterEvent("CHAT_MSG_SYSTEM");
EventFrame:RegisterEvent("CHAT_MSG_RAID");
EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER");

getglobal(button_leader_join:GetName() .. "Text"):SetText("Leader join");
editbox_lower_bound:SetNumber(low_range_limit);
editbox_upper_bound:SetNumber(high_range_limit);
Longroll_main_frame:RegisterForDrag("LeftButton");

local player_frame = CreateFrame("Frame",nil,UIParent)
player_frame:SetFrameStrata("BACKGROUND")
player_frame:SetWidth(300)
player_frame:SetMovable(true);
player_frame:EnableMouse(true);
player_frame:RegisterForDrag("LeftButton");
player_frame:SetScript("OnLoad", player_frame.Hide);
player_frame:SetScript("OnDragStart", player_frame.StartMoving);
player_frame:SetScript("OnDragStop", player_frame.StopMovingOrSizing);

player_frame:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=1, tileSize=32, edgeSize=32,
    insets={left=11, right=12, top=12, bottom=11}
})

player_frame:SetPoint("CENTER",0,0)

function Toggle_Leader_Join()
    isLeaderJoin = not isLeaderJoin;
end

function Start_Moving_Frame()
    Longroll_main_frame:StartMoving();
end
function Stop_Moving_Frame()
    Longroll_main_frame:StopMovingOrSizing();
end

function Hide_Frames()
    Longroll_main_frame:Hide();
    player_frame:Hide();
end

function Get_Raid_Snapshot()
    for i = 1,40,1 do
        local playerName, rank = GetRaidRosterInfo(i);

        if (playerName) then
            if (isLeaderJoin and rank == 2) then
                raid_snapshot[playerName] = 0;
            elseif (rank == 2) then
                _ = 1+1;
            else
                 raid_snapshot[playerName] = 0;
            end
        end
    end
end

function Clear_Raid_Snapshot()
    isRolling = false;
    for playerName, _ in pairs(raid_snapshot) do
        local ref = player_frame_font_strings[playerName];
        ref:SetTextColor(1, 1, 1, 0);
        --ref:SetParent(nil);
        --ref:ClearAllPoints();
    end
    raid_snapshot = {};
    roll_list = {};
    print("Cleared everything")
end

function Print_Raid()
    print("Printing raid info!")
    print("---------------");
    for playerName, _ in pairs(raid_snapshot) do
        print(string.format("%s: %s", playerName, raid_snapshot[playerName]));
    end
    print("---------------");
    for playerName, _ in pairs(roll_list) do
        print(string.format("%s: %s", playerName, roll_list[playerName]));
    end
end

local function Find_Roll(event, arg1, arg2, arg3, arg4, arg5, arg6)
    if string.match(arg1, "rolls") then
        local name = string.match(arg1, "(%a+)%s");
        local roll = string.match(arg1, "%s(%d+)");
        local low_range = string.match(arg1, "%s.(%d+)-");
        local high_range = string.match(arg1, "-(%d+)");
        return name, roll, low_range, high_range
    end
end

function Table_Length(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function Update_Player_Frame()
    for playerName, hasRolled in pairs(raid_snapshot) do
        local string_ref = player_frame_font_strings[playerName];
        if roll_list[playerName] == nil then
            string_ref:SetFormattedText("%s:", playerName);
        else
            string_ref:SetFormattedText("%s: %d", playerName, roll_list[playerName]);
        end
        if tonumber(hasRolled) > 0 then
            string_ref:SetTextColor(0, 1, 0);
        else
            string_ref:SetTextColor(1, 0, 0);
        end
    end
end

function Start_Roll()
    Clear_Raid_Snapshot();
    Get_Raid_Snapshot();
    isRolling = true;
    high_range_limit = editbox_upper_bound:GetNumber();
    low_range_limit = editbox_lower_bound:GetNumber();
    --SendChatMessage(roll_phrase, "RAID_WARNING");

    local index = 0;
    
    for playerName, _ in pairs(raid_snapshot) do
        local newPlayerString = player_frame:CreateFontString(playerName, "BACKGROUND", "GameFontNormal");
        player_frame_font_strings[playerName] = newPlayerString;
        newPlayerString:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE");
        newPlayerString:SetShadowOffset(1, -1)
        newPlayerString:SetShadowColor(1,1,1)
        newPlayerString:SetPoint("TOPLEFT", 20 ,-50 - index * 20);
        newPlayerString:SetFormattedText("%s: ", playerName);
        newPlayerString:SetTextColor(0, 0, 0);
        index = index + 1;
    end
    player_frame:SetHeight(index * 20 + 50 + 10)
    Update_Player_Frame();
    player_frame:Show()

end

function Compare(a,b)
    return a[1] < b[1]
end

function Find_lowest_rolls()
    table.sort(roll_list, Compare);
    print("Sorted roll list:");
    print("-----------------");
    for playerName, _ in pairs(roll_list) do
        print(string.format("%s: %s", playerName, roll_list[playerName]));
    end
end

EventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5, arg6)
	if(event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
		print("Raid Message Event Captured!");
    end
    if(event == "CHAT_MSG_SYSTEM" and isRolling) then
        local name, roll, range_low, range_high = Find_Roll(event, arg1, arg2, arg3, arg4, arg5, arg6);
        local playerIsInRaid = false;
        for playerName, _ in pairs(raid_snapshot) do
            if (playerName == name) then
                if raid_snapshot[playerName] == 1 then
                    print(string.format("%s has already rolled!", playerName));
                else
                    playerIsInRaid = true;
                    raid_snapshot[playerName] = 1;
                end
            end
        end
        if playerIsInRaid then
            if (tonumber(range_high) == tonumber(high_range_limit)) then
                if (tonumber(range_low) == tonumber(low_range_limit)) then
                    roll_list[name] = roll;
                    Update_Player_Frame();
                    if Table_Length(roll_list) == Table_Length(raid_snapshot) then
                        isRolling = false;
                        print("Everyone has rolled!");
                        Find_lowest_rolls();
                    end
                else
                    raid_snapshot[name] = 0;
                    print(string.format("%s rolled in the wrong range [(%s-%s) instead of (%s-%s)]", name, range_low, range_high, low_range_limit, high_range_limit));
                end
            else
                raid_snapshot[name] = 0;
                print(string.format("%s rolled in the wrong range [(%s-%s) instead of (%s-%s)]", name, range_low, range_high, low_range_limit, high_range_limit));
            end
        end
    end
end)

function LongRollCommands(msg, editbox)
    if msg == "show" then
        Longroll_main_frame:Show();
    elseif msg == "hide" then
        Longroll_main_frame:Hide();
        player_frame:Hide();
    else
        print("Did not understand this command");
    end
end

SLASH_LONG1 = "/longroll"
SLASH_LONG2 = "/lr"
SlashCmdList["LONG"] = LongRollCommands