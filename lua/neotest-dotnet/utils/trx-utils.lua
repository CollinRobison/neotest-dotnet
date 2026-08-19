local lib = require("neotest.lib")
local logger = require("neotest.logging")

local M = {}

local function remove_bom(str)
  if string.byte(str, 1) == 239 and string.byte(str, 2) == 187 and string.byte(str, 3) == 191 then
    str = string.sub(str, 4)
  end
  return str
end

M.as_list = function(value)
  if type(value) ~= "table" then
    return {}
  end
  if value._attr then
    return { value }
  end
  return value
end

M.map_outcome = function(outcome)
  return ({
    Passed = "passed",
    Failed = "failed",
    Skipped = "skipped",
    NotExecuted = "skipped",
  })[outcome] or "failed"
end

M.parse_trx = function(output_file)
  logger.info("Parsing trx file: " .. output_file)
  local success, xml = pcall(lib.files.read, output_file)

  if not success then
    logger.error("No test output file found ")
    return {}
  end

  local no_bom_xml = remove_bom(xml)

  local ok, parsed_data = pcall(lib.xml.parse, no_bom_xml)
  if not ok then
    logger.error("Failed to parse test output:", output_file)
    return {}
  end

  return parsed_data
end

return M
