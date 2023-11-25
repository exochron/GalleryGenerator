
assert(LibStub, "LibStub is not installed!")

local MINOR = 1
local GalleryGenerator = LibStub:NewLibrary("GalleryGenerator", MINOR)
---@class GalleryGenerator: { TakeScreenshots: function }
if not GalleryGenerator then return end

local cursor
local backScreen

---Take multiple Screenshots of your UI
---@param shotHandlers table List of Preparation Functions
---@param doneHandler nil|function optional Function to cleanup your UI after the last Screenshot was taken.
function GalleryGenerator:TakeScreenshots(shotHandlers, doneHandler)
    local previousQuality = C_CVar.GetCVar("screenshotQuality")
    if previousQuality ~= "10" then
        C_CVar.SetCVar("screenshotQuality", 10)
    end

    local internalAPI = {}

    local isInterrupted = false
    local function shoot()
        C_Timer.After(1, function()
            if not isInterrupted then
                Screenshot()
            end
        end)
    end

    local function onDone()
        cursor:UnregisterAllEvents()

        if previousQuality ~= "10" then
            C_CVar.SetCVar("screenshotQuality", previousQuality)
        end

        if doneHandler then
            doneHandler(internalAPI)
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
        C_Timer.After(1.1, function()
            bubbleEvent(targetFrame, "OnLeave")
        end)

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
    function internalAPI:Continue()
        if isInterrupted then
            isInterrupted = false
            shoot()
        end
    end

    --- This shows a back screen to hide the game world.
    --- @see https://warcraft.wiki.gg/wiki/API_TextureBase_SetColorTexture
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

    if not cursor then
        cursor = CreateFrame("Frame")
        cursor:SetSize(19, 19)
        cursor:SetFrameStrata("TOOLTIP")

        cursor.tex = cursor:CreateTexture()
        cursor:Hide()
    end

    local currentIndex

    local function proceed()
        local currentHandler
        currentIndex, currentHandler = next(shotHandlers, currentIndex)
        if currentIndex and currentHandler then
            currentHandler(internalAPI)
            shoot()
        else
            onDone()
        end
    end

    cursor:RegisterEvent("SCREENSHOT_SUCCEEDED")
    cursor:RegisterEvent("SCREENSHOT_FAILED")
    cursor:SetScript("OnEvent", function(_, event)
        cursor:Hide()
        if backScreen then
            backScreen:Hide()
        end

        if event == "SCREENSHOT_SUCCEEDED" then
            proceed()
        else
            onDone()
        end
    end)

    proceed()
end