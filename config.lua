local _, core = ...;
core.config = {};

local config = core.config;
local dorkGambling;
core.gameModes = {
    ["Death Roll"] = {
        minPlayers =2,
        maxPlayers =2,
        name = 'Death Roll',
        checked = true},
    ["Coin Toss"] = {
        minPlayers=2,
        maxPlayers=40, 
        name = 'Coin Toss',
        checked = false
    },
    ["High Low"] = {
        minPlayers=2,
        maxPlayers=40, 
        name = 'High Low',
        checked = false
    }
  }

function config:toggle()
    local menu = dorkGambling or config:CreateMenu();
    menu:SetShown(not menu:IsShown())
end

function config:registerTextEvents()
    dorkGambling:RegisterEvent("CHAT_MSG_SYSTEM");
    dorkGambling:RegisterEvent("CHAT_MSG_PARTY");
    dorkGambling:RegisterEvent("CHAT_MSG_PARTY_LEADER");
    dorkGambling:SetScript("OnEvent", core.TextEventHandler)
end

function config:unregisterTextEvents()
    dorkGambling:UnregisterEvent("CHAT_MSG_SYSTEM");
    dorkGambling:UnregisterEvent("CHAT_MSG_PARTY");
    dorkGambling:UnregisterEvent("CHAT_MSG_PARTY_LEADER");
end


function config:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text, xSize, ySize)
    local btn = CreateFrame("Button", nil, dorkGambling, "GameMenuButtonTemplate");
    btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
    btn:SetSize(xSize,ySize);
    btn:SetText(text);
    btn:SetNormalFontObject("GameFontNormalLarge");
    btn:SetHighlightFontObject("GameFontHighlightLarge");
    return btn;
end

function config:SetGameType(newValue)
    core.SelectedGameType = core.gameModes[newValue].name;
    UIDropDownMenu_SetText(dorkGambling.gameTypeDropDown, core.SelectedGameType);
    CloseDropDownMenus();
end

function core:startGame()
    if GetNumGroupMembers() == 0 then
        print("Cant start a game when you're not in a party!")
        return;
    end
    core.game = core.game or core.newGame(core.SelectedGameType, core.currentBet)
    if core.game.state == nil then
        dorkGambling.startBtn:SetText('Start Roll');
        dorkGambling.startBtn:Disable();
        dorkGambling.cancleBtn:Enable();
        config:registerTextEvents();
        core.game.state = 'Waiting';
        core:dgMessage('Game Started! Type 1 in chat to join, -1 to leave', "Party")
    elseif (core.game.state == 'Waiting') then
        dorkGambling.startBtn:SetText('In Progress');
        core.game.state = 'In Progress'
    end
end

function core:resetGame()
    core.game = nil;
    dorkGambling.startBtn:SetText('Start');
    dorkGambling.startBtn:Enable();
    dorkGambling.playerCount:SetText('Players in game: 0');
    dorkGambling.playerCount:SetFontObject("GameFontNormal");
    dorkGambling.cancleBtn:Disable();
    config.unregisterTextEvents();
end

function config:PlayersInGame()
    --
end

function config:CreateMenu()
    dorkGambling = CreateFrame("FRAME", "dorkGambling", UIParent, "UIPanelDialogTemplate");

    --------------------
    -- Make Draggable --
    --------------------
    dorkGambling:SetMovable(true)
    dorkGambling:EnableMouse(true)
    dorkGambling:RegisterForDrag("LeftButton")
    dorkGambling:SetScript("OnDragStart", dorkGambling.StartMoving)
    dorkGambling:SetScript("OnDragStop", dorkGambling.StopMovingOrSizing)

    dorkGambling:SetSize(200,200);
    dorkGambling:SetPoint("Center", UIParent, "Center");

    dorkGambling.Title:SetFontObject("GameFontHighlight");
    dorkGambling.Title:SetPoint("Left", dorkGamblingTitleBG, "Left", 6, 2);
    dorkGambling.Title:SetText("Dork Gambling");

    ------------------------------
    -- Game Type DropDown menu ---
    ------------------------------
    dorkGambling.gameTypeDropDown = CreateFrame("Frame", "GameTypeDropDown", dorkGambling , "UIDropDownMenuTemplate");
    GameTypeDropDown.displayMode = "Menu";
    UIDropDownMenu_Initialize(dorkGambling.gameTypeDropDown, 
    function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = config.SetGameType;
        for k,v in pairs(core.gameModes) do            
            info.text, info.arg1, info.checked = v.name, k, v.name == core.SelectedGameType
            UIDropDownMenu_AddButton(info)
        end
    end)
    dorkGambling.gameTypeDropDown:SetPoint('CENTER', dorkGamblingDialogBG, "TOP", 0, -20 );
    UIDropDownMenu_SetWidth(dorkGambling.gameTypeDropDown, 150);
    core.SelectedGameType = core.gameModes["Death Roll"].name;
    UIDropDownMenu_SetText(dorkGambling.gameTypeDropDown, core.SelectedGameType);

    ---------------------------
    ---- BUTTONS, MARRAAAZZZ---
    ---------------------------
    dorkGambling.startBtn = self:CreateButton("CENTER", dorkGambling.gameTypeDropDown, "TOP", 50, -50, "Start", 80, 20);
    dorkGambling.startBtn:SetScript("OnClick", core.startGame);

    dorkGambling.cancleBtn = self:CreateButton("BOTTOM", dorkGambling, "BOTTOM", 0, 10, "Reset Game", 130, 20);
    dorkGambling.cancleBtn:SetScript("OnClick", core.resetGame);
    dorkGambling.cancleBtn:Disable();

    ---------------------------
    -- Input for bet ammount --
    ---------------------------
    dorkGambling.editbox = CreateFrame("EditBox", nil, dorkGambling, "InputBoxTemplate")
    dorkGambling.editbox:SetMultiLine(false)
    dorkGambling.editbox:SetPoint("CENTER", dorkGamblingDialogBG, "TOP", -40, -53);
    dorkGambling.editbox:SetFontObject("ChatFontNormal")
    dorkGambling.editbox:SetWidth(80)
    dorkGambling.editbox:SetHeight(20)
    dorkGambling.editbox:SetText(1000)
    dorkGambling.editbox:SetAutoFocus(false)
    dorkGambling.editbox:SetNumeric();
    dorkGambling.editbox:SetScript("OnEscapePressed", function() 
        dorkGambling.currentBet = dorkGambling.editbox:GetNumber();    
    end)
    dorkGambling.editbox:SetScript("OnEnterPressed", function()
        dorkGambling.currentBet = dorkGambling.editbox:GetNumber();
    end
    )

    -------------
    -- Divider --
    -------------
    dorkGambling.line = dorkGambling:CreateTexture()
    dorkGambling.line:SetTexture("Interface/BUTTONS/WHITE8X8")
    dorkGambling.line:SetColorTexture(1 ,1, 1, .2)
    dorkGambling.line:SetSize(180, 2)
    dorkGambling.line:SetPoint("CENTER",dorkGamblingDialogBG, "TOP",0,-75)

    ------------------
    --- texts --------
    ------------------
    dorkGambling.playerCount = dorkGambling:CreateFontString("Player Count:","dorkGamblingDialogBG");
    dorkGambling.playerCount:SetFontObject("GameFontNormal");
    dorkGambling.playerCount:SetPoint("TOP", dorkGambling.line, "CENTER", 0, -2);
    dorkGambling.playerCount:SetText("Players in game: 0");


    dorkGambling:Hide();
    return dorkGambling
end

function config:updatePlayerCount()
    if core.game.numPlayers ~= nil then
        dorkGambling.playerCount:SetText("Players in game: " .. core.game.numPlayers .. " (max:"..core.game.maxNumPlayers..")");
    end
    if core.game:gameCanStart() then
        dorkGambling.playerCount:SetFontObject("GameFontGreen");
        dorkGambling.startBtn:Enable()
    else
        dorkGambling.playerCount:SetFontObject("GameFontNormal");
        dorkGambling.startBtn:Disable()
    end

end