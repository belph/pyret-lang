## image_matrix_helpers.arr
## -------------------
## Blame issues on:
##  Philip Blair (GitHub: belph)
##  peblairman@gmail.com

## Description:
## ------------
## Provides matrix transformation
## functions used in image library

provide {
  vector-add : vector-add,
  vector-sub : vector-sub,
  points-bounding-box : points-bounding-box,
  list-of-points-bounding-box : list-of-points-bounding-box,
  mtx-center : mtx-center,
  translate : translate,
  translate-posn : translate-posn,
  trans-mtx : trans-mtx,
  homogeneous-transform : homogeneous-transform,
  transform-posn : transform-posn,
  transform-posn-about : transform-posn-about,
  affine-transform-matrix : affine-transform-matrix,
  matrix-to-posns : matrix-to-posns,
  matrices-to-posns : matrices-to-posns,
  bezier-box : bezier-box,
  cubic-bezier-bounding-box : cubic-bezier-bounding-box,
  bezier-snap-trans : bezier-snap-trans,
  bez-corner-box : bez-corner-box,
  poly-corner-box : poly-corner-box,
  cornerbox : cornerbox
} end

provide-types {
  CornerBox : CornerBox
}

#import matrix, vector from shared-gdrive("matrices_3", "0ByJ_bK5RkycfSVZTRFd5QUpzaWc")
#import shared-gdrive("matrices_3", "0ByJ_bK5RkycfSVZTRFd5QUpzaWc") as M
#import shared-gdrive("image_auxiliary_datatypes", "0ByJ_bK5RkycfNEd0WGJ5eFc3RE0") as IM_AUX
#import matrix, vector from "matrices.arr"
#import "matrices.arr" as M
#import "image_auxiliary_datatypes.arr" as IM_AUX
import matrix, vector from matrices
import matrices as M
import image_auxiliary_datatypes as IM_AUX
import lists as L

# Random Helpers

fun about<X>(a :: X, b :: X) -> Boolean:
  doc: "Returns true if the two arguments are roughly equal"
  loc-within = within(0.001)
  if M.is-matrix(a):
    L.all2(loc-within, a.to-list(), b.to-list())
  else if is-link(a):
    L.all2(loc-within, a, b)
  else if IM_AUX.is-posn(a):
    (loc-within(a.x, b.x) and loc-within(a.y, b.y))
  else if is-number(a):
    loc-within(a, b)
  else:
    raise('Unknown values given to about(): ' + a + ' and ' + b)
  end
where:
  [matrix(2,2): 1, 2, 3, 4] is%(about) [matrix(2,2): 1, 2, 3, 4]
  [list: 1, 2, num-sqrt(2)] is%(about) [list: 1, 2, num-sqrt(2)]
  [list: 1, num-sqrt(2), 5] is-not%(about) [list: 1, 5, num-sqrt(2)]
  num-sqrt(6) is%(about) num-sqrt(6)
  num-sqrt(7) is-not%(about) num-sqrt(6)
end

# Inspired by Python's min and max functions
fun min<X>(l :: List<X>) -> X:
  doc: "Returns the minimal element of the given list. The elements of the list must be able to be compared with <"
  when is-empty(l):
    raise("min: Cannot find the least element of an empty list.")
  end
  if is-number(l.first):
    fold(lam(r,f): if (num-exact(r) < num-exact(f)): r else: f end end, l.first, l.rest)
  else:
    fold(lam(r,f): if (r < f): r else: f end end, l.first, l.rest)
  end
where:
  min([list: 2, 3, 1, 5, 3, -5, 2]) is -5
  min([list: 8, 8, 8, 8, 8, 8, 9]) is 8
end

fun max<X>(l :: List<X>) -> X:
  doc: "Returns the maximal element of the given list. The elements of the list must be able to be compared with >"
  when is-empty(l):
    raise("max: Cannot find the greatest element of an empty list.")
  end
  if is-number(l.first):
    fold(lam(r,f): if (num-exact(r) > num-exact(f)): r else: f end end, l.first, l.rest)
  else:
    fold(lam(r,f): if (r > f): r else: f end end, l.first, l.rest)
  end
where:
  max([list: 2, 3, 1, 5, 3, -5, 2]) is 5
  max([list: 8, 8, 8, 8, 8, 8, 9]) is 9
end

fun vector-add(a :: M.Vector, b :: M.Vector) -> M.Vector:
  doc: "Adds the second vector to the first"
  [vector: (a.first + b.first), (a.get(1) + b.get(1))]
where:
  vector-add([vector: 12, 15], [vector: 3, 2]) is [vector: 15, 17]
end

fun vector-sub(a :: M.Vector, b :: M.Vector) -> M.Vector:
  doc: "Subtracts the second vector from the first"
  [vector: (a.first - b.first), (a.get(1) - b.get(1))]
where:
  vector-sub([vector: 12, 15], [vector: 3, 2]) is [vector: 9, 13]
end

# Called by Image's get-box() method
fun points-bounding-box(mtx :: M.Matrix) -> IM_AUX.Box:
  doc: "Returns the size of the box containing the given points"
  m = mtx.to-lists()
  IM_AUX.box((max(m.get(0)) - min(m.get(0))), (max(m.get(1)) - min(m.get(1))))
where:
  points-bounding-box([matrix(2,4): 1, 2, 3, 4, 5, 6, 7, 8]) is IM_AUX.box(3,3)
end

fun list-of-points-bounding-box(l :: List<M.Matrix>) -> IM_AUX.Box:
  doc: "Returns the bounding box for the entirety of the given list"
  points-bounding-box(fold(lam(acc,cur): acc.augment(cur) end, l.first, l.rest))
where:
  list-of-points-bounding-box([list: [matrix(2,4): 1, 2, 3, 4, 5, 6, 7, 8], [matrix(2,3): 10, 11, 12, 13, 14, 15]]) is IM_AUX.box(11,10)
end

fun mtx-center(mtx :: M.Matrix) -> IM_AUX.Position:
  doc: "Returns the center point of the given matrix"
  b = points-bounding-box(mtx)
  IM_AUX.posn(b.width / 2, b.height / 2)
end

lstlength = lam(n): lam(l :: List): l.length() == n end end
# We only want 2-Dimensional Translations.
length2 = lstlength(2)

fun translate(m :: M.Matrix, v :: M.Vector%( length2 )) -> M.Matrix:
  doc: "Translates all positions in the given matrix by the given amount"
  from-homogeneous(
    [matrix(3,3): 1, 0, v.get(0), 0, 1, v.get(1), 0, 0, 1] *
    to-homogeneous(m))
where:
  translate([matrix(2,3): 1, 2, 3, 2, 3, 4], [vector: 1, 1]) is
  [matrix(2,3): 2, 3, 4, 3, 4, 5]
end

# So centers can stay consistent
fun translate-posn(p :: IM_AUX.Position, v :: M.Vector%(length2)) -> IM_AUX.Position:
  doc: "Translates the given position by the given vector"
  IM_AUX.posn(p.x + v.get(0), p.y + v.get(1))
where:
  translate-posn(IM_AUX.posn(10,20), [vector: 2, 3]) is IM_AUX.posn(12,23)
end

#TODO: List<Matrix> output may be deprecated...need to check.
fun trans-mtx(mtx :: M.Matrix, img): # -> Matrix or List<Matrix>
  doc: "Transforms the given matrix or list of matrixes by the given matrix"
  if (is-link(img) or is-empty(img)):
    map(lam(i): trans-mtx(mtx, i) end, img)
  else:
    mtx * img
  end
end

fun to-homogeneous(m :: M.Matrix) -> M.Matrix:
  doc: "Converts the given positions into Homogeneous Coordinate positions"
  m.stack(M.make-matrix(1,m.cols,1)).augment(M.make-matrix(m.rows, 1, 0).stack(M.make-matrix(1,1,1)))
where:
  to-homogeneous([matrix(2,2): 1, 2, 2, 3]) is 
  [matrix(3,3): 1, 2, 0, 2, 3, 0, 1, 1, 1]
end

fun from-homogeneous(m :: M.Matrix) -> M.Matrix:
  doc: "Converts the given positions back from Homogeneous Coordinates"
  m.submatrix(range(0,(m.rows - 1)), range(0, m.cols - 1))
where:
  from-homogeneous([matrix(3,3): 1, 2, 0, 2, 3, 0, 1, 1, 1]) is
  [matrix(2,2): 1, 2, 2, 3]
end

# Will possibly deprecate
matrix2d = lam(m): m.rows == 2 end
# NOTE: Translation is a special case, so it gets its own function
fun homogeneous-transform(trans :: M.Matrix%(matrix2d), other :: M.Matrix%(matrix2d)):
  doc: "Transforms the given 2d matrices using homogeneous coordinates"
  from-homogeneous(
    to-homogeneous(trans) * to-homogeneous(other))
where:
  homogeneous-transform([matrix(2,2):1,0,0,-1],[matrix(2,3):1,2,3,4,5,6]) is
  [matrix(2,3):1,2,3,-4,-5,-6]
end



# For Centers
fun transform-posn(m :: M.Matrix, p :: IM_AUX.Position):
  doc: "Returns the given Position after transforming it with the given matrix"
  trans = (to-homogeneous(m) * [matrix(3,1): p.x, p.y, 1]).submatrix([list:0],[list:0,1]).to-list()
  IM_AUX.posn(trans.get(0),trans.get(1))
end

fun transform-posn-about(m :: M.Matrix, p :: IM_AUX.Position, abt :: IM_AUX.Position):
  doc: "Transforms the given position using the given matrix about the given point"
  temp = transform-posn(m, IM_AUX.posn(p.x - abt.x, p.y - abt.y))
  IM_AUX.posn(temp.x + abt.x, temp.y + abt.y)
end

fun affine-transform-matrix(transformation :: M.Matrix%(matrix2d), to-trans :: M.Matrix, m-center :: IM_AUX.Position) -> M.Matrix:
  doc: "Performs the given transformation on the given matrix about the given point"
  translate(homogeneous-transform(transformation,
      translate(to-trans,[vector: (-1 * m-center.x), (-1 * m-center.y)])),[vector: m-center.x, m-center.y])
end

fun transform-box(b :: IM_AUX.Box, mtx :: M.Matrix) -> IM_AUX.Box:
  doc: "Returns the given box after being transformed by the given matrix"
  b-mtx = [matrix(2,4): 0, 0, b.x, b.x, 0, b.y, b.y, 0]
  trans = homogeneous-transform(mtx,b-mtx)
  points-bounding-box(trans)
end

fun matrix-to-posns(m :: M.Matrix%(matrix2d)) -> List<IM_AUX.Position>:
  doc: "Converts the given 2D Matrix into a list of positions"
  for map(col from m.transpose().to-lists()):
    IM_AUX.posn(col.get(0), col.get(1))
  end
where:
  matrix-to-posns([matrix(2, 3): 1, 2, 3, 4, 5, 6]) is
  [list: IM_AUX.posn(1,4), IM_AUX.posn(2,5), IM_AUX.posn(3,6)]
end

fun matrices-to-posns(l :: List<M.Matrix>) -> List<List<IM_AUX.Position>>:
  doc: "Converts the given list of 2d matrices into a list of lists of their positions"
  map(matrix-to-posns,l)
end

# Represents a box with the given top-left and bottom-right corner positions
# (The box is not rotated)
# Assumption: both the top-left x and y are less than the bottom-right x and y
# (Or one of the two are equal...Regardless, bottom-right is never above or to
#   the left of top-left)
data CornerBox:
  | cornerbox(top-left :: IM_AUX.Position, bottom-right :: IM_AUX.Position) with:
    join(self, other :: CornerBox) -> CornerBox:
      doc: "Returns the smallest box containing the box and the given box"
      minx = num-min(self.top-left.x, other.top-left.x)
      miny = num-min(self.top-left.y, other.top-left.y)
      maxx = num-max(self.bottom-right.x, other.bottom-right.x)
      maxy = num-max(self.bottom-right.y, other.bottom-right.y)
      cornerbox(IM_AUX.posn(minx, miny), IM_AUX.posn(maxx, maxy))
    end,
    intersect(self, other :: CornerBox) -> CornerBox:
      doc: "Returns the intersection of the two given cornerboxes"
      # Courtesy of Charles Bretana on SO (yeah, this is straighforward,
      #   but I had just woken up, so I Googled it. Sue me.),if any of 
      #   these four conditions are met, there is no intersection:
      # 1. Left edge of self right of right edge of other
      cond1 = num-exact(self.top-left.x) > num-exact(other.bottom-right.x)
      # 2. Right edge of self left of left edge of other
      cond2 = num-exact(self.bottom-right.x) < num-exact(other.top-left.x)
      # 3. Top of self below bottom of other (> because screen coordinates)
      cond3 = num-exact(self.top-left.y) > num-exact(other.bottom-right.y)
      # 4. Bottom of self above top of other
      cond4 = num-exact(self.bottom-right.y) < num-exact(other.top-left.y)
      if (cond1 or cond2 or cond3 or cond4):
        cornerbox(IM_AUX.posn(0,0),IM_AUX.posn(0,0)) # Useful to return something instead
                                                     # of erroring
      else:
        new-tl = IM_AUX.posn(num-max(self.top-left.x,other.top-left.x),num-max(self.top-left.y,other.top-left.y))
        new-br = IM_AUX.posn(num-min(self.bottom-right.x,other.bottom-right.x),num-min(self.bottom-right.y,other.bottom-right.y))
        cornerbox(new-tl, new-br)
      end
    end,
	  get-center(self) -> IM_AUX.Position:
	    doc: "Returns the center of this CornerBox"
	    IM_AUX.posn(num-round-even((self.bottom-right.x + self.top-left.x) / 2), num-round-even((self.bottom-right.y + self.top-left.y) / 2))
	  end,
    to-box(self) -> IM_AUX.Box:
      doc: "Converts the CornerBox into a normal Box"
      IM_AUX.box((self.bottom-right.x - self.top-left.x), (self.bottom-right.y - self.top-left.y))
    end,
    translate(self, x :: Number, y :: Number) -> CornerBox:
      doc: "Translates this cornerbox by the given amount"
      new-tl = IM_AUX.posn(self.top-left.x + x, self.top-left.y + y)
      new-br = IM_AUX.posn(self.bottom-right.x + x, self.bottom-right.y + y)
      cornerbox(new-tl, new-br)
    end
where:
  a = cornerbox(IM_AUX.posn(10,10), IM_AUX.posn(40,50))
  a.join(cornerbox(IM_AUX.posn(15,5), IM_AUX.posn(60,60))) is
  cornerbox(IM_AUX.posn(10,5), IM_AUX.posn(60,60))
  
  a.join(cornerbox(IM_AUX.posn(15,5), IM_AUX.posn(60,30))) is
  cornerbox(IM_AUX.posn(10,5), IM_AUX.posn(60,50))
  
  a.join(cornerbox(IM_AUX.posn(0,0), IM_AUX.posn(5,5))) is
  cornerbox(IM_AUX.posn(0,0), IM_AUX.posn(40, 50))
  
  a.intersect(cornerbox(IM_AUX.posn(0,0),IM_AUX.posn(100,100))) is a
  
  a.intersect(cornerbox(IM_AUX.posn(15,0),IM_AUX.posn(30,55))) is 
  cornerbox(IM_AUX.posn(15,10), IM_AUX.posn(30,50))
  
  a.to-box() is IM_AUX.box(30,40)
end

# Represents a curve parameterized by two functions of t
data Param2D:
  | param(x :: (Number -> Number), y :: (Number -> Number)) with:
    at(self, t :: Number) -> IM_AUX.Position:
      doc: "Evaluates the curve's position at the given time"
      IM_AUX.posn(self.x(t), self.y(t))
    end
where:
  xt = lam(t): t * 2 end
  yt = lam(t): num-expt(t,2) end
  pt = param(xt,yt)
  pt.at(1) is%(about) IM_AUX.posn(2, 1)
  pt.at(3) is%(about) IM_AUX.posn(6, 9)
end



# Represents the a, b, and c in a quadratic equation of the form ax^2 + bx + c = 0
data QuadTuple:
  | qtup(a :: Number, b :: Number, c :: Number) with:
    discriminant(self) -> Number:
      num-expt(self.b, 2) - (4 * self.a * self.c)
    end,
    solve(self) -> List<Number>:
      doc: "Finds all real roots of the quadratic equation"
      disc = self.discriminant()
      # (mag-one is +-1)
      solve = lam(mag-one :: Number): ((-1 * self.b) + (mag-one * num-sqrt(disc))) / (2 * self.a) end
      if num-exact(disc) < 0:
        [list: ]
      else if (num-exact(self.a) == 0) and not(num-exact(self.b) == 0):
        [list: (-1 * self.c) / self.b]
      else if (num-exact(self.a) == 0):
        [list: ]
      else if num-exact(disc) == 0:
        [list: solve(1)]
      else:
        [list: solve(-1), solve(1)]
      end
    end
where:
#  circa = lam(l,r): fold2(lam(a,b,c): a and (num-abs(b - c) < 0.0001) end, true, l, r) end
  qtup(2,4,-4).solve() is%(about) [list: (-1 - num-sqrt(3)), (-1 + num-sqrt(3))]
  qtup(1,4,5).solve() is%(about) [list: ]
  qtup(1,2,1).solve() is%(about) [list: -1]
end

data TuplePair:
  | tup-pair(x :: QuadTuple, y :: QuadTuple) with:
    solutions(self) -> List<Number>:
      self.x.solve() + self.y.solve()
    end
where:
#  circa = lam(l,r): fold2(lam(a,b,c): a and (num-abs(b - c) < 0.0001) end, true, l, r) end
  tup-pair(qtup(2,4,-4),qtup(1,2,1)).solutions() is%(about) [list: (-1 - num-sqrt(3)), (-1 + num-sqrt(3)), -1]
end

# Bounding Box Credit to Floris

fun cubic-bezier-spline(p0 :: IM_AUX.Position, p1 :: IM_AUX.Position, p2 :: IM_AUX.Position, p3 :: IM_AUX.Position) -> Param2D:
  doc: "Returns the parameterization of the curve represented by the given points"
  x = lam(t): (num-expt(t, 3) * ((p3.x - (3 * p2.x)) + ((3 * p1.x) - p0.x))) + (num-expt(t, 2) * (((3 * p2.x) - (6 * p1.x)) + (3 * p0.x))) + (t * ((3 * p1.x) - (3 * p0.x))) + p0.x end
  y = lam(t): (num-expt(t, 3) * ((p3.y - (3 * p2.y)) + ((3 * p1.y) - p0.y))) + (num-expt(t, 2) * (((3 * p2.y) - (6 * p1.y)) + (3 * p0.y))) + (t * ((3 * p1.y) - (3 * p0.y))) + p0.y end
  param(x,y)
end

fun cubic-bezier-tuple(p0 :: IM_AUX.Position, p1 :: IM_AUX.Position, p2 :: IM_AUX.Position, p3 :: IM_AUX.Position) -> TuplePair:
  doc: "Returns the Quadratic Tuple for the bezier curve represented by the given points"
  ax = ((3 * p3.x) - (9 * p2.x)) + ((9 * p1.x) - (3 * p0.x))
  bx = ((6 * p2.x) - (12 * p1.x)) + (6 * p0.x)
  cx = (3 * p1.x) - (3 * p0.x)
  ay = ((3 * p3.y) - (9 * p2.y)) + ((9 * p1.y) - (3 * p0.y))
  by = ((6 * p2.y) - (12 * p1.y)) + (6 * p0.y)
  cy = (3 * p1.y) - (3 * p0.y)
  tup-pair(qtup(ax,bx,cx),qtup(ay,by,cy))
end

fun cubic-bezier-bounding-box(p0 :: IM_AUX.Position, p1 :: IM_AUX.Position, p2 :: IM_AUX.Position, p3 :: IM_AUX.Position) -> CornerBox:
  # We want the solutions where 0<=t<=1
  in-range = lam(t): (0 <= num-exact(t)) and (num-exact(t) <= 1) end
  lessx = lam(a,b): num-exact(a.x) < num-exact(b.x) end
  eqx = lam(a,b): num-exact(a.x) == num-exact(b.x) end
  lessy = lam(a,b): num-exact(a.y) < num-exact(b.y) end
  eqy = lam(a,b): num-exact(a.y) == num-exact(b.y) end
  curve-param = cubic-bezier-spline(p0,p1,p2,p3)
  tups = cubic-bezier-tuple(p0,p1,p2,p3)
  solns = tups.solutions().filter(in-range)
  extrema = solns.map(curve-param.at) + [list: p0, p3] #Add start & end pts
  # Not the most efficient, maybe, but the list will definitely be short, so I'll leave it for now
  min-x = extrema.sort-by(lessx, eqx).first.x
  max-x = extrema.sort-by(lessx, eqx).last().x
  min-y = extrema.sort-by(lessy, eqy).first.y
  max-y = extrema.sort-by(lessy, eqy).last().y
  cornerbox(IM_AUX.posn(min-x, min-y), IM_AUX.posn(max-x, max-y))
end

fun bez-corner-box(pts :: List<IM_AUX.Position>) -> CornerBox:
  var pbs = [list: ]
  getSet = lam(n): [list: pts.get(0 + (3 * n)),pts.get(1 + (3 * n)),pts.get(2 + (3 * n)),pts.get(3 + (3 * n))] end # Returns one of the four bezier curves
  for each(i from range(0,num-floor(pts.length() / 3))):
    st = getSet(i)
    pbs := pbs + [list: cubic-bezier-bounding-box(st.get(0),st.get(1),st.get(2),st.get(3))]
  end
  fold(lam(f,r): f.join(r) end,pbs.first,pbs.rest)
end

fun bezier-box(pts :: List<IM_AUX.Position>) -> IM_AUX.Box:
  doc: "Returns the bounding box for the bezier shape defined by the given control points"
  bez-corner-box(pts).to-box()
end

fun bezier-snap-trans(pts :: List<IM_AUX.Position>) -> M.Vector:
  doc: "Returns the translation vector needed to snap the bezier shape defined by the given control points to the x and y axes"
  top-left = bez-corner-box(pts).top-left
  [vector: (-1 * top-left.x), (-1 * top-left.y)]
end

fun poly-corner-box(pts :: List<List<Number>>) -> CornerBox:
  doc: "Returns the bounding CornerBox for the given polygon"
  cornerbox(IM_AUX.posn(min(pts.first), min(pts.get(1))), IM_AUX.posn(max(pts.first), max(pts.get(1))))
end
