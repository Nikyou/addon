---@class wowutilsPrivate
---@field notifications wowutils_notifications

---@type string, wowutilsPrivate
local addon_name, ns = ...
local floor = math.floor

local LSM = LibStub("LibSharedMedia-3.0")

---@class wowutils_notifications
---@field OnPositionChanged fun()? set by the gui so the sliders follow a drag
ns.notifications = {
  LSM = LSM,
}

-- share our bundled fonts through LSM, so they show up in the font list (and in other addons)
do
  local fontFolder = [[Interface\AddOns\wowutils\media\fonts\]]
  local latinCyrillic = LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU
  LSM:Register("font", "IBM Plex Sans", fontFolder .. "IBMPlexSans-Regular.ttf", latinCyrillic)
  LSM:Register("font", "IBM Plex Sans Medium", fontFolder .. "IBMPlexSans-Medium.ttf", latinCyrillic)
  LSM:Register("font", "IBM Plex Sans SemiBold", fontFolder .. "IBMPlexSans-SemiBold.ttf", latinCyrillic)
  LSM:Register("font", "IBM Plex Mono", fontFolder .. "IBMPlexMono-Regular.ttf", latinCyrillic)
  LSM:Register("font", "IBM Plex Mono Medium", fontFolder .. "IBMPlexMono-Medium.ttf", latinCyrillic)
  LSM:Register("font", "Cal Sans SemiBold", fontFolder .. "CalSans-SemiBold.ttf", LSM.LOCALE_BIT_western)
end

local msgFrame = CreateFrame("MessageFrame", "WowUtilsNotificationFrame", UIParent)
msgFrame:SetSize(800, 300)
msgFrame:SetFrameStrata("HIGH")
msgFrame:SetInsertMode("TOP") -- BOTTOM draws outside of the frame, revisit if we want a grow up option
msgFrame:SetFading(true)
msgFrame:SetClampedToScreen(true)
msgFrame:SetMovable(true)
msgFrame:EnableMouse(false)
msgFrame:RegisterForDrag("LeftButton")

-- only visible while unlocked, shows where the frame is and what can be dragged
local unlockOverlay = CreateFrame("Frame", nil, msgFrame, "BackdropTemplate")
unlockOverlay:SetAllPoints(msgFrame)
unlockOverlay:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  edgeSize = 1,
})
unlockOverlay:SetBackdropColor(0.22, 0.70, 0.44, 0.15)
unlockOverlay:SetBackdropBorderColor(0.22, 0.70, 0.44, 1)
unlockOverlay:Hide()
local unlockLabel = unlockOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
unlockLabel:SetPoint("BOTTOM", unlockOverlay, "BOTTOM", 0, 6)
unlockLabel:SetText("WowUtils notifications - drag to move")

msgFrame:SetScript("OnDragStart", msgFrame.StartMoving)
msgFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(false) -- position lives in our own options, not in layout-local
  -- StopMovingOrSizing can re-anchor to any point, so normalize back to an offset from the center
  local cx, cy = self:GetCenter()
  local ux, uy = UIParent:GetCenter()
  local o = WowUtilsDB.options.notifications
  o.x = floor(cx - ux + 0.5)
  o.y = floor(cy - uy + 0.5)
  ns.notifications.ApplySettings()
  if ns.notifications.OnPositionChanged then
    ns.notifications.OnPositionChanged()
  end
end)

function ns.notifications.ApplySettings()
  local o = WowUtilsDB.options.notifications
  msgFrame:ClearAllPoints()
  msgFrame:SetPoint("CENTER", UIParent, "CENTER", o.x, o.y)
  -- Fetch falls back to LSM's default font if the saved one isn't registered (yet)
  msgFrame:SetFont(LSM:Fetch("font", o.font), o.fontSize, "OUTLINE")
  msgFrame:SetSpacing(o.spacing)
  msgFrame:SetJustifyH(o.justify)
  msgFrame:SetTimeVisible(o.timeVisible)
  msgFrame:SetFadeDuration(o.fadeDuration)
end

---@param msg string
---@param r number? defaults to the color from options
---@param g number?
---@param b number?
function ns.notifications.AddMessage(msg, r, g, b)
  if not r then
    local c = WowUtilsDB.options.notifications.color
    r, g, b = c.r, c.g, c.b
  end
  msgFrame:AddMessage(msg, r, g, b)
end

---@param unlocked boolean
function ns.notifications.SetUnlocked(unlocked)
  msgFrame:EnableMouse(unlocked)
  unlockOverlay:SetShown(unlocked)
end

ns.notifications.ApplySettings()

-- the saved font can come from an addon that loads after us, apply it once it gets registered
LSM.RegisterCallback(ns.notifications, "LibSharedMedia_Registered", function(_, mediatype, key)
  if mediatype == "font" and key == WowUtilsDB.options.notifications.font then
    ns.notifications.ApplySettings()
  end
end)
