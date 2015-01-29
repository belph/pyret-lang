## image_auxiliary_datatypes.arr
## -------------------
## Blame issues on:
##  Philip Blair (GitHub: belph)
##  peblairman@gmail.com

## Description:
## ------------
## Provides data definitions
##  for the image library which
##  are not to be exported with
##  the final library

provide {
  posn : posn,
  box  : box,
  ivl  : ivl
} end
provide-types *

# Represents Position Data
data Position:
  | posn(x :: Number,
         y :: Number)
end

# Represents a rectangular size
data Box:
  | box(width :: Number,
      height :: Number)
end

# Represents a range of numbers (i.e. coordinates on one axis)
data Interval:
  | ivl(start :: Number, last :: Number)
    with:
    shift(self, n :: Number):
      ivl(self.start + n, self.last + n)
    end,
    comb(self, other :: Interval):
      doc: "Combines two intervals into one interval containing both"
      ivl(num-min(self.start, other.start), num-max(self.last, other.last))
    end,
    intersect(self, other :: Interval):
      doc: "Returns the intersection of the two intervals"
      ivl(num-max(self.start, other.start), num-min(self.last, other.last))
    end,
    len(self):
      self.last - self.start
    end
where:
  a = ivl(1,10)
  a.shift(2) is ivl(3,12)
  a.shift(-2) is ivl(-1,8)
  a.comb(ivl(5,15)) is ivl(1,15)
  a.comb(ivl(-7,9)) is ivl(-7,10)
  a.comb(ivl(-7,15)) is ivl(-7,15)
  a.intersect(ivl(5,15)) is ivl(5,10)
  a.intersect(ivl(-7,9)) is ivl(1,9)
  a.intersect(ivl(-7,15)) is ivl(1,10)
  a.len() is 9
end