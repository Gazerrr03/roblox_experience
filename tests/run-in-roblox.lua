return function()
    local ServerScriptService = game:GetService('ServerScriptService')
    local TestSuite = require(ServerScriptService:WaitForChild('TestSuite'))

    print('[INFO] Running Roblox experience logic tests via run-in-roblox')

    local success, failures = TestSuite.run()
    if not success then
        error(
            string.format('Roblox experience logic tests failed with %d failure(s)', #failures),
            0
        )
    end
end
