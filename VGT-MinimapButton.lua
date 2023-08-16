local LibDBIcon = LibStub("LibDBIcon-1.0")

function VGT:InitializeMinimapButton()
  ---@class MinimapButtonDataObject : LibDBIcon.dataObject, LibDataBroker.DataDisplay
  self.minimapButton = LibStub("LibDataBroker-1.1"):NewDataObject(VGT.name, {
    type = "data source",
    text = "Valhalla Guild Tools",
    OnClick = function(_, button)
      local m
      if button == "RightButton" then
        m = self:GetModule("lootTracker")
      elseif button == "LeftButton" then
        if IsControlKeyDown() then
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
        else
          m = self:GetModule("dropTracker")
        end
      end
      if m then
        m:Toggle()
      end
    end,
    ---@type fun(tooltip: GameTooltip)
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then
        return
      end
      tooltip:AddLine("Valhalla Guild Tools", 1, 1, 1)
      tooltip:AddLine(" ")
      tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Left Click:|r Toggle Drop Tracker Window")
      tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Right Click:|r Toggle Loot Master Window")
      tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Ctrl + Left Click:|r Show Options")
    end,
    OnEnter = nil,
    OnLeave = nil,
    icon = self:GetIcon(),
    label = nil,
    suffix = nil,
    tooltip = nil,
    value = nil
  })

  LibDBIcon:Register(self.name, self.minimapButton, self.db.profile.minimapButton)
end

function VGT:GetIcon()
  return self.db.profile.minimapButton.oldIcon and "Interface\\Addons\\ValhallaGuildTools\\Valhalla.classic.tga" or "Interface\\Addons\\ValhallaGuildTools\\Valhalla.wotlk.tga"
end

function VGT:UpdateIcon()
  self.minimapButton.icon = self:GetIcon()
end

function VGT:RefreshMinimapButtonConfig()
  if self.minimapButton then
    self:UpdateIcon()
    LibDBIcon:Refresh(self.name, self.db.profile.minimapButton)
  end
end
