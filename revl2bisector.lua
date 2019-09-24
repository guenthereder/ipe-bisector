------------------------------------------------------------------------
-- ipelet: rev-l2-bisector.lua
------------------------------------------------------------------------
--
-- This ipelet is for researching the MWVD in particular its bisector arcs.
-- Given an arc and a site and weight (mark,size) this ipelet constructs
-- the second site and weight that produces the circle defining the arc.
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
-- geder@cs.sbg.ac.at -----------------------------------------------

label = "Rev-L2-Bisector"

about = [[
   Create the corresponding site and weight for a given arc and site.
]]

function incorrect(model)
  model:warning("Selection is not an arc and a point (mark)!")
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

function getArcFromArcObj(arcObj)
   return arcObj:shape()[1][1]
end

function collect_elements(model)
   local p = model:page()

   local items = {}
   local item_cnt = 0

   for i, obj, sel, layer in p:objects() do
	   if sel then
         items[item_cnt] = obj
         item_cnt = item_cnt + 1
	   end	 
   end

   if item_cnt ~= 2 then incorrect(model) return end
   
   local A, B = items[0], items[1]

   if A:type() == "reference" and B:type() == "path" then
      return A, getArcFromArcObj(B), A:matrix(), B:matrix()
   end
   
   if B:type() == "reference" and A:type() == "path" then
      return B, getArcFromArcObj(A), B:matrix(), A:matrix()
   end

   incorrect(model) return 
end

function dist(a,b)
   local cx = a.x-b.x
   local cy = a.y-b.y
   return math.sqrt(cx^2 + cy^2) 
end

function orderIntersectionPoints(vect,s1)
   if dist(s1,vect[1]) < dist(s1,vect[2]) then
      return vect[1], vect[2]
   else 
      return vect[2], vect[1]
   end
end

function reverseBisector(s1, sigS1, arc)
   local mat = arc.arc:matrix()
   
   local circ = ipe.Arc(mat)
   local m = mat:translation()
   local d = (s1-m):normalized()
   local l = ipe.Line(m,d)
   
   p1, p2 = orderIntersectionPoints(circ:intersect(l),s1)

   print(p1,p2,m,s1,sigS1)

   d1, d2 = dist(s1,p1), dist(s1,p2)
   t1, t2 = d1/sigS1, d2/sigS1

   sigS2xd =  (1/(t2-t1)) * (p1-p2)

   s2 = p1 + sigS2xd * t1
   sigS2 = sigS2xd:len()

   return s2, sigS2
end

function drawMarkOfSize(model,s,size,mark)
   mark:set('symbolsize',size)
   local trans = ipe.Translation(s)
   mark:setMatrix(mark:matrix() * trans)
   local ref = ipe.Reference(model.attributes, "mark/disk(sx)", s)
   ref:set('symbolsize',size)
   if ref then
        model:creation("create mark", ref)
   end
end

function create_site(model)
   S1, arc, matrixS1, matrixarc = collect_elements(model)

   if not S1 or not arc then return end

   local s1 = matrixS1 * S1:position()
   local sigmaS1 = getWeight(S1)

   s2, sigmaS2 = reverseBisector(s1, sigmaS1, arc)

   drawMarkOfSize(model,s2,sigmaS2,S1:clone())

   return
end


methods = {
  { label="Rev-L2-weighted-bisector (point, arc)", run = create_site },
}
