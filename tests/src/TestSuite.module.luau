local TestSuite = {}

local function getTestModules()
    return script.Parent:WaitForChild('Shared'):GetChildren()
end

function TestSuite.run()
    local failures = {}
    local testModules = getTestModules()

    for _, moduleScript in ipairs(testModules) do
        local ok, message = pcall(function()
            require(moduleScript)()
        end)

        if not ok then
            table.insert(
                failures,
                string.format('%s failed: %s', moduleScript.Name, tostring(message))
            )
        else
            print(string.format('[PASS] %s', moduleScript.Name))
        end
    end

    if #failures > 0 then
        warn('[FAIL] Roblox experience logic tests')
        for _, failure in ipairs(failures) do
            warn(failure)
        end

        return false, failures
    end

    print(string.format('[PASS] All Roblox experience logic tests passed (%d tests)', #testModules))
    return true, {}
end

return TestSuite
