'Set up config when app loads'
Sub init()
    m.top.functionName = "fetchSavedTimes"
    'Channels Feed Task'
    m.channelsFeedTask = CreateObject("roSGNode", "BaseObjectFeedTask")
    m.channelsFeedTask.feedName = "Channels"

    'Channels Feed Task'
    m.configFeedTask = CreateObject("roSGNode", "BaseObjectFeedTask")
    m.configFeedTask.feedName = "Config"

    m.registryTask = createObject("roSGNode", "RegistryTask")
End Sub

function fetchSavedTimes()
    m.registryTask.method = "GET"
    m.registryTask.key = ""
    m.registryTask.observeField("success", "onSavedTimesFetched")
    m.registryTask.control = "RUN"
end function

function onSavedTimesFetched()
    if m.registryTask.success
        newState = m.global.state
        newState.addReplace("savedItems", m.registryTask.values)
        m.global.addReplace("state", newState)
    end if
    ' Continue the flow
    fetchConfig()
end function

Function fetchConfig()
    ' Save the key_tape for later use
    info = createObject("roAppInfo")

    configURL = info.getValue("config_file")

    newState = m.global.state
    newState.addReplace("baseEndpoint", configURL)
    m.global.addReplace("state", newState)

    m.configFeedTask.fetchURL = configURL
    m.configFeedTask.ObserveField("feedResponseObject", "onConfigFetched")
    m.configFeedTask.ObserveField("statusCode", "onConfigFailedFetch")
    'Run task, gather feed data'
    m.configFeedTask.control = "RUN"
End Function

function onConfigFetched()
    unobserveTask(m.configFeedTask)
    ' store key needed for the requests
    newState = m.global.state
    if m.configFeedTask.feedResponseObject.DoesExist("apiToken")
        newState.addReplace("apiToken", m.configFeedTask.feedResponseObject.apiToken)
        m.global.addReplace("state", newState)
        channelsFeed = newState.baseEndpoint + APP_CONSTANTS().INTERFACE.getAll
        fetchChannels(channelsFeed)
    else
        ' @TODO: use custom error notify parent and manage a refresh
        m.top.errorCode = "404"
    end if
end function

function onConfigFailedFetch()
    unobserveTask(m.configFeedTask)
    m.top.errorCode = m.configFeedTask.statusCode
end function

Function fetchChannels(url as string)
    m.channelsFeedTask.authHeader = m.global.state.apiToken
    m.channelsFeedTask.fetchURL = url
    m.channelsFeedTask.feedType = "RAW"
    m.channelsFeedTask.ObserveField("feedResponseObject", "onChannelsFetched")
    m.channelsFeedTask.ObserveField("statusCode", "onChannelsFailedFetch")
    'Run task, gather feed data'
    m.channelsFeedTask.control = "RUN"
End Function

'Called when max mind feed was fetched'
Function onChannelsFetched()
    unobserveTask(m.channelsFeedTask)
    newState = m.global.state
    newState.addReplace("channels", ParseJson(m.channelsFeedTask.feedResponseObject.value))
    m.global.addReplace("state", newState)

    m.top.success = 1
End Function

'If the channels feeds have an error'
Function onChannelsFailedFetch()
    unobserveTask(m.channelsFeedTask)
    m.top.errorCode = m.channelsFeedTask.statusCode
End Function
