do
  local ldb = LibStub("LibDataBroker-1.1")
  VGT.MinimapButton =
  ldb:NewDataObject(
    VGT.Name,
    {
      type = "data source",
      text = "Valhalla Guild Tools",
      icon = "Interface\\Addons\\ValhallaGuildTools\\Valhalla.tga",
      OnClick = function(_, button)
        if button == "RightButton" then
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
          InterfaceOptionsFrame_OpenToCategory(VGT.menu)
        elseif button == "LeftButton" then
          if IsControlKeyDown() then
            VGT.MasterLooter:Toggle()
          else
            VGT.MasterLooter:Toggle()
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

  VGT:RegisterEvent(
    "PLAYER_ENTERING_WORLD",
    function(_, isInitialLogin, isReloadingUI)
      if (isInitialLogin or isReloadingUI) then
        VGT.MinimapIcon:Register(VGT.Name, VGT.MinimapButton, VGT.OPTIONS.MINIMAP)
      end
    end
  )
end
