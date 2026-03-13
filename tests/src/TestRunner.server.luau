local tests = script.Parent:WaitForChild('Shared'):GetChildren()

local failures = {}

for _, moduleScript in ipairs(tests) do
    local ok, message = pcall(function()
        require(moduleScript)()
    end)

    if not ok then
        table.insert(failures, string.format('%s failed: %s', moduleScript.Name, tostring(message)))
    else
        print(string.format('[PASS] %s', moduleScript.Name))
    end
end

if #failures > 0 then
    warn('[FAIL] Roblox experience logic tests')
    for _, failure in ipairs(failures) do
        warn(failure)
    end
else
    print('[PASS] All Roblox experience logic tests passed')
end

