-- Polish typesetting rules that pandoc and Typst do not apply on their own.
--
-- 1. One-letter words (a, i, o, u, w, z) never end a line: the space after
--    them becomes a non-breaking space, as in Polish printed books.
-- 2. A paragraph ending with ":" stays on the same page as the list, table or
--    code it introduces, so "Funkcje:" never ends a page on its own.
-- 3. A table stays on one page, so a page never starts with a leftover row.
--    All tables here are short enough to fit.
-- 4. Two-column tables get a first column wide enough for its longest word,
--    so a long test name like searchWithGenreOnlyUsesDiscoverEndpoint fits.

local nbsp = "\u{00A0}"

local function is_single_letter_word(text)
  -- Also catches a letter after an opening bracket or quote: "(w", "„z".
  return text:match("^[%(\u{201E}\u{201C}\"]?[aiouwzAIOUWZ]$") ~= nil
end

function Inlines(inlines)
  for position = 1, #inlines - 1 do
    local current = inlines[position]
    local next_inline = inlines[position + 1]
    if current.t == "Str" and next_inline.t == "Space" and is_single_letter_word(current.text) then
      inlines[position + 1] = pandoc.Str(nbsp)
    end
  end
  return inlines
end

local introduced_blocks = {
  CodeBlock = true,
  Table = true,
  BulletList = true,
  OrderedList = true,
}

-- Tables with more body rows than this may be split between pages.
local max_rows_kept_together = 20

-- Measured on the PDF: text width 425pt, code in table cells about 5.8pt per
-- character, plus the cell padding.
local text_width_points = 425
local code_character_points = 5.8
local cell_padding_points = 16
local min_first_column_share = 0.25
local max_first_column_share = 0.62
local signature_column_share = 0.5

local function table_row_count(tbl)
  local count = 0
  for _, body in ipairs(tbl.bodies) do
    count = count + #body.body
  end
  return count
end

local function first_column_cells(tbl)
  local cells = {}
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      table.insert(cells, pandoc.utils.stringify(row.cells[1].contents))
    end
  end
  return cells
end

-- Share of the text width for the first column of a two-column table.
local function first_column_share(tbl)
  local longest_word = 0
  for _, text in ipairs(first_column_cells(tbl)) do
    if text:find(" ") then
      -- Function signatures wrap at spaces, half the width is enough.
      return signature_column_share
    end
    longest_word = math.max(longest_word, utf8.len(text) or #text)
  end
  local share = (longest_word * code_character_points + cell_padding_points) / text_width_points
  return math.min(math.max(share, min_first_column_share), max_first_column_share)
end

function Table(tbl)
  if FORMAT ~= "typst" or #tbl.colspecs ~= 2 then
    return nil
  end
  local share = first_column_share(tbl)
  tbl.colspecs = {
    { tbl.colspecs[1][1], share },
    { tbl.colspecs[2][1], 1 - share },
  }
  return tbl
end

local function is_short_table(block)
  return block.t == "Table" and table_row_count(block) <= max_rows_kept_together
end

local function ends_with_colon(block)
  if block.t ~= "Para" and block.t ~= "Plain" then
    return false
  end
  local text = pandoc.utils.stringify(block)
  return text:match(":%s*$") ~= nil
end

-- Wraps the blocks in a Typst block with the given options, e.g. "sticky: true".
local function insert_wrapped(result, options, wrapped_blocks)
  result:insert(pandoc.RawBlock("typst", "#block(" .. options .. ")["))
  for _, wrapped in ipairs(wrapped_blocks) do
    result:insert(wrapped)
  end
  result:insert(pandoc.RawBlock("typst", "]"))
end

local function insert_block(result, block)
  if is_short_table(block) then
    insert_wrapped(result, "breakable: false, above: 1.2em, below: 1.2em", { block })
  else
    result:insert(block)
  end
end

function Blocks(blocks)
  if FORMAT ~= "typst" then
    return nil
  end
  local result = pandoc.Blocks({})
  for position = 1, #blocks do
    local block = blocks[position]
    local next_block = blocks[position + 1]
    if next_block ~= nil and introduced_blocks[next_block.t] and ends_with_colon(block) then
      insert_wrapped(result, "sticky: true", { block })
    else
      insert_block(result, block)
    end
  end
  return result
end
