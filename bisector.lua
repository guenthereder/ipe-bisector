------------------------------------------------------------------------
-- ipelet: bisector.lua
------------------------------------------------------------------------
--
-- This ipelet lets one create a (weighted) bisector between two line 
-- segments. If the two supporting lines do not intersect you get a line 
-- segment (weighted) centered between them.
--
-- Weights are defined by the line pen-width.
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
-- geder@cs.sbg.ac.at -------------------------------------------------

label = "Bisector"

about = [[
   Create (weighted) bisector between lines.
]]

-----------------------------------------------------------------------
--    START point bisector
-----------------------------------------------------------------------

function getWeight(S)
   local size = S:get('symbolsize')
   
   if size == "tiny" then
      size = 1.1
   elseif size == "small" then
      size = 2.0
   elseif size == "normal" then
      size = 3.0
   elseif size == "large" then
      size = 5.0
   elseif math.type(size) == "nil" then 
      print("Warning: Unknown size: " + size)
      size = 2.0
   end

   return size
end

function collect_points(model)
   local p = model:page()

   local items = {}
   local item_cnt = 0

   for i, obj, sel, layer in p:objects() do
	   if sel then
         items[item_cnt] = obj
         item_cnt = item_cnt + 1
	   end	 
   end

   if item_cnt < 2 or item_cnt > 2 then incorrect(model) return end
  
   local A = items[0]
   local B = items[1]

   if B:type() ~= "reference" then incorrect(model) return end
   if A:type() ~= "reference" then incorrect(model) return end

   if getWeight(A) < getWeight(B) or 
      getWeight(A) == getWeight(B) and A:position().x < B:position().x or
      getWeight(A) == getWeight(B) and A:position().x == B:position().x and A:position().y < B:position().y then
      return A, B, A:matrix(), B:matrix()
   else 
      return B, A, B:matrix(), A:matrix()
   end
end


function pbis_create_line_segment(model, start, stop)
   local shape = { type="curve", closed=false; { type="segment"; start, stop } }
   local s = ipe.Path(model.attributes, { shape } )
   if s then
      model:creation("create line segment", s)
   end
end

function create_circle(model, midpoint, radius)
   local m = ipe.Matrix(radius,0,0,radius)
   local trans = ipe.Translation(midpoint)
   local mt = trans * m
   local shape = { type="ellipse", closed=true; mt}
   local s = ipe.Path(model.attributes, { shape } )
   if s then
        model:creation("create circle", s)
   end
end

function dist(a,b)
   local cx = a.x-b.x
   local cy = a.y-b.y
   return math.sqrt(cx^2 + cy^2) 
end

function getWeightedCircle(a,b,wa,wb)
   local div = wa^2 - wb^2
   if div ~= 0 then
      local center = ( (wa^2 * b) - (wb^2 * a) ) * (1 / div)
      local radius = math.abs(wa * wb * dist(a,b) / div)
      return center, radius
   end
   return a, 1
end

function getPointBisector(a,b)
   local l   = ipe.LineThrough(a, b)
   local ext = dist(a,b)
   local pi = a + (1/2 * (b-a))
   local vtrans = l:normal() * ext
   return pi-vtrans, pi+vtrans
end

-- calculate weighted L-inf bisector between two sites A and B
function create_point_bisector(model)
   -- get sites (B is dominant over A, i.e., has a larger weight) 
   A, B, matrixA, matrixB = collect_points(model)

   if not A or not B then return end

   local a, b = matrixA * A:position(), matrixB * B:position()
   local wa, wb = getWeight(A), getWeight(B)
  
   if wa ~= wb then
      local midpoint, radius = getWeightedCircle(a,b,wa,wb)
      create_circle(model, midpoint, radius)
   else
      local start, stop = getPointBisector(a,b)
      pbis_create_line_segment(model, start, stop)
   end

   return
end

-----------------------------------------------------------------------
--    END point bisector
-----------------------------------------------------------------------


-----------------------------------------------------------------------
--    START line-segment bisector
-----------------------------------------------------------------------


function incorrect(model)
  model:warning("Selection are not TWO lines or points!")
end

function getPenSize(S)
   local size = S:get('pen')
   
   if size == "normal" then
      size = 0.4
   elseif size == "heavier" then
      size = 0.8
   elseif size == "fat" then
      size = 1.2
   elseif size == "ultrafat" then
      size = 2.0
   elseif math.type(size) == "nil" then 
      print("Warning: Unknown pensize: " + size)
      size = 0.4
   end
 
   return size
end

function collect_segments(model)
   local p = model:page()

   local items = {}
   local item_cnt = 0
   
   segments = {}
   weights  = {}

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
                  weights[seg_idx] = getPenSize(obj_a)
                  seg_idx = seg_idx + 1
               end
            end
            return segments, weights, obj_a:matrix(), obj_a:matrix()
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

  weights[0] = getPenSize(obj_a)
  weights[1] = getPenSize(obj_b)

  return segments, weights, obj_a:matrix(), obj_b:matrix()
end

function angle_bisector(dir1, dir2, w1, w2)
  assert(dir1:sqLen() > 0)
  assert(dir2:sqLen() > 0)
  local bisector = ( dir1:normalized() * (1/w1) ) + ( dir2:normalized() * (1/w2) )
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

function bisector(model, a, b, c, d, w1, w2)
  local l1 = ipe.LineThrough(a,b)
  local l2 = ipe.LineThrough(c,d)
  local intersect = l1:intersects(l2)
  
  if intersect then
     local bis = angle_bisector(b-a, d-c, w1, w2) 
     local start, stop = calculate_start_stop(a,b,c,d,intersect,bis)

     return create_line_segment(model, start, stop )
  else

     local l1_normal = l1:normal()
     local dist = l1:distance(c)/2.0 * (w1/w2)
     local center = a + (l1_normal:normalized()*dist)
     
     if l2:distance(center) > dist*2.0 * (w1/w2) then
        center = a - (l1_normal:normalized()*dist)
     end

     local start, stop = calculate_start_stop(a,b,c,d,center,l1:dir())
     
     local l12 = l1
     local l13 = ipe.LineThrough(a,c)
     local l14 = ipe.LineThrough(a,d)
     if l12:dir() == l13:dir() and l13:dir() == l14:dir() then
         -- strange way of testing, but in this case the lines are colinear
         center = a + ((d-a)*0.5)
         start, stop =  calculate_start_stop(a,b,c,d,center,l1:normal())
     end

      
     return create_line_segment(model, start, stop )
  end
end

function create_bisector_obj(model,seg1,seg2,w1,w2,matrix1,matrix2)
   local a = matrix1 * seg1[1]
   local b = matrix1 * seg1[2]
   local d = matrix2 * seg2[1]
   local c = matrix2 * seg2[2]
   
   local obj = bisector(model, a, b, c, d, w1, w2)
   if obj then
      model:creation("create bisector of lines", obj)
   end
end

function start_bisector(model,createall)
  segments, weights, matrix, matrix2 = collect_segments(model)
  if not segments then return end

  if createall then
     for idx_a=0,#segments-1 do
         for idx_b=idx_a+1,#segments do
            local seg1 = segments[idx_a]
            local seg2 = segments[idx_b]
            local w1   = weights[idx_a]
            local w2   = weights[idx_b]

            create_bisector_obj(model,seg1,seg2,w1,w2,matrix,matrix2)
         end
     end
  else
     local idx = 0
     while idx < #segments do
        local seg1 = segments[idx]
        local seg2 = segments[idx+1]
        local w1   = weights[idx]
        local w2   = weights[idx+1]

        create_bisector_obj(model,seg1,seg2,w1,w2,matrix,matrix2)

        idx = idx+1
      end
      if #segments-1 > 1 then
        local seg1 = segments[idx]
        local seg2 = segments[0]
        local w1   = weights[idx]
        local w2   = weights[0]

        local a = matrix * seg1[1]
        local b = matrix * seg1[2]
        local d = matrix * seg2[1]
        local c = matrix * seg2[2]

        if a == c or b ==d then
            create_bisector_obj(model,seg1,seg2,w1,w2,matrix,matrix2)
        end
      end
  end

end

function selectionHasRef(model)
   local p = model:page()
   for i, obj, sel, layer in p:objects() do
	   if sel and obj:type() == "reference" then
         return true
	   end	 
   end
   return false
end

function create_bisector(model)
   -- if selection has ref (mark)
   if selectionHasRef(model) then
      create_point_bisector(model)
   else 
      start_bisector(model,false)
   end
end

function create_all_bisector(model)
   start_bisector(model,true)
end

methods = {
  { label="Bisector of two segments or points", run = create_bisector },
  { label="All Bisectors of polyline", run = create_all_bisector },
}

shortcuts.ipelet_1_bisector = "Shift+D"  -- Weighted Bisector
