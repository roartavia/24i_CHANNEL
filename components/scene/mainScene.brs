Sub init()
    'Setup Config Before Starting the app'
    m.configSetupTask = CreateObject("roSGNode", "ConfigSetupTask")
    ' Menu bar
    ' m.menu = m.top.findNode("menu")
    ' m.menu.observeField("selectedIndex", "onFocusScreen")
    ' Group to manage the views currently rendered
    m.viewContainer = m.top.findNode("viewContainer")
    ' Home Screen, always ready
    m.homeUI = m.top.findNode("homeUI")
    ' Home Screen, always ready
    m.searchUI = m.top.findNode("searchUI")
    ' Loading screen for feeds, etc.
    m.loadingScreen = m.top.findNode("loadingScreen")
    ' Dialog for fatal errors
    m.errorDialog = m.top.findNode("errorDialog")
    m.errorDialog.buttons = ["Retry"]
    ' @TODO: manage the rest of the view in here - try to reuse the same views
    m.views = [m.homeUI]
    m.currentViewIndex = 0
    ' Set initial state,
    m.global.addReplace("state", getInitialState())
    ' Start setting the content.
    startConfigFetch()
End Sub

'Start Config Fetching'
Function startConfigFetch()
    showLoadingScreen()
    m.configSetupTask.ObserveField("errorCode", "onConfigFail")
    m.configSetupTask.ObserveField("success", "onConfigReady")
    m.configSetupTask.control = "RUN"
End Function

'To be called when and error happened when making the request, could be the internet.
Function onConfigFail()
    'Show the error dialog.
    m.errorDialog.visible = True
    m.errorDialog.ObserveField("buttonSelected", "onErrorDialogSelected")
    m.errorDialog.ObserveField("wasClosed", "onErrorDialogClosed")
    showDialog(m.errorDialog)
End Function

'To be called when the channels feed was fetched'
Function onConfigReady()
    if m.top.launchArgs <> invalid and m.top.launchArgs.DoesExist("contentId")
        m.homeUI.callFunc("updateContent", m.global.state.channels, m.top.launchArgs.contentId)
    else
        m.homeUI.callFunc("updateContent", m.global.state.channels)
    end if
End Function

'Displays the episode details screen'
'@public'
Function showWatchScreen()
    m.homeUI.callFunc("setFocus")
    m.homeUI.visible = True
End Function

' Public
'Shows given Dialog'
Function showDialog(dialog as dynamic)
    m.top.dialog = dialog
End Function

'Public'
'@param: dialog - Dialog to be closed'
Function closeDialog(dialogToClose as object)
    dialogToClose.close = True
    dialogToClose.unobserveField("buttonSelected")
    dialogToClose.unobserveField("wasClosed")
End Function

'Fired when button selected in error dialog'
Function onErrorDialogSelected()
    'Run again the config
    startConfigFetch()
    closeDialog(m.errorDialog)
End Function

'Fired when error dialog has been closed'
Function onErrorDialogClosed()
    'Close the app
    m.global.equitTracker = True
End Function

'Public'
function hideLoadingScreen()
    m.loadingScreen.visible = false
end function

'Public'
function showLoadingScreen()
    m.loadingScreen.visible = true
end function

'Focus the navigation bar'
Function showMenu()

    m.homeUI.visible = false
    ' m.searchUI.visible = true
    m.searchUI.callFunc("setFocus", true)
End Function

'Focus the watchScreen'
Function unfocusMenu(params as object)
    m.homeUI.callFunc("setFocus")
End Function

function onFocusScreen()
    m.currentViewIndex = m.menu.selectedIndex
    focusCurrentView()
end function

function focusCurrentView()
    m.views[m.currentViewIndex].callFunc("setFocus")
end function
