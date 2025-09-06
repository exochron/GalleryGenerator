function GG_Test_Example()
    local gg = LibStub("GalleryGenerator")
    gg:TakeScreenshots(
        {
            -- First screenshot with open character frame
            function(api)
                api:BackScreen() -- hide game world with black screen

                ToggleCharacter("PaperDollFrame") -- show character frame
            end,
            -- second screenshot with reputation frame
            function(api)
                api:BackScreen(0, 1, 0) -- green screen

                api:PointAndClick(CharacterFrameTab2)
            end,
            -- third screenshot toggles player menu
            function(api)
                api:Click(CharacterFrameTab1) -- back to tab 1

                -- open player menu
                UnitPopup_OpenMenu("SELF", { fromPlayerFrame = true, unit = "player", })

                -- wait for menu and point to raid markers
                api:WaitAndPointOnMenuElement(1, 2, function()
                    --wait again and point to skull marker
                    api:WaitAndPointOnMenuElement(2, 1)
                end)
            end,
        },
        -- cleanup and revert previous states
        function(api)
            ToggleCharacter("PaperDollFrame") -- hide character frame
        end
    )
end