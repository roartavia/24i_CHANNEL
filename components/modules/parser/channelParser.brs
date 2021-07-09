sub init()
    m.top.functionName = "setContent"
end sub

function setContent()
    channels = m.top.channels
    if channels <> invalid

        maxCol = 7
        totalRows = channels.count() / maxCol

        content = CreateObject("roSGNode", "ContentNode")
        m.section = invalid
        for i = 0 to channels.count() - 1
            if (i MOD maxCol) = 0 then
                m.section = content.createChild("ContentNode")
            end if
            item = createItem(channels[i])

            if m.top.searchItemId <> invalid and m.top.searchItemId <> "" and item.id = m.top.searchItemId
                m.top.searchedResultsPos = [int(i / maxCol), (i MOD maxCol)]
            end if
            m.section.appendChild(item)
        end for

        m.top.content = content
    else
        ' Notify error
        m.top.errorCode = 101
    end if
end function

function createItem(media As object) as dynamic
    ' Create the node
    item = CreateObject("roSGNode", "VideoTileContent")
    ' @TODO: check the item has those values before setting them
    item.title = media.title
    ' @TODO this is not set - adding test content
    ' item.description = media.description
    ' item.year = media.year
    item.description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris risus orci, placerat id imperdiet id, consectetur eu odio. Sed ultrices purus et ultricies commodo. Curabitur a ex ac sapien finibus ultricies"
    item.year = "2011"
    item.image = getImageURL(media.id)
    item.contentType = media.type
    item.id = media.id

    if media.type = "movie" then item.streamURL = getStreamURL(media.id)
    return item
end function

' @TODO: search how to use what the poster endpoint returns
function getImageURL(id as string, isTile = false as boolean) as string
    state = m.global.state
    baseEndpoint = state.baseEndpoint

    finalImageUri = baseEndpoint + APP_CONSTANTS().INTERFACE.getAssetInfo
    finalImageUri = finalImageUri.Replace("{id}", id)
    finalImageUri = finalImageUri.Replace("<width>", "200")
    finalImageUri = finalImageUri.Replace("<height>", "300")

    return finalImageUri
end function

function getStreamURL(id as string) as string
    state = m.global.state
    baseEndpoint = state.baseEndpoint
    api = APP_CONSTANTS().INTERFACE.getStream.Replace("{id}", id)
    api = api.Replace("{drmValue}", "true")
    return baseEndpoint + api
end function
