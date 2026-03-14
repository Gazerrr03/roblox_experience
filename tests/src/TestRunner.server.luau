local TestSuite = require(script.Parent:WaitForChild('TestSuite'))

local success = TestSuite.run()

if not success then
    error('Roblox experience logic tests failed', 0)
end
