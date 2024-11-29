function GG_Test_Example()
    local gg = LibStub("GalleryGenerator")
    gg:TakeScreenshots(
            {
                -- First shot with open character frame
                function(api)
                    api:BackScreen() -- hide game world with black screen

                    ToggleCharacter("PaperDollFrame") -- show character frame
                    api:PointAndClick(PaperDollFrame.ExpandButton)
                end,
                -- second shot with reputation frame
                function(api)
                    api:BackScreen(0, 1, 0) -- green screen
                    api:Click(PaperDollFrame.ExpandButton) -- revert previous toggle

                    api:PointAndClick(CharacterFrameTab2)
                end,
            },
            -- cleanup and revert previous states
            function(api)
                api:Click(CharacterFrameTab1)
                ToggleCharacter("PaperDollFrame") -- hide character frame
            end
    )
end