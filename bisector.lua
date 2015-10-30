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
  model:warning("Selection are not TWO lines or a polyline!")
end

function collect_segments(model)
   local p = model:page()

   local items = {}
   local item_cnt = 0
   
   segments = {}

   for i, obj, sel, layer in p:objects() do
	   if sel then
         items[item_cnt] = obj
         item_cnt = item_cnt + 1
	   end	    
   end

   if item_cnt == 0 then incorrect(model) return end
  
   local obj_a = items[0]
   if item_cnt == 1 and obj_a:type() == "path" then
      local my_path = obj_a:shape()
      if(#my_path > 0) then
         local sub_path = my_path[1]
         if(#sub_path > 1) then
            local seg_idx = 0
            for idx=1,#sub_path do
               local seg = sub_path[idx]
               if(seg.type == "segment") then
                  segments[seg_idx] = sub_path[idx]
                  seg_idx = seg_idx + 1
               end
            end
            return segments, obj_a:matrix(), obj_a:matrix()
         end
      end
   end

  if item_cnt > 2 or item_cnt < 2 then incorrect(model) return end

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

  segments[0] = shape_a[1][1]
  segments[1] = shape_b[1][1]

  return segments, obj_a:matrix(), obj_b:matrix()


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
   local start   = bi_line:project(a)
   local length  = math.abs( math.sqrt( (a-b) .. (a-b) ) + math.sqrt( (c-d) .. (c-d) ) ) / 2.0

   local dx = (b-a)
   local dy = (d-c)

   local angle = (math.asin(  (dx.x*dy.y - dx.y*dy.x) / (math.sqrt(dx.x*dx.x + dx.y*dx.y) * math.sqrt(dy.x*dy.x + dy.y*dy.y ) ) ) ) *180 / math.pi
   local stop;

   -- start at a common endpoint in case one exists
   if a == c or b ==d then 
      if a == c     then start = a 
      elseif b == d then start = b
      end

      if angle > math.pi then 
         stop = start + (bis:normalized() * length)
      elseif angle <= math.pi then
         stop = start - (bis:normalized() * length)
      end
      
      return start, stop;
   end

   stop   = start + (bis:normalized() * length)

   return start, stop
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

function create_bisector_obj(model,seg1,seg2,matrix1,matrix2)
   local a = matrix1 * seg1[1]
   local b = matrix1 * seg1[2]
   local d = matrix2 * seg2[1]
   local c = matrix2 * seg2[2]
   
   local obj = bisector(model, a, b, c, d)
   if obj then
      model:creation("create bisector of lines", obj)
   end
end

function start_bisector(model,createall)
  segments, matrix, matrix2 = collect_segments(model)
  if not segments then return end

  if createall and #segments >= 2 then
     for idx_a=0,#segments-1 do
         for idx_b=idx_a+1,#segments do
            local seg1 = segments[idx_a]
            local seg2 = segments[idx_b]

            create_bisector_obj(model,seg1,seg2,matrix,matrix2)
         end
     end
  else
     local idx = 0
     while idx < #segments do
        local seg1 = segments[idx]
        local seg2 = segments[idx+1]

        create_bisector_obj(model,seg1,seg2,matrix,matrix2)

        idx = idx+1
      end
      if #segments > 1 then
        local seg1 = segments[idx]
        local seg2 = segments[0]

        local a = matrix * seg1[1]
        local b = matrix * seg1[2]
        local d = matrix * seg2[1]
        local c = matrix * seg2[2]

        if a == c or b ==d then
            create_bisector_obj(model,seg1,seg2,matrix,matrix2)
        end
      end
  end

end

function create_all_bisector(model)
   start_bisector(model,true)
end

function create_bisector(model)
   start_bisector(model,false)
end

methods = {
  { label="Bisector (two edges|polyline)", run = create_bisector },
  { label="All Bisectors of polyline", run = create_all_bisector },
  --{ label="Bisector of two lines", run = create_incircle },
  --{ label="(nothing yet)", run = create_excircles },
}
