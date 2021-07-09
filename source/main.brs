Sub Main (args as dynamic) as void
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")

    screen.setMessagePort(port)
    'Define all global VAR and CONSTS.
    m.global = screen.getGlobalNode()
    'To control the quit exit event.
    m.global.addField("equitTracker", "int", True)
    'Observe when app need to be closed
    m.global.observeField("equitTracker", port)
    'Observe when app need to be closed
    m.global.addFields({ state: {} })
    'Start Scene'
    scene = screen.CreateScene("MainScene")
    ' Deeplinking on launch
    if args.DoesExist("mediaType") and args.DoesExist("contentId")
        deeplink = {
            contentId: args.contentID
            ' Dont need the media type for now
            mediaType: args.mediaType
        }
        ? deeplink
        scene.launchArgs = deeplink
    end if
    screen.show()
    While true
        msg = wait(0, port)
        If m.global.equitTracker = 1 Then
            'Quit Application'
            END
        End If
        If type(msg) = "roSGScreenEvent"
            If msg.isScreenClosed() Then Exit While
        end if
    End While
End Sub
