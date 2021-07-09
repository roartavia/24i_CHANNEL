Sub init()
    m.input = m.top.findNode("input")
    m.labelResults = m.top.findNode("labelResults")
    m.searchButton = m.top.findNode("searchButton")
    m.results = m.top.findNode("results")
    m.results.observeField("rowItemSelected", "onVideoTileSelected")

    m.filters = m.top.findNode("filters")
    m.filtersValues = ["movie", "series"]

    m.progressDialog = createObject("roSGNode", "StandardProgressDialog")
    m.progressDialog.title = "Searching"
    m.progressDialog.message = "Almost there!"

    m.keyboard = createObject("roSGNode", "StandardKeyboardDialog")
    m.keyboard.title = "Enter Value"
    m.keyboard.buttons = ["OK"]
    m.keyboard.observeField("buttonSelected", "setText")
    m.keyboard.observeField("wasClosed", "setText")
    m.searchButton.observeField("buttonSelected", "onSearchSelected")

    m.lastItemFocus = m.input
End Sub

function setFocus(isFocus as boolean)
    m.lastItemFocus.setFocus(isFocus)
    updateInputStyle()
    m.top.visible = isFocus
end function

function updateInputStyle()
    if m.input.hasFocus() or m.input.isInFocusChain()
        m.input.backgroundUri = "pkg:/images/search/focus.9.png"
        m.input.textColor = "#000000"
    else
        m.input.backgroundUri = "pkg:/images/search/unFocus.9.png"
        m.input.textColor = "#ffffff"
    end if
end function

'Called when a video tile is selected'
Function onVideoTileSelected()
    rowItemSelected = m.results.rowItemSelected
    row = rowItemSelected[0]
    col = rowItemSelected[1]

    m.itemSelected = m.results.content.getChild(row).getChild(col)
    ' this is more a modal than a view, because it would walk the rowlist
    m.detailView = CreateObject("roSGNode", "EpisodeDetailsScreenUI")
    m.detailView.item = m.itemSelected
    m.detailView.ObserveField("requestClose", "onDetailRequestClose")
    m.detailView.ObserveField("action", "onDetailActionRequest")
    m.top.appendChild(m.detailView)
    m.detailView.callFunc("setFocus", true)
End Function

function onDetailActionRequest()
    action = m.detailView.action
    ' close the windows and select the next item in the rowlist
    onDetailRequestClose()
    lastItemSelected = m.results.rowItemSelected
    row = lastItemSelected[0]
    col = lastItemSelected[1]
    if action = "right"
        maxX = m.results.content.getChild(row).getChildCount() - 1
        if col + 1 > maxX
            maxY = m.results.content.getChildCount() - 1
            if row + 1 > maxY
            else
                m.results.jumpToRowItem = [row + 1, 0]
                m.results.rowItemSelected = [row + 1, 0]

            end if
        else
            m.results.jumpToRowItem = [row, col + 1]
            m.results.rowItemSelected = [row, col + 1]
        end if
    else
        if col - 1 < 0
            if row - 1 < 0
            else
                maxY = m.results.content.getChild(row - 1).getChildCount() - 1
                m.results.jumpToRowItem = [row - 1, maxY]
                m.results.rowItemSelected = [row - 1, maxY]
            end if
        else
            m.results.jumpToRowItem = [row, col - 1]
            m.results.rowItemSelected = [row, col - 1]
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
    m.results.setFocus(true)
end function

function onSearchSelected()
    ' clean the rowlist
    m.results.content = invalid
    ' Prepare the feed
    values = []
    checkedStates = m.filters.checkedState
    for i = 0 to checkedStates.count() - 1
        if checkedStates[i] then values.push(m.filtersValues[i])
    end for
    ' both filters == none filters
    state = m.global.state
    url = APP_CONSTANTS().INTERFACE.getSearch.replace("{searched_string}", m.input.text)
    if not (values.count() = m.filtersValues.count() or values.count() = 0)
        url = url + "&filter=" + values[0]
    end if
    channelsFeed = state.baseEndpoint + url

    if m.channelsFeedTask = invalid then m.channelsFeedTask = CreateObject("roSGNode", "BaseObjectFeedTask")
    m.channelsFeedTask.feedName = "Channels"
    m.channelsFeedTask.authHeader = state.apiToken
    m.channelsFeedTask.fetchURL = channelsFeed
    m.channelsFeedTask.feedType = "RAW"
    m.channelsFeedTask.ObserveField("feedResponseObject", "onChannelsFetched")
    m.channelsFeedTask.ObserveField("statusCode", "onChannelsFailedFetch")

    startLoading()
    m.channelsFeedTask.control = "RUN"
end function

function startLoading()
    if m.top.getScene().dialog = Invalid or not m.top.getScene().dialog.isSameNode(m.progressDialog)
        m.top.getScene().dialog = m.progressDialog
        return true
    else
        return false
    end if
end function

function endLoading()
    m.progressDialog.close = true
end function

function onChannelsFetched()
    unobserveTask(m.channelsFeedTask)
    results = ParseJson(m.channelsFeedTask.feedResponseObject.value)
    m.channelsFeedTask = invalid

    m.labelResults.text = "Results: " + results.count().toStr()
    if results.count() > 0
        ' @TODO:
        ' Parse the content
        if m.channelParser = invalid then m.channelParser = CreateObject("roSGNode", "ChannelParser")
        m.channelParser.ObserveField("content", "onContentReady")
        m.channelParser.ObserveField("errorCode", "onContentError")
        m.channelParser.channels = results
        m.channelParser.control = "RUN"
    else
        endLoading()
    end if
end function

function onContentReady()
    m.channelParser.unObserveField("content")
    m.channelParser.unObserveField("errorCode")
    ' Now set the content
    content = m.channelParser.content

    m.results.content = content
    m.results.numRows = content.getChildCount()
    m.results.setFocus(True)
    endLoading()
end function

function onContentError()
    ' TODO
end function

function onChannelsFailedFetch()
    unobserveTask(m.channelsFeedTask)
    m.channelsFeedTask = invalid
    m.labelResults.text = "Results: 0"
    endLoading()
end function

function showKeyboard() as boolean
    if m.top.getScene().dialog = Invalid or not m.top.getScene().dialog.isSameNode(m.keyboard)
        m.keyboard.textEditBox.text = m.input.text
        m.keyboard.textEditBox.cursorPosition = m.input.cursorPosition
        m.top.getScene().dialog = m.keyboard
        return true
    else
        return false
    end if
end function

function setText()
    m.keyboard.close = true
    m.input.cursorPosition = m.keyboard.textEditBox.cursorPosition
    m.input.text = m.keyboard.textEditBox.text
end function

function cleanView()
    m.input.text = ""
    m.input.setFocus(true)
    m.lastItemFocus = m.input
    m.results.content = invalid
    m.labelResults.text = "Results:"
    m.top.visible = false
end function

'Handle key events'
Function onKeyEvent(key As string, press As boolean) As boolean
    handled = false
    if press
        if key = "back"
            cleanView()
            m.top.getScene().callFunc("showWatchScreen")
            handled = true
        else if key = "OK" and m.input.hasFocus()
            ' If needed
            handled = showKeyboard()
        else
            items = [
                [m.input, m.filters]
                m.searchButton
            ]
            if m.results.content <> invalid and m.results.content.getchildcount() > 0 then items.push(m.results)
            toFocus = handleFocusWithItems(items, key)

            if toFocus <> Invalid
                toFocus.setFocus(true)
                m.lastItemFocus = toFocus
                updateInputStyle()
                handled = true
            end if
        end if
    end if
    ' @TODO: for now block all key events
    return true
End Function
