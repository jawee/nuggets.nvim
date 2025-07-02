local M = {}

---@param args table
---@param on_stdout fun(data: table<string>)
---@param on_exit fun(exit_code: integer)
function M.run_async_command(args, on_stdout, on_exit)
  local job_id = vim.fn.jobstart(vim.list_extend({ "sh", "-c" }, args), {
    rpc = false,
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if on_stdout then
        on_stdout(data)
      end
    end,
    on_exit = function(_, exit_code, _)
      if on_exit then
        on_exit(exit_code)
      end
    end,
  })

  if job_id == 0 then
    vim.notify("Failed to start job: " .. args, vim.log.levels.ERROR)
  end
end

return M
