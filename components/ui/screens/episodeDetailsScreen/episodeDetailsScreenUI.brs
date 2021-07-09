Sub init()
    m.tileImage = m.top.findNode("tileImage")
    m.titleLabel = m.top.findNode("titleLabel")
    m.decriptionLabel = m.top.findNode("decriptionLabel")
    m.playButton = m.top.findNode("playButton")
    m.playButton.ObserveField("buttonSelected", "onPlaySelected")

    'Dialog Error
    m.notAvailableDialog = m.top.findNode("notAvailableDialog")
    m.notAvailableDialog.buttons = ["OK"]
End Sub

function onPlaySelected()
    ' Ask if is a movie to be sure
    if m.top.item.contentType = "movie"
        requestStream(m.top.item.streamURL)
    end if
end function

function setFocus(isFocus as boolean)
    if isFocus
        if m.top.item <> invalid
            setContent(m.top.item)
        end if
        m.top.visible = true
    end if
end function

function setContent(item)
    m.titleLabel.text = item.title
    m.decriptionLabel.text = item.description
    ' Set the URL of the Image
    state = m.global.state

    httpAgent = m.tileImage.getHttpAgent()
    httpAgent.AddHeader("X-API-TOKEN", state.apiToken)
    finalImageUri = state.baseEndpoint + APP_CONSTANTS().INTERFACE.getAssetInfo
    finalImageUri = finalImageUri.Replace("{id}", item.id)
    finalImageUri = finalImageUri.Replace("<width>", "500")
    finalImageUri = finalImageUri.Replace("<height>", "750")
    m.tileImage.uri = finalImageUri

    if item.contentType = "movie"
        m.playButton.visible = true
        m.playButton.setFocus(true)
    else
        m.playButton.visible = false
        m.top.setFocus(true)
    end if
end function

function requestStream(url as string)
    state = m.global.state
    m.streamTask = createObject("RoSGNode", "BaseObjectFeedTask")
    m.streamTask.feedName = "Stream Request"
    m.streamTask.fetchURL = url
    m.streamTask.authHeader = state.apiToken
    m.streamTask.ObserveField("feedResponseObject", "onStreamTaskFetched")
    m.streamTask.ObserveField("statusCode", "onStreamTaskError")
    ' @TODO: show loading
    m.streamTask.control = "RUN"
end function

function onStreamTaskFetched()
    unobserveTask(m.streamTask)
    if m.streamTask.feedResponseObject.DoesExist("url")
        streamObj = m.streamTask.feedResponseObject
        ' ------------------
        ' ------------------
        ' @IMPORTANT
        ' @TODO: the feed isn't returning a valid drm secure stream, so for drm testing
        ' ill use the one in the doc:
        ' ------------------
        ' ------------------
        streamObj.addReplace("url", "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd")

        playStream(streamObj)
        m.streamTask = invalid
    else
        onStreamTaskError()
    end if
end function

function onStreamTaskError()
    unobserveTask(m.streamTask)
    ' @TODO - notify error
end function

'Plays the stream'
function playStream(streamObj)
    progressMade = m.global.state.savedItems
    m.video = createObject("RoSGNode", "Video")
    m.video.ObserveField("state", "onPlayerStateChanged")
    m.prevHeartBeat = 0
    m.video.ObserveField("position", "onPositionChanged")

    ' Set comtent
    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.title = "Testing Video"

    videoContent.url = streamObj.url
    videoContent.streamformat = streamObj.type
    drmParams = {
        "keySystem": streamObj.drmType,
        "licenseServerURL": streamObj.drmUrl
    }
    videoContent.drmParams = drmParams
    ' Set node
    m.video.content = videoContent
    ' Check if is a played video
    if progressMade.DoesExist(m.top.item.id)
        m.video.seek = progressMade[m.top.item.id].toInt()
    end if
    m.video.visible = true
    m.video.enableUI = true
    m.video.mute = false
    m.top.appendChild(m.video)
    m.video.setFocus(true)
    m.video.control = "play"
End function

function onPositionChanged()
    if m.video.position <> 0 and (m.video.position MOD 20) = 0
        if int(m.video.position) <> m.prevHeartBeat
            m.prevHeartBeat = int(m.video.position)
            ' send heart beat interval 20 seconds
            state = m.global.state
            url = state.baseEndpoint + APP_CONSTANTS().INTERFACE.postHeartbeat

            heartBeat = createObject("RoSGNode", "BaseObjectFeedTask")
            heartBeat.feedName = "Heartbeat Request"
            heartBeat.fetchURL = url
            heartBeat.authHeader = state.apiToken
            heartBeat.method = "POST"
            heartBeat.postData = {
                "id": m.top.item.id, "progress": m.video.position
            }
            heartBeat.ObserveField("feedResponseObject", "onHeartBeatSent")
            heartBeat.ObserveField("statusCode", "onHeartBeatSent")
            ' @TODO: show loading
            heartBeat.control = "RUN"
        end if
    end if
end function

function onHeartBeatSent(msg)
    ? msg.getData()
end function

' @TODO: A better way to do it is save on interval and not on close
function saveProgress(id, time = "" as string)

    state = m.global.state
    prevItems = state.savedItems
    if time = ""
        prevItems.delete(id)
    else
        prevItems.addReplace(id, time)
    end if
    state.addReplace("savedItems", prevItems)
    m.global.state = state
    ' Now save it to the registry
    registryTask = createObject("roSGNode", "RegistryTask")
    registryTask.method = "SET"

    registryTask.values = prevItems
    registryTask.observeField("success", "onProgressSaved")
    registryTask.control = "run"
end function

function onProgressSaved()
    ? "Item progress updated in memory"
end function

'Stops the video'
function stopVideo(isSaveNeeded as boolean)
    if isSaveNeeded
        saveProgress(m.top.item.id, m.video.position.toStr())
    else
        saveProgress(m.top.item.id)
    end if
    m.video.content = Invalid
    m.video.control = "stop"
    m.video.visible = false
    m.video.unobserveField("onPlayerStateChanged")
    m.top.removeChild(m.video)
    m.video = invalid
    m.playButton.setFocus(true)
End function

'Controls the states in the video
function onPlayerStateChanged()
    If m.video.state = "error"
        m.notAvailableDialog.visible = true
        m.notAvailableDialog.ObserveField("buttonSelected", "onErrorDialogClosed")
        m.notAvailableDialog.ObserveField("wasClosed", "onErrorDialogClosed")
    Else If m.video.state = "finished"
        ' remove item from registry
        stopVideo(false)
    End If
End function

' Close the error dialog
function onErrorDialogClosed()
    m.notAvailableDialog.unObserveField("buttonSelected")
    m.notAvailableDialog.unObserveField("wasClosed")
    closeDialog(m.notAvailableDialog)
    stopVideo(false)
End function

'Util Close Dialog'
'@param: dialog - Dialog to be closed'
function closeDialog(dialogToClose as object)
    dialogToClose.unobserveField("buttonSelected")
    dialogToClose.unobserveField("wasClosed")
    dialogToClose.close = true
    dialogToClose.visible = false
    m.top.getScene().callFunc("closeDialog", {})
End function

'Manage all the key events.
function onKeyEvent(key as string, press as boolean) as boolean
    if press
        if key = "back" and m.video <> invalid
            stopVideo(true)
            return true
        else if key = "back"
            m.top.requestClose = true
            return true
        else if (key = "left" or key = "right") and m.video = invalid
            ' This can be manage by the parent onKeyEvent, instead of using the action
            m.top.action = key
            return true
        end if
    end if
    ' @TODO: for now block all key events
    return true
end function
