import shared-gdrive("matricies", "0ByJ_bK5RkycfcVV1OU9XN2M5bUk") as mtx

#########################
# PYRET IMAGE DATATYPES #
#########################

### USED PREDICATES

# in-color-range:
# Predicate to check whether or not
#   the given number is within the
#   range [0, 255]
fun in-color-range(n :: Number) -> Boolean:
  (0 <= n) and (n <= 255)
where:
  in-color-range(-1) is false
  in-color-range(100) is true
  in-color-range(266) is false
end

# greater-than-zero
# Predicate to make sure that the
#   given number is larger than 0.
fun greater-than-zero(n :: Number) -> Boolean:
  0 < n
end

# nonzero-nat
# Predicate to check if the
#   given number is a Natural
#   number greater than 0.
fun nonzero-nat(n :: Number) -> Boolean:
  (0 < n) and num-is-integer(n)
end

### DATA DEFINITIONS

# Represents Color Data
# TODO: Default alpha to 255?
data Color:
  | color(red :: Number%(in-color-range),
          blue :: Number%(in-color-range),
          green :: Number%(in-color-range),
          alpha :: Number%(in-color-range))
end

# Represents Position Data
data Position:
  | posn(x :: Number,
         y :: Number)
end

# Represents the Image Mode.
# Equivalent to Racket's 'solid
#   'outline.
data Mode:
  | outline
  | solid
end

# The Image Data Type

# IMAGE DATATYPE LAYOUT:
# - Primitives (circle, star, square, etc.)
#    + Same as 2htdp library
# - Compound Image
#    + A Binary Tree datatype which represents
#        one image on top of another, centered
#        at the given point
# - Orthoganally Transformed Images (rotation, reflection)
#    + Represents an image with a size-preserving
#        transformation


data Image:
  # circle():
  # Represents a Circle with the
  #   given radius, mode, and color.
  | circle(radius :: Number%(greater-than-zero),
           mode   :: Mode,
           color  :: Color)
  # ellipse()
  # Represents an ellips with the
  #   given width, height, mode, and
  #   color.
  | ellipse(width  :: Number%(greater-than-zero),
            height :: Number%(greater-than-zero),
            mode   :: Mode,
            color  :: Color)
  # line()
  # Represents a line going from point
  #   (0,0) to point (x,y) of the given color
  | line(x     :: Number,
         y     :: Number,
         color :: Color)
  # text()
  # Represents the given string
  #   of text, using the given
  #   font size and color
  | text(string :: String,
         size   :: Number%(greater-than-zero),
         color  :: Color)
  # text-font()
  # Represents the given string
  #   of text with the given font
  #   specification
  | text-font(string      :: String,
              size        :: Number%(greater-than-zero),
              color       :: Color,
              font-face   :: String, #TODO: Font Face datatype?
              font-family :: String, #TODO: Font Family datatype?
              style       :: String,
              weight      :: String,
              underline   :: Boolean)
  # triangle()
  # Represents an upward-pointing
  #   equilateral triangle
  | triangle(side-length :: Number%(greater-than-zero),
             mode        :: Mode,
             color       :: Color)
  # right-triangle()
  # Represents a right triangle with
  #   its right angle at the bottom
  #   right and with leg lengths
  #   side-length1 and side-length2
  | right-triangle(side-length1 :: Number%(greater-than-zero),
                   side-length2 :: Number%(greater-than-zero),
                   mode         :: Mode,
                   color        :: Color)
  # isosceles-triangle()
  # Represents an isosceles triangle,
  #   where the sides are of length 
  #   side-length, and the angle
  #   between the two equal-length
  #   sides is angle-c
  | isosceles-triangle(side-length :: Number%(greater-than-zero),
                       angle-c     :: Number, # Degrees
                       mode        :: Mode,
                       color       :: Color)
  # triangle-sss()
  # Represents a triangle with the
  #   given side lengths
  | triangle-sss(side-a :: Number%(greater-than-zero),
                 side-b :: Number%(greater-than-zero),
                 side-c :: Number%(greater-than-zero),
                 mode   :: Mode,
                 color  :: Color)
  # triangle-ass()
  # Represents a triangle with the
  #   given angle and two sides.(A-S-S)
  | triangle-ass(angle-a :: Number, # Degrees
                 side-b  :: Number%(greater-than-zero),
                 side-c  :: Number%(greater-than-zero),
                 mode    :: Mode,
                 color   :: Color)
  # triangle-sas()
  # Represents a triangle with the
  #   given angle and two sides.(S-A-S)
  | triangle-sas(side-a  :: Number%(greater-than-zero),
                 angle-b :: Number, # Degrees
                 side-c  :: Number%(greater-than-zero),
                 mode    :: Mode,
                 color   :: Color)
  # triangle-ssa()
  # Represents a triangle with the
  #   given angle and two sides.(S-S-A)
  | triangle-ssa(side-a  :: Number%(greater-than-zero),
                 side-b  :: Number%(greater-than-zero),
                 angle-c :: Number, # Degrees
                 mode    :: Mode,
                 color   :: Color)
  # triangle-aas()
  # Represents a triangle with the
  #   given angle and two sides.(A-A-S)
  | triangle-aas(angle-a :: Number, # Degrees
                 angle-b :: Number, # Degrees
                 side-c  :: Number%(greater-than-zero),
                 mode    :: String,
                 color   :: Color)
  # triangle-asa()
  # Represents a triangle with the
  #   given angle and two sides.(A-S-A)
  | triangle-asa(angle-a :: Number, # Degrees
                 side-b  :: Number%(greater-than-zero),
                 angle-c :: Number, # Degrees
                 mode    :: Mode,
                 color   :: Color)
  # triangle-saa()
  # Represents a triangle with the
  #   given angle and two sides.(S-A-A)
  | triangle-saa(side-a  :: Number%(greater-than-zero),
                 angle-b :: Number, # Degrees
                 angle-c :: Number, # Degrees
                 mode    :: Mode,
                 color   :: Color)
  # square()
  # Represents a square of the given side length
  | square(side-length :: Number%(greater-than-zero),
           mode        :: Mode,
           color       :: Color)
  # rectangle()
  # Represents a rectangle with the
  #   given two side lengths
  | rectangle(width  :: Number%(greater-than-zero),
              height :: Number%(greater-than-zero),
              mode   :: Mode,
              color  :: Color)
  # rhombus()
  # Represents a rhombus with the given
  #   side length and the given top/bottom
  #   angle
  | rhombus(side-length :: Number%(greater-than-zero),
            angle       :: Number, # Degrees
            mode        :: Mode,
            color       :: Color)
  # star()
  # Represents a 5-pointed star of
  #   the given side length
  | star(side-length :: Number%(greater-than-zero),
         mode        :: Mode,
         color       :: Color)
  # radial-star()
  # Represents a star with the given
  #   amount of points; the outer
  #   points will be a distance of
  #   outer from the center, the inner
  #   a distance of inner
  | radial-star(point-count :: Number%(nonzero-nat),
                outer       :: Number%(greater-than-zero),
                inner       :: Number%(greater-than-zero),
                mode        :: Mode,
                color       :: Color)
  # star-sized()
  # Same as radial-star().
  | star-sized(point-count :: Number%(nonzero-nat),
               outer       :: Number%(greater-than-zero),
               inner       :: Number%(greater-than-zero),
               mode        :: Mode,
               color       :: Color)
  # star-polygon()
  # Represents a regular star polygon,
  #   with every step-th vertex connected
  | star-polygon(side-length :: Number%(greater-than-zero),
                 point-count :: Number%(nonzero-nat),
                 step        :: Number%(nonzero-nat),
                 mode        :: Mode,
                 color       :: Color)
  # regular-polygon()
  # Represents a regular polygon
  #   with the given number of sides.
  | regular-polygon(length :: Number%(greater-than-zero),
                    count  :: Number%(nonzero-nat),
                    mode   :: Mode,
                    color  :: Color)
  # empty-image()
  # Represents an empty image
  #   of the given size.
  | empty-image(x :: Number%(greater-than-zero),
                y :: Number%(greater-than-zero))
  # compound-image()
  # Represents the first Image
  #   placed on top of the second
  #   one, centered at the given
  #   position
  | compound-image(top    :: Image,
                   at     :: Position,
                   bottom :: Image)
  # rotated()
  # Represents the rotation of the
  #   given image by the given angle
  | rotated(image :: Image,
            angle :: Number) # Degrees
  # reflect-x()
  # Represents the reflection of
  #   the given image about the x-axis
  | reflect-x(image :: Image)
  # reflect-y()
  # Represents the reflection of the
  #   given image about the y-axis
  | reflect-y(image :: Image)
end

pi = 2 * num-asin(1)

fun near(a :: Number, b :: Number):
  num-abs(a - b) < num-expt(10, -3)
end

# rotation-matrix
# Returns the rotation
#  matrix corrisponding
#  to the given angle
fun rotation-matrix(theta :: Number) -> Matrix:
  [list: [list: num-cos(theta), (-1 * (num-sin(theta)))]
         [list: num-sin(theta), num-cos(theta)]]
end


fun place-image(i1 :: Image, x :: Number, y :: Number, i2 :: Image) -> Image:
  compound-image(i1, posn(x, y), i2)
end


