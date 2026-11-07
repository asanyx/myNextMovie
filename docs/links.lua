-- Relative links like ../README.md point into the repository on GitHub,
-- so they still work in the PDF.
local repo = "https://github.com/fwsoft/my-next-movie/blob/main/"

function Link(link)
  local target = link.target
  if target:match("^%a[%w+.-]*:") or target:match("^#") then
    return nil
  end
  if target:match("^%.%./") then
    link.target = repo .. target:sub(4)
  else
    link.target = repo .. "docs/" .. target
  end
  return link
end
