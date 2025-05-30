local M = {}

M.targets = {}
M.tests = {}

function M.say_hi()
    print("Hi from my plugin")
end

--- calls the swift package describe cli which gives all the targets
--- tests and files.
function M.package_describe()
    local result = vim.system(
        {"swift", "package", "describe", "--type", "json"},
        { text = true }
    ):wait()
    local json = vim.json.decode(result.stdout)
    local targets = json.targets
    for _, target in ipairs(targets) do
        print("target > ", target.name, " - ", target.type)
    end
    M.targets = targets
end

function M.test_list()
    local result = vim.system(
        {"swift", "test", "list"},
        { text = true }
    ):wait()

    -- spliting stdout into lines
    local lines = vim.split(result.stdout, "\n", { trimempty = true })

    -- construct tests by grepping
    local tests = {}
    for _, line in ipairs(lines) do
        print("test >", line)
        table.insert(tests, line)
    end

    -- set the global list
    M.tests = tests
end

function M.create_popup()
    local buf = vim.api.nvim_create_buf(false, true) -- create new [unlisted, scratch] buffer
    -- local lines = { "Hello from popup!", "Second line" }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.tests)

    local width = 100
    local height = 20
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = "minimal",
        border = "rounded",
    }
    local win = vim.api.nvim_open_win(buf, true, opts)
    -- highlight cursorline
    vim.wo[win].cursorline = true


    print("win_id: ", win)

    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
        callback = function()
            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
            print("select line", line)
            -- vim.api.nvim_win_close(win, true)
            -- local output = vim.fn.system("swift test --filter" .. " " .. line)
            vim.system({"swift", "test", "--filter", line}, {text = true} , function (obj)
                vim.schedule(function ()
                    local _buf = vim.api.nvim_create_buf(true, false)
                    local _lines = vim.split(obj.stdout, "\n")
                    vim.api.nvim_buf_set_lines(_buf, 0, -1, false, _lines)
                    vim.api.nvim_buf_set_name(_buf, line)
                    vim.cmd("tabnew")
                    vim.api.nvim_win_set_buf(0, _buf) -- set to new tab
                end)
            end)
        end,
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "n", "<C-c>", "", {
        callback = function()
            vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true
    })
end

vim.api.nvim_create_user_command("SwiftPackageDescribe", function()
    M.package_describe()
end, {})

vim.api.nvim_create_user_command("SwiftTestList", function()
    M.test_list()
end, {})

vim.api.nvim_create_user_command("SwiftTest", function(opts)
    local test_name = opts.args
    print("test_name: ", test_name)
    local test_output = vim.system(
        {"swift", "test", "--filter", test_name},
        { text = true }
    ):wait()
    print("test_output: ", test_output.stdout)
end, {
    nargs = 1,
    complete = "file", -- enable filename auto completions when hit tab
    desc = "Testing a file"
})

vim.api.nvim_create_user_command("SwiftToggle", function()
    M.test_list()
    M.create_popup()
end, {})


return M
