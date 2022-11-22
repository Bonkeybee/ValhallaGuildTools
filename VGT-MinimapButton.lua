local LibDBIcon = LibStub("LibDBIcon-1.0")

function VGT:InitializeMinimapButton()
  self.minimapButton = LibStub("LibDataBroker-1.1"):NewDataObject(VGT.name, {
    type = "data source",
    text = "Valhalla Guild Tools",
    OnClick = function(_, button)
      if button == "RightButton" then
        VGT.masterLooter:Toggle()
      elseif button == "LeftButton" then
        if IsControlKeyDown() then
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
        else
          VGT.dropTracker:Toggle()
        end
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then
        return
      end
      tooltip:AddLine("Valhalla Guild Tools", 1, 1, 1)
      tooltip:AddLine(" ")
      tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Left Click:|r Toggle Drop Tracker Window")
      tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Right Click:|r Toggle Loot Master Window")
      tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Ctrl + Left Click:|r Show Options")
    end
  })
  
  function self.minimapButton:UpdateIcon()
    self.icon = VGT.db.profile.minimapButton.oldIcon and
      "Interface\\Addons\\ValhallaGuildTools\\Valhalla.classic.tga" or
      "Interface\\Addons\\ValhallaGuildTools\\Valhalla.wotlk.tga"
  end

  self.minimapButton:UpdateIcon()
  LibDBIcon:Register(self.name, self.minimapButton, self.db.profile.minimapButton)
end

function VGT:RefreshMinimapButtonConfig()
  if self.minimapButton then
    self.minimapButton:UpdateIcon()
    LibDBIcon:Refresh(self.name, self.db.profile.minimapButton)
  end
end
