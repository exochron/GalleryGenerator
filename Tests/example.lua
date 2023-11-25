function GG_Test_Example()
    local gg = LibStub("GalleryGenerator")
    gg:TakeScreenshots(
            {
                function(api)
                    api:BackScreen() -- hide game world with black screen

                    ToggleCharacter("PaperDollFrame") -- show character frame
                    api:PointAndClick(PaperDollFrame.ExpandButton)
                end,
                function(api)
                    api:BackScreen(0, 1, 0) -- green screen
                    api:Click(PaperDollFrame.ExpandButton) -- revert previous toggle

                    api:PointAndClick(CharacterFrameTab2)
                end,
            },
            function(api)
                api:Click(CharacterFrameTab1)
                ToggleCharacter("PaperDollFrame")
            end
    )
end