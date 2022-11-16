do
  local ldb = LibStub("LibDataBroker-1.1")
  VGT.minimapButton =
  ldb:NewDataObject(
    VGT.name,
    {
      type = "data source",
      text = "Valhalla Guild Tools",
      icon = "Interface\\Addons\\ValhallaGuildTools\\Valhalla.wotlk.tga",
      OnClick = function(_, button)
        if button == "RightButton" then
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
        elseif button == "LeftButton" then
          if IsControlKeyDown() then
            VGT.masterLooter:Toggle()
          else
            VGT.masterLooter:Toggle()
          end
        end
      end,
      OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
          return
        end
        tooltip:AddLine("Valhalla Guild Tools", 1, 1, 1)
        tooltip:AddLine(" ")
        tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Left Click:|r Toggle Loot Master Window")
        tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Right Click:|r Show Options")
        --tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Ctrl + Left Click:|r Toggle Loot Master Window")
      end
    }
  )

  function VGT.minimapButton:UpdateIcon()
    self.icon = VGT.OPTIONS.oldIcon and
      "Interface\\Addons\\ValhallaGuildTools\\Valhalla.classic.tga" or
      "Interface\\Addons\\ValhallaGuildTools\\Valhalla.wotlk.tga"
  end

  VGT:RegisterEvent(
    "PLAYER_ENTERING_WORLD",
    function(_, isInitialLogin, isReloadingUI)
      if (isInitialLogin or isReloadingUI) then
        VGT.minimapButton:UpdateIcon()
        LibStub("LibDBIcon-1.0"):Register(VGT.name, VGT.minimapButton, VGT.OPTIONS.MINIMAP)
      end
    end
  )
end
