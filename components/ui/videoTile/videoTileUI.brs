Sub init()
    'Channel Group'
    m.channelGroup = m.top.findNode("channelGroup")
    'Channel tile image'
    m.tileImage = m.top.findNode("tileImage")
    m.titleLabel = m.top.findNode("titleLabel")


End Sub


'Default Scenegraph function to show content'
Function showcontent()
    itemContent = m.top.itemContent
    state = m.global.state
    m.channelGroup.visible = True

    httpAgent = m.tileImage.getHttpAgent()
    httpAgent.AddHeader("X-API-TOKEN", state.apiToken)
    m.tileImage.uri = itemContent.image
    m.titleLabel.text = itemContent.title
End Function
