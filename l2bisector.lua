------------------------------------------------------------------------
-- ipelet: max-bisector.lua
------------------------------------------------------------------------
--
-- This ipelet lets one create a maximum norm bisector between two 
-- points.
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

label = "L2-Bisector"

about = [[
   Create L-2 bisector between two points. Weights given by symbol size.
]]

local publicClass={};

function publicClass.helloWorld()
    print("Hello World");
end;

return publicClass;

function incorrect(model)
  model:warning("Selection is NOT two points (marks)!")
end

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


function create_line_segment(model, start, stop)
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
function create_bisector(model)
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
      create_line_segment(model, start, stop)
   end

   return
end


methods = {
  { label="L2-weighted-Bisector (two points)", run = create_bisector },
}
