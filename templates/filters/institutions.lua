---
--- This is a simple pandoc filter 
--- that takes metadata from the document 
--- and expands it to contain institutions.
---
--- before
---    author:
---      - name: ..
---        affiliation:
---          - name: ...
---
--- after:
---
--- author:
---   - name: ..
---     affiliation: ..
---     inst-num: x 
---
--- institutions:
---   - name: ...
---   - name: ...


local function gather_institutions(meta)
  local authors = meta.author or {}
  -- hash set to avoid duplicates
  local institutions = {}
  for _, author in ipairs(authors) do
    if author.affiliation then
      for _, aff in ipairs(author.affiliation) do
        if aff.name then
          institutions[aff.name] = true
        end
      end
    end
  end

  local inst_list = {}
  for name in pairs(institutions) do
    table.insert(inst_list, {name = name})
  end
  meta.institutions = inst_list

  -- update authors
  for i, author in ipairs(authors) do
    if author.affiliation then
      for _, aff in ipairs(author.affiliation) do
        if aff.name then
          for j, inst in ipairs(inst_list) do
            if inst.name == aff.name then
              author['inst-num'] = j
              break
            end
          end
        end
      end
    end
    authors[i] = author  -- update the author in the list
  end

  meta.author = authors
  return meta
end

return {
  { Meta = gather_institutions },
}
