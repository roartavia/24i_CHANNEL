sub init()
    m.top.functionName = "performRegistryTask"
end sub

function performRegistryTask()
    section = createObject("roRegistrySection", m.top.section)

    values = m.top.values
    key = m.top.key
    method = uCase(m.top.method)

    if method = "GET"
        if key <> Invalid and key <> ""
            if section.exists(key)
                value = section.read(key)
                vals = {}
                vals.addReplace(key, value)
                m.top.values = vals
            else
                vals = {}
                vals.addReplace(key, Invalid)
                m.top.values = vals
            end if
        else
            keys = section.getkeyList()
            m.top.values = section.readMulti(keys)
        end if
        m.top.success = true
    else if method = "SET"
        values = m.top.values
        success = section.writeMulti(values)
        flushSuccess = false
        if success
            flushSuccess = section.flush()
        end if
        m.top.success = success and flushSuccess
    else if method = "DELETE"
        if key <> Invalid and key <> ""
            success = false
            if section.exists(key)
                success = section.delete(key)
            end if
            m.top.success = success and section.flush()
        else
            registry = createObject("roRegistry")
            success = registry.delete(m.top.section)
            m.top.success = success and registry.flush()
        end if
    end if
end function
