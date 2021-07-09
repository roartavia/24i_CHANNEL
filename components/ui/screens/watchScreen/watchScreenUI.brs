Sub init()
    'Watch Rowlist'
    m.videosRowList = m.top.findNode("videosRowList")
    'Observe item selected from video rowlist'
    m.videosRowList.ObserveField("rowItemSelected", "onVideoTileSelected")
    ' Parser
    m.channelParser = CreateObject("roSGNode", "ChannelParser")

    ' m.selectionForDeepLinking = ""
End Sub

'Set data for the watch page'
Function updateContent(channels as dynamic, deepLikingId = "" as string)
    m.channelParser.ObserveField("content", "onContentReady")
    m.channelParser.ObserveField("errorCode", "onContentError")
    ' Pass to the parser the id, so you dont need to iterate again the rowlist
    m.channelParser.searchItemId = deepLikingId
    m.channelParser.channels = channels
    m.channelParser.control = "RUN"
End Function

function onContentError()
    ' @TODO: Notify the error to the mainScene, this is fatal.
end function

function onContentReady()
    m.channelParser.unObserveField("content")
    m.channelParser.unObserveField("errorCode")

    ' Now set the content
    content = m.channelParser.content

    m.videosRowList.content = content
    m.videosRowList.numRows = content.getChildCount()
    m.videosRowList.setFocus(True)

    m.top.visible = true

    if m.channelParser.searchedResultsPos <> invalid and m.channelParser.searchedResultsPos.count() > 0
        m.videosRowList.jumpToRowItem = m.channelParser.searchedResultsPos
        m.videosRowList.rowItemSelected = m.channelParser.searchedResultsPos
    end if

    m.top.getScene().callFunc("hideLoadingScreen")
end function

'Called when a video tile is selected'
Function onVideoTileSelected()
    rowItemSelected = m.videosRowList.rowItemSelected
    row = rowItemSelected[0]
    col = rowItemSelected[1]
    ' @TODO
    ' you would probably need to pass all the list for the
    ' or you can just pass the position and in the view check the state the field:
    ' currentList or something
    m.itemSelected = m.videosRowList.content.getChild(row).getChild(col)

    ' this is more a modal than a view, because it would walk the rowlist
    m.detailView = CreateObject("roSGNode", "EpisodeDetailsScreenUI")

    m.detailView.item = m.itemSelected
    m.detailView.ObserveField("requestClose", "onDetailRequestClose")
    m.detailView.ObserveField("action", "onDetailActionRequest")
    m.top.appendChild(m.detailView)
    m.detailView.callFunc("setFocus", true)

    ' m.top.getScene().callFunc("showEpisodeDetailsScreen", sectionSelected)
End Function

function onDetailActionRequest()
    action = m.detailView.action
    ' close the windows and select the next item in the rowlist
    onDetailRequestClose()
    lastItemSelected = m.videosRowList.rowItemSelected
    row = lastItemSelected[0]
    col = lastItemSelected[1]
    if action = "right"
        maxX = m.videosRowList.content.getChild(row).getChildCount() - 1
        if col + 1 > maxX
            maxY = m.videosRowList.content.getChildCount() - 1
            if row + 1 > maxY
            else
                m.videosRowList.jumpToRowItem = [row + 1, 0]
                m.videosRowList.rowItemSelected = [row + 1, 0]

            end if
        else
            m.videosRowList.jumpToRowItem = [row, col + 1]
            m.videosRowList.rowItemSelected = [row, col + 1]
        end if
    else
        if col - 1 < 0
            if row - 1 < 0
            else
                maxY = m.videosRowList.content.getChild(row - 1).getChildCount() - 1
                m.videosRowList.jumpToRowItem = [row - 1, maxY]
                m.videosRowList.rowItemSelected = [row - 1, maxY]
            end if
        else
            m.videosRowList.jumpToRowItem = [row, col - 1]
            m.videosRowList.rowItemSelected = [row, col - 1]
        end if
    end if
end function

function onDetailRequestClose()
    m.detailView.unObserveField("requestClose")
    m.detailView.unObserveField("action")
    m.detailView.visible = false
    m.top.removeChild(m.detailView)

    m.detailView = invalid
    ' return focus to rowlist
    m.videosRowList.setFocus(true)
end function

' Focus this screen
Function setFocus()
    m.videosRowList.setFocus(True)
End Function

'Handle key events'
function onKeyEvent(key As string, press As boolean) As boolean
    if press and key = "options" and m.detailView = invalid
        m.top.getScene().callFunc("showMenu")
        return true
    end if
    return false
end function
