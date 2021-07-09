' Shared functions and constants
function APP_CONSTANTS()
    return {
        "RESPONSE": {
            "NOT_FOUND": 404,
            "SUCCESS": 200
        },
        "INTERFACE": {
            ' Call to ger all vod content. Filter can have one item from optionals. - GET [?filter=movie|series|season|episode]",
            "getAll": "/vod",
            ' Call to get specific vod content with {id}. If full set to true for seasons and series returns whole tree (series < seasons < episodes).
            "getSerie": "/vod/{id}[?full=true|false]",
            ' Call to get all children for asset with {id} – seasons for series or episodes for season
            "getChildrenSeries": "/vod/{id}/children",
            ' Call to get stream data for asset with {id}, If drm value is true a drm protected stream data is returned.
            ' [?drm=true|false]
            "getStream": "/vod/{id}/stream?drm={drmValue}",
            ' Search call returning assets with title containing <searched_string>. With optional filter specific asset types can be filtered. [&filter=movie|series|season|episode]
            "getSearch": "/vod/search?s={searched_string}",
            ' Call to get image for asset with {id}, Optional width / height param accepted. If not present their default value 100px is used.
            "getAssetInfo": "/vod/{id}/poster?w=<width>&h=<height>",
            ' Call for sending heartbeat object {id: <asset_id>, progress: <long integer>}. Same is returned. - POST
            "postHeartbeat": "/vod/heartbeat"
        }
    }
end function

function console_log(lines)
    #if debug
        for each line in lines
            print line
        end for
    #end if
end function

' Returns true if the provided object is an array.
' This function will return true for objects of the type roArray, roByteArray, roList, and roXMLList
function isArray(x) as boolean
    return getInterface(x, "ifArray") <> Invalid and getInterface(x, "ifArraySet") <> Invalid
end function

' Returns true if the provided object is an associative array.
' This function will return false if the provided object is a roSGNode.
function isAssociativeArray(x) as boolean
    return getInterface(x, "ifAssociativeArray") <> Invalid and not isNode(x)
end function

' Returns true if the object is a roku scenegraph node
function isNode(obj as object) as boolean
    return getInterface(obj, "ifSGNodeDict") <> Invalid
end function

function handleFocusWithItems(grid as object, key as string) as dynamic
    currentRowIndex = -1
    currentColIndex = -1
    ' Find current index of focused item
    for i = 0 to grid.count() - 1
        row = grid[i]
        if isArray(row)
            for j = 0 to row.count() - 1
                col = row[j]
                if isNode(col) and col.isInFocusChain()
                    currentRowIndex = i 'eslint-disable-line roku/no-uninitialized-variables
                    currentColIndex = j
                    exit for
                end if
            end for

        else if isNode(row) and row.isInFocusChain()
            currentRowIndex = i
            currentColIndex = 0
        end if

        if currentRowIndex >= 0
            exit for
        end if
    end for

    if currentRowIndex = -1
        return Invalid
    else
        ' Figure out the next index
        nextRowIndex = 0
        nextColIndex = 0
        ' Go up one row
        if key = "up"
            nextRowIndex = currentRowIndex - 1
            nextColIndex = currentColIndex
            ' Go left one column
        else if key = "left"
            nextRowIndex = currentRowIndex
            nextColIndex = currentColIndex - 1
            ' Go right one column
        else if key = "right"
            nextRowIndex = currentRowIndex
            nextColIndex = currentColIndex + 1
            ' Go down one row
        else if key = "down"
            nextRowIndex = currentRowIndex + 1
            nextColIndex = currentColIndex
            ' We don't handle other key presses
        else
            return Invalid
        end if

        ' Check row index
        if nextRowIndex < 0 or nextRowIndex >= grid.count()
            return Invalid
        end if

        ' Figure out column size
        nextRow = grid[nextRowIndex]
        nextRowColumns = 1
        if isArray(nextRow)
            nextRowColumns = nextRow.count()
        end if

        ' Change rows
        if nextRowIndex <> currentRowIndex
            if nextRowColumns = 1
                if isArray(nextRow)
                    return nextRow[0]
                else
                    return nextRow
                end if
            else
                if nextColIndex >= nextRowColumns
                    nextColIndex = nextRowColumns - 1
                end if
                return nextRow[nextColIndex]
            end if
            ' Change columns
        else
            if nextColIndex < 0 or nextColIndex >= nextRowColumns
                return Invalid
            else
                return nextRow[nextColIndex]
            end if
        end if
    end if
end function

'Unobserve helper for config task'
'@param: task   - task node to unobserve'
Function unobserveTask(task as object)
    fields = ["feedResponseObject", "statusCode"]
    For Each field in fields
        task.unobserveField(field)
    End For
End Function


