
assert(LibStub, "LibStub is not installed!")

--@do-not-package@
local MINOR = 9999999
--@end-do-not-package@
--[===[@non-debug@
local MINOR = @project-version@
--@end-non-debug@]===]
local GalleryGenerator = LibStub:NewLibrary("GalleryGenerator", MINOR)
---@class GalleryGenerator: { TakeScreenshots: function }
if not GalleryGenerator then return end

local DELAY = 1.0

local cursor
local backScreen
local openMenus

---Take multiple Screenshots of your UI
---@param shotHandlers table List of Preparation Functions
---@param doneHandler nil|function optional Function to cleanup your UI after the last Screenshot was taken.
function GalleryGenerator:TakeScreenshots(shotHandlers, doneHandler)

    ---@class GalleryGeneratorApi: { Point: function, Point: function, Click: function, PointAndClick: function, Wait: function, Continue: function, BackScreen: function, GetOpenMenuElement: function, WaitAndPointOnMenuElement: function }
    local internalAPI = {}
    local cleanupQueue = {}

    local defaultCVars = {
        screenshotQuality = 10, -- Set quality to max to also get rid of hidden watermark.
        Contrast = C_CVar.GetCVarDefault("Contrast"),
        Gamma = C_CVar.GetCVarDefault("Gamma"),
        Brightness = C_CVar.GetCVarDefault("Brightness"),
    }
    local previousCVars = {}
    for cvar, defaultVal in pairs(defaultCVars) do
        local val = C_CVar.GetCVar(cvar)
        if nil ~= val then
            previousCVars[cvar] = tonumber(val)
        end
        C_CVar.SetCVar(cvar, defaultVal)
    end

    local isInterrupted = false
    local function shoot()
        if not isInterrupted then
            C_Timer.After(DELAY, function()
                if not isInterrupted then
                    Screenshot()
                end
            end)
        end
    end

    if nil == openMenus then
        openMenus = {}
        local menuManager = Menu.GetManager()
        if menuManager then
            local function collectMenus(self, _, menuDescription)
                local menu = self:GetOpenMenu()
                if not menu then
                    return
                end

                openMenus = {menu}
                menuDescription:AddMenuAcquiredCallback(function(frame)
                    openMenus[#openMenus+1] = frame
                end)
                menuDescription:AddMenuReleasedCallback(function()
                    openMenus[#openMenus] = nil
                end)
            end

            hooksecurefunc(menuManager, 'OpenMenu', collectMenus)
            hooksecurefunc(menuManager, 'OpenContextMenu', collectMenus)
            hooksecurefunc(menuManager, 'CloseMenus', function()
                openMenus = {}
            end)
        end
    end

    --- This places a virtual pointer icon central on the given frame.
    --- It also triggers script handlers for OnEnter and all parent frames. Subsequently, it also triggers OnLeave.
    ---@param targetFrame table|Frame A frame to place the pointer onto
    ---@param offsetX nil|number Optional offset right of the center (negative for left)
    ---@param offsetY nil|number Optional offset up of the center (negative for down)
    ---@return table|TextureBase Texture instance of pointer icon for own further customization
    function internalAPI:Point(targetFrame, offsetX, offsetY)
        cursor.tex:SetAllPoints()
        cursor.tex:SetTexture()
        cursor.tex:SetAtlas("Cursor_Point_48")
        cursor:SetPoint("TOPLEFT", targetFrame, "CENTER", offsetX or 0, offsetY or 0)
        cursor:Show()

        local originalIsMouseOver = targetFrame.IsMouseOver
        targetFrame.IsMouseOver = function()
            return true
        end

        local function bubbleEvent(frame, event)
            local onEvent = frame:GetScript(event)
            if onEvent then
                onEvent(frame, false)
            end
            local parent = frame:GetParent()
            if parent then
                bubbleEvent(parent, event)
            end
        end
        bubbleEvent(targetFrame, "OnEnter")
        table.insert(cleanupQueue, function()
            targetFrame.IsMouseOver = originalIsMouseOver
        end)
        table.insert(cleanupQueue, function()
            bubbleEvent(targetFrame, "OnLeave")
        end)

        -- show highlight effects on buttons
        if targetFrame.IsEnabled and targetFrame:IsEnabled() then
            local highlightTexture = targetFrame.GetHighlightTexture and targetFrame:GetHighlightTexture()
            if highlightTexture then
                local drawLayer, drawLevel = highlightTexture:GetDrawLayer()
                highlightTexture:SetDrawLayer("ARTWORK")
                table.insert(cleanupQueue, function()
                    highlightTexture:SetDrawLayer(drawLayer, drawLevel)
                end)
            end
            local highlightFont = targetFrame.GetHighlightFontObject and targetFrame:GetHighlightFontObject()
            if highlightFont then
                local normalFont = targetFrame:GetNormalFontObject()
                targetFrame:SetNormalFontObject(highlightFont)
                table.insert(cleanupQueue,  function()
                    targetFrame:SetNormalFontObject(normalFont)
                end)
            end
        end

        return cursor.tex
    end

    --- This triggers all cLick handlers on the given frame. (In order: OnMouseDown, OnMouseUp, PreClick, OnClick, PostClick)
    ---@param targetFrame table|Frame Frame to trigger a click on
    ---@param button nil|string Optional mouse button identifier. Defaults to "LeftButton"
    function internalAPI:Click(targetFrame, button)
        local function trigger(event, ...)
            local onEvent = targetFrame:GetScript(event)
            if onEvent then
                onEvent(targetFrame, button or "LeftButton", ...)
            end
        end
        trigger("OnMouseDown")
        trigger("OnMouseUp")
        trigger("PreClick", false)
        trigger("OnClick", false)
        trigger("PostClick", false)
    end

    --- A simple function to subsequently call Point() and Click()
    ---@param targetFrame table|Frame Frame to place the pointer on and trigger a LeftClick
    ---@return table|TextureBase Texture instance of pointer icon for own further customization
    function internalAPI:PointAndClick(targetFrame)
        local tex = self:Point(targetFrame)
        self:Click(targetFrame)
        return tex
    end

    --- This interrupts the internal Screenshot timer, so you can wait longer for your UI to finish loading.
    --- You HAVE TO call Continue() on your own to process further!
    function internalAPI:Wait()
        isInterrupted = true
    end

    --- This continues processing after a Wait() interruption.
    --- @async
    function internalAPI:Continue()
        if isInterrupted then
            isInterrupted = false
            shoot()
        end
    end

    --- This shows a back screen to hide the game world.
    --- @source https://warcraft.wiki.gg/wiki/API_TextureBase_SetColorTexture
    --- @param red nil|number Optional red component [0.0 - 1.0]
    --- @param green nil|number Optional green component [0.0 - 1.0]
    --- @param blue nil|number Optional blue component [0.0 - 1.0]
    function internalAPI:BackScreen(red, green, blue)
        if not backScreen then
            backScreen = CreateFrame("Frame")
            backScreen:SetAllPoints()
            backScreen:SetFrameStrata("BACKGROUND")
            backScreen.tex = backScreen:CreateTexture()
            backScreen.tex:SetAllPoints()
        end

        backScreen.tex:SetColorTexture(red or 0, green or 0, blue or 0, 1)
        backScreen:Show()
    end

    --- Returns the n-th element frame of an open menu.
    --- @param menuIndex number Index number of open Menu (1=start menu, 2=first submenu, 3=second submenu...)
    --- @param elementIndex number Index number of element from the top. Spacer and divider do count as well.
    function internalAPI:GetOpenMenuElement(menuIndex, elementIndex)
        if openMenus and openMenus[menuIndex] then
            local children = {openMenus[menuIndex]:GetChildren()}
            return children[elementIndex+2]
        end
    end

    --- Interrupts execution and waits for menu element to be rendered. It also points onto the element.
    --- You can chain `WaitAndPointOnMenuElement` in your `onDone` handler to traverse multiple submenus.
    --- You need to `Continue()` in your own `onDone` function. If you don't provide a function, it continues automatically.
    --- @async
    --- @param menuIndex number Index number of open Menu (1=start menu, 2=first submenu, 3=second submenu...)
    --- @param elementIndex number Index number of element from the top. Spacer and divider do count as well.
    --- @param onDone nil|function Optional custom handling gets element frame as first parameter.
    --- @param offsetX nil|number Optional offset right of the element center (negative for left)
    --- @param offsetY nil|number Optional offset up of the element center (negative for down)
    function internalAPI:WaitAndPointOnMenuElement(menuIndex, elementIndex, onDone, offsetX, offsetY)
        self:Wait()
        onDone = onDone or self.Continue

        local ticker
        ticker = C_Timer.NewTicker(0.1, function()
            local element = self:GetOpenMenuElement(menuIndex, elementIndex)
            if element then
                ticker:Cancel()
                self:Point(element, offsetX, offsetY)
                C_Timer.After(0.2, function() -- wait for submenu to be rendered
                    onDone(element)
                end)
            end
        end)
    end

    if not cursor then
        cursor = CreateFrame("Frame")
        cursor:SetSize(19, 19)
        cursor:SetFrameStrata("TOOLTIP")

        cursor.tex = cursor:CreateTexture()
        cursor:Hide()
    end

    local function cleanup()
        cursor:Hide()
        if backScreen then
            backScreen:Hide()
        end
        for _, handler in ipairs(cleanupQueue) do
            handler()
        end
        cleanupQueue = {}

        if MenuUtil then
            -- Modern Menu Api
            Menu.GetManager():CloseMenus()
        end
        if CloseDropDownMenus then
            -- Legacy Menu Api
            CloseDropDownMenus()
        end
    end

    local function onDone()
        cleanup()
        cursor:UnregisterAllEvents()

        for cvar, value in pairs(previousCVars) do
            C_CVar.SetCVar(cvar, value)
        end

        if doneHandler then
            doneHandler(internalAPI)
        end
    end

    local currentIndex

    local function proceed()
        local currentHandler
        currentIndex, currentHandler = next(shotHandlers, currentIndex)
        if currentIndex and currentHandler then
            if type(currentHandler) == "function" then
                cleanup()
                if xpcall(currentHandler, CallErrorHandler, internalAPI) then
                    shoot()
                else
                    onDone()
                end
            else
                proceed()
            end
        else
            onDone()
        end
    end

    cursor:RegisterEvent("SCREENSHOT_SUCCEEDED")
    cursor:RegisterEvent("SCREENSHOT_FAILED")
    cursor:SetScript("OnEvent", function(_, event)
        if event == "SCREENSHOT_SUCCEEDED" then
            proceed()
        else
            onDone()
        end
    end)

    proceed()
end