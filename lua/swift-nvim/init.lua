local M = {}

function M.say_hi()
    print("Hi from my plugin")
end

function M.package_describe()
    local stdout = vim.fn.system("swift package describe --type json")
    local json = vim.json.decode(stdout)
    for _, target in ipairs(json.targets) do
        print(target.name, target.type)
    end
    return json
end

function M.test_list()
    local stdout = vim.fn.system("swift test list")
    local lines = {}
    for m in stdout:gmatch("[^\r\n]+") do
        table.insert(lines, m)
    end
    local build_complete = false
    local tests = {}
    for _, line in ipairs(lines) do
        if string.find(line, "Build complete!") then
            build_complete = true
        end
        if build_complete then
            if not string.find(line, "Build complete!") then
                print("test >", line)
                table.insert(tests, line)
            end
        end
    end
    return tests
end

vim.api.nvim_create_user_command("SwiftPackageDescribe", function()
    local _ = M.package_describe()
    local _ = M.test_list()
end, {})

vim.api.nvim_create_user_command("SwiftTest", function(opts)
    local _ = M.package_describe()
    local _ = M.test_list()

    local test_name = opts.args
    print("test_name: ", test_name)
    local test_output = vim.fn.system("swift test --filter " .. test_name)
    print("test_output: ", test_output)
end, {
    nargs = 1,
    complete = "file", -- enable filename auto completions when hit tab
    desc = "Testing a file"
})

return M
