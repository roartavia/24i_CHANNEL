Sub init()
    m.top.functionName = "retrieveFeed"
    m.port = CreateObject("roMessagePort")
    ' Save device info variable
    m.deviceInfo = CreateObject("roDeviceInfo")
End Sub

' Makes a GET request to given URL
Function retrieveFeed() As dynamic
    ' Check if there is internet connection
    If NOT m.deviceInfo.GetLinkStatus()
        m.top.statusCode = 101
        ' Exit the function, don't attempt to make a request
        return m.top.statusCode
    End If
    request = createObject("roUrlTransfer")
    ' Enable this for custom config files
    request.EnablePeerVerification(false)
    request.SetUrl(m.top.fetchURL)
    request.SetMessagePort(m.port)

    If m.top.authHeader <> "" Then request.AddHeader("X-API-TOKEN", m.top.authHeader)

    console_log(["Making Request to " + m.top.fetchURL])


    if m.top.method = "GET"
        request.asyncGetToString()
    else
        postData = m.top.postData
        postStr = ""
        if postData <> Invalid
            postStr = formatJSON(postData)
        end if
        request.addHeader("Content-Type", "application/json")
        request.asyncPostFromString(postStr)
    end if

    ' request.AsyncGetToString()

    While true
        msg = wait(0, m.port)
        If Type(msg) = "roUrlEvent"
            If msg.GetSourceIdentity() = request.GetIdentity()
                If msg.GetResponseCode() = 200
                    response = msg.GetString()
                    If response.Len() <> 0
                        console_log([m.top.feedName + " Feed Successful"])
                        ' Notify Watchers
                        if ucase(m.top.feedType) = "JSON"
                            setContent(ParseJson(response))
                        else
                            setContent({ value: response })
                        end if
                    Else
                        console_log([m.top.feedName + " Feed Failed - Empty Response"])
                        ' Notify Watchers
                        m.top.statusCode = 102
                    End If
                Else
                    console_log([m.top.feedName + " Feed Failed", msg])
                    ' Notify Watchers
                    m.top.statusCode = 102
                End If
                Exit While
            End If
            Exit While
        End If
    End While
End Function

' This can be reused/overwhite when extends
function setContent(response)
    m.top.feedResponseObject = response
end function
