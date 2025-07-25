local M = {}

M.list_outdated = require("nuggets.commands.list_outdated").list_outdated
M.add_nuget = require("nuggets.commands.add_package").add_package
M.update_all = require("nuggets.commands.update_all").update_all

return M
