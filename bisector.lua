------------------------------------------------------------------------
-- ipelet: bisector.lua
------------------------------------------------------------------------
--
-- This ipelet lets one create a bisector between two line segments.
-- If the two supporting lines do not intersect you get a line segment
-- centered between them.
--
-- File used as a kind of template to create this: 
-- (http://www.filewatcher.com/p/ipe_7.1.1-1_i386.deb.1106034/usr/lib
-- /ipe/7.1.1/ipelets/euclid.lua.html)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- geder@cosy.sbg.ac.at -----------------------------------------------

label = "Bisector"

about = [[
   Create bisector between lines.
]]

function incorrect(model)
  model:warning("Primary selection are not TWO lines")
end

function collect_vertices(model)
   local p = model:page()

   local items = {}
   local item_cnt = 0

   for i, obj, sel, layer in p:objects() do
	   if sel then
         items[item_cnt] = obj
         item_cnt = item_cnt + 1
	   end	    
   end

  if item_cnt > 2 or item_cnt < 2 then incorrect(model) return end

  local obj_a = items[0]
  local obj_b = items[1]

  if (obj_a:type() ~= "path" or obj_b:type() ~= "path") then incorrect(model) return end

  local shape_a = obj_a:shape()
  local shape_b = obj_b:shape()
  
  if (#shape_a ~= 1 or shape_a[1].type ~= "curve" or #shape_a[1] ~= 1
      or shape_a[1][1].type ~= "segment") 
  then
    incorrect(model)
    return
  end
  if (#shape_b ~= 1 or shape_b[1].type ~= "curve" or #shape_b[1] ~= 1
      or shape_b[1][1].type ~= "segment") 
  then
    incorrect(model)
    return
  end

  local m_a = obj_a:matrix()
  local m_b = obj_b:matrix()
  local a = m_a * shape_a[1][1][1]
  local b = m_a * shape_a[1][1][2]
  local d = m_b * shape_b[1][1][1]
  local c = m_b * shape_b[1][1][2]
  return a, b, c, d
end

function angle_bisector(dir1, dir2)
  assert(dir1:sqLen() > 0)
  assert(dir2:sqLen() > 0)
  local bisector = dir1:normalized() + dir2:normalized()
  if bisector:sqLen() == 0 then bisector = dir1:orthogonal(); print("ortho...") end
  return bisector 
end

function create_line_segment(model, start, stop)
  local shape = { type="curve", closed=false; { type="segment"; start, stop } }
  return ipe.Path(model.attributes, { shape } )
end

function calculate_start_stop(a,b,c,d,intersect,bis)
   local bi_line = ipe.LineThrough(intersect, intersect + bis)
--   local angle = bi_line:dir():angle()
   local start  = bi_line:project(a)

   local length = math.abs( math.sqrt( (a-b) .. (a-b) ) + math.sqrt( (c-d) .. (c-d) ) ) / 2.0

   return start, (start + (bis:normalized() * length))
end

function bisector(model, a, b, c, d)
  local l1 = ipe.LineThrough(a,b)
  local l2 = ipe.LineThrough(c,d)
  local intersect = l1:intersects(l2)
  
  if intersect then
     local bis = angle_bisector(b-a, d-c) 
     local start, stop = calculate_start_stop(a,b,c,d,intersect,bis)
      
     return create_line_segment(model, start, stop )
  else
     local l1_normal = l1:normal()
     local dist = l1:distance(c)/2.0
     local center = a + (l1_normal:normalized()*dist)
     if l2:distance(center) > dist*2.0 then
         center = a - (l1_normal:normalized()*dist)
     end
     local start, stop = calculate_start_stop(a,b,c,d,center,l1:dir())
      
     return create_line_segment(model, start, stop )
  end
end


function create_bisector(model)
  local a, b, c, d = collect_vertices(model)
  if not a then return end

  local obj = bisector(model, a, b, c, d)
  if obj then
    model:creation("create bisector of lines", obj)
  end
end

methods = {
  { label="Bisector of two lines", run = create_bisector },
  --{ label="Bisector of two lines", run = create_incircle },
  --{ label="(nothing yet)", run = create_excircles },
}
