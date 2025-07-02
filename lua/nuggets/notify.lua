local Fidget = require("fidget")

local M = {}

---@param msg string
function M.debug(msg)
  print(msg)
end

---@param msg string
function M.notify(msg)
  Fidget.notify(msg, vim.log.levels.INFO)
end

---@param msg string
function M.notify_error(msg)
  Fidget.notify(msg, vim.log.levels.ERROR)
end

---@param message string
function M.create_progress_handle(message)
  local progress = require("fidget.progress")
  local handle = progress.handle.create({
    title = "Azuredo",
    message = "",
    lsp_client = { name = message or "Calling DevOps" },
    percentage = 0,
  })
  return handle
end

function M.progress_report(handle, message, percentage)
  handle:report({
    title = "Azuredo",
    message = message,
    percentage = percentage,
  })
end

function M.progress_finish(handle)
  handle:finish()
end

return M
