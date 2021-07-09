Sub init()
    'Custom spinner'
    m.spinner = m.top.findNode("spinner")
    m.spinner.poster.uri = "pkg:/images/loading/spinner.png"
    m.spinner.poster.width = "100"
    m.spinner.poster.height = "100"
    m.spinner.control = "start"
End Sub
