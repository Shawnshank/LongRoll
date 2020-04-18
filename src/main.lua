

local raid_snapshot = {};
local roll_list = {};
local isRolling = false;
local isLeaderJoin = false;
local high_range_limit = 1000;
local low_range_limit = 1;
local roll_phrase = "Roll!";
local player_frame_font_strings = {};
local sorted_roll_list = {};

-- TESTING PURPOSE
--local test_players_roll = {};
--test_players_roll["a"] = 1000;
--test_players_roll["b"] = 328;
--test_players_roll["c"] = 687;
--test_players_roll["d"] = 254;
--test_players_roll["e"] = 473;
--test_players_roll["f"] = 100;
--test_players_roll["g"] = 564;
-- --------------------------

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
    -- TESTING PURPOSE
    --for playerNameTest, _ in pairs(test_players_roll) do
    --    if (playerNameTest) then
    --        raid_snapshot[playerNameTest] = 1;
    --    end
    --end
    --for playerNameTest, roll in pairs(test_players_roll) do
    --    if (playerNameTest) then
    --        roll_list[playerNameTest] = roll;
    --    end
    --end
    -- --------------------------
end

function Shallow_Copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Deep_Copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Sort_Roll_list()
    local roll_list_snapshot = Shallow_Copy(roll_list);
    local index = 1;
    local isSorting = true;
    while isSorting do
        local current_lowest = 10000000;
        local current_lowest_player = "test";
        for playerName, roll in pairs(roll_list_snapshot) do
            if tonumber(roll) < tonumber(current_lowest) then
                if index > 1 then
                    for i = 1, Table_Length(sorted_roll_list) do
                        if playerName == sorted_roll_list[i] then
                            print("Already sorted")
                        else
                            current_lowest = roll;
                            current_lowest_player = playerName;
                        end
                    end
                else
                    current_lowest = roll;
                    current_lowest_player = playerName;
                end
            end
        end
        roll_list_snapshot[current_lowest_player] = nil;
        if current_lowest_player == "test" then
            isSorting = false
        else
            sorted_roll_list[index] = current_lowest_player;
        end
        index = index + 1;
    end
end

function Clear_Raid_Snapshot()
    isRolling = false;
    for playerName, _ in pairs(raid_snapshot) do
        local ref = player_frame_font_strings[playerName];
        ref:SetTextColor(1, 1, 1, 0);
    end
    raid_snapshot = {};
    roll_list = {};
    sorted_roll_list = {};
    print("Cleared previous rolls")
end

function Print_help()
    print("LongRoll Usage:");
    print("/lr show - Shows the UI");
    print("/lr hide - Hides the UI");
end

function Print_Raid()
    print("Printing internal roll info")
    print("---------------");
    for playerName, _ in pairs(raid_snapshot) do
        print(string.format("%s: %s", playerName, raid_snapshot[playerName]));
    end
    print("---------------");
    Sort_Roll_list();
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
    local current_lowest = 1000000;
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
    SendChatMessage(roll_phrase, "RAID_WARNING");

    local index = 0;
    
    for playerName, _ in pairs(raid_snapshot) do
        local newPlayerString = player_frame:CreateFontString(playerName, "BACKGROUND", "GameFontNormal");
        player_frame_font_strings[playerName] = newPlayerString;
        newPlayerString:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE");
        newPlayerString:SetShadowOffset(1, -1)
        newPlayerString:SetShadowColor(1,1,1)
        newPlayerString:SetPoint("TOPLEFT", 20 ,-20 - index * 20);
        newPlayerString:SetFormattedText("%s: ", playerName);
        newPlayerString:SetTextColor(0, 0, 0);
        index = index + 1;
    end
    player_frame:SetHeight(index * 20 + 30)
    Update_Player_Frame();
    player_frame:Show()

end

function Compare(a,b)
    return a < b
end

function Find_lowest_rolls()
    Sort_Roll_list();
    local fontstring_ref = player_frame_font_strings[sorted_roll_list[1]];
    fontstring_ref:SetTextColor(1, 0, 0.5);
    local fontstring_ref = player_frame_font_strings[sorted_roll_list[2]];
    fontstring_ref:SetTextColor(1, 0.5, 0);
    print("Players sorted by lowest roll:");
    print("-----------------");
    local index = 1;
    for index=1,Table_Length(sorted_roll_list) do
        local playername = tostring(sorted_roll_list[index]);
        print(index, ": ", playername, " - ", roll_list[playername]);
    end
    print("-----------------");
end

EventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5, arg6)
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
        Print_help();
    end
end

SLASH_LONG1 = "/longroll"
SLASH_LONG2 = "/lr"
SlashCmdList["LONG"] = LongRollCommands