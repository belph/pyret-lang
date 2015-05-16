#lang at-exp s-exp "../../image-modlang.rkt"
@;
@; HEAVILY adapted from the 2htdp docs
@;
@(require "../../scribble-api.rkt" "../abbrevs.rkt"
          racket/base
          scribble/core scribble/html-properties
          scribble/base
          "../../image-syntax.rkt")

@(define I (a-id "Image" (xref "pyret-image" "Image")))

@docmodule["pyret-image"]{
@section{Construction Tape Ahead}
The ultimate goal of this library is to replicate the functionality
of Racket's @pyret{2htdp/image} library. This is a work in progress!
Consider everything on this page subject to change.

@section{Images}
@function["circle"]{
Constructs a circle with the given radius, mode, and color.
@image-examples[#:racket (circle 30 'outline 'red)
                         "circle(30, outline, red)"
                         "circle(20, solid, blue)"]
}

@function["ellipse"]{
Constructs an ellipse with the given width, height, mode, and color.
@image-examples[#:racket (ellipse 60 30 'outline 'black) 
                         "ellipse(60, 30, outline, black)"
                         "ellipse(30, 60, solid, blue)"]
 }

@function["line"]{
Constructs an image representing a line segment that connects the points (0,0)
to (x,y)
@image-examples[#:racket (line 30 30 'black)
                         "line(30, 30, black)"
                         #:racket (line -30 30 "red")
                         "line(-30, 20, red)"
                         "line(30, -20, red)"]
}

@function["triangle"]{Constructs a upward-pointing equilateral triangle. 
 The @pyret{side-length} argument determines the length of the side of the triangle.
 @image-examples[#:racket (triangle 40 'solid 'tan)
                          "triangle(40, solid, tan)"]
 }

@function["right-triangle"]{Constructs a triangle with a right angle where the two sides adjacent to the 
 right angle have lengths side-length1 and side-length2.
 @image-examples[#:racket (right-triangle 36 48 'solid 'black)]{right-triangle(36, 48, solid, black)}
 }

@function["isosceles-triangle"]{Creates a triangle with two equal-length sides, of length @pyret{side-length} where 
 the angle between those sides is @pyret{angle}. The third leg is straight, horizontally. 
 If the angle is less than 180, then the triangle will point up and if the @pyret{angle} is more, 
 then the triangle will point down.
 @image-examples[#:racket (isosceles-triangle 200 170 'solid 'seagreen)
                          "isosceles-triangle(200, 170, solid, seagreen)"
                          "isosceles-triangle(60, 30, solid, aquamarine)"
                          "isosceles-triangle(60, 330, solid, lightseagreen)"]
 }

@function["triangle-sss"]{Creates a triangle where the side lengths a, b, and, c are given by @pyret{side-length-a}, 
 @pyret{side-length-b}, and, @pyret{side-length-c} respectively.
 @image-examples[#:racket (triangle/sss 40 60 80 'solid 'seagreen)
                          "triangle-sss(40, 60, 80, solid, seagreen)"
                          "triangle-sss(80, 40, 60, solid, aquamarine)"
                          "triangle-sss(80, 80, 40, solid, lightseagreen)"]
 }

@function["triangle-ass"]{Creates a triangle where the angle A and side length a and b, are given by @pyret{angle-a},
@pyret{side-length-b}, and, @pyret{side-length-c} respectively.

@image-examples[#:racket (triangle/ass 10 60 100 'solid 'seagreen)
                         "triangle-ass(10, 60, 100, solid, seagreen)"
                         "triangle-ass(90, 60, 100, solid, aquamarine)"
                         "triangle-ass(130, 60, 100, solid, lightseagreen)"]
}

@function["triangle-sas"]{Creates a triangle where the side length a, angle B, and, side length c given by
@pyret{side-length-a}, @pyret{angle-b}, and, @pyret{side-length-c} respectively.

@image-examples[#:racket (triangle/sas 60 10 100 'solid 'seagreen)
                         "triangle-sas(60, 10, 100, solid, seagreen)"
                         "triangle-sas(60, 90, 100, solid, aquamarine)"
                         "triangle-sas(60, 130, 100, solid, lightseagreen)"]
}

@function["triangle-ssa"]{Creates a triangle where the side length a, side length b, and, angle c given by
@pyret{side-length-a}, @pyret{side-length-b}, and, @pyret{angle-c} respectively.

@image-examples[#:racket (triangle/ssa 60 100 10 'solid 'seagreen)
                         "triangle-ssa(60, 100, 10, solid, seagreen)"
                         "triangle-ssa(60, 100, 90, solid, aquamarine)"
                         "triangle-ssa(60, 100, 130, solid, lightseagreen)"]
}

@function["triangle-aas"]{Creates a triangle where the angle A, angle B, and, side length c given by
@pyret{angle-a}, @pyret{angle-b}, and, @pyret{side-length-c} respectively.

@image-examples[#:racket (triangle/aas 10 40 200 'solid 'seagreen)
                         "triangle-aas(10, 40, 200, solid, seagreen)"
                         "triangle-aas(90, 40, 200, solid, aquamarine)"
                         "triangle-aas(130, 40, 40, solid, lightseagreen)"]
}

@function["triangle-asa"]{Creates a triangle where the angle A, side length b, and, angle C given by
@pyret{angle-a}, @pyret{side-length-b}, and, @pyret{angle-c} respectively.

@image-examples[#:racket (triangle/asa 10 200 40 'solid 'seagreen)
                         "triangle-asa(10, 200, 40, solid, seagreen)"
                         "triangle-asa(90, 200, 40, solid, aquamarine)"
                         "triangle-asa(130, 40, 40, solid, lightseagreen)"]
}

@function["triangle-saa"]{Creates a triangle where the side length a, angle B, and, angle C given by
@pyret{side-length-a}, @pyret{angle-b}, and, @pyret{angle-c} respectively.

@image-examples[#:racket (triangle/saa 200 10 40 'solid 'seagreen)
                         "triangle-saa(200, 10, 40, solid, seagreen)"
                         "triangle-saa(200, 90, 40, solid, aquamarine)"
                         "triangle-saa(40, 130, 40, solid, lightseagreen)"]
}

@function["square"]{Constructs a square.
                    
@image-examples[#:racket (square 40 'solid 'slateblue)
                         "square(40, solid, slateblue)"
                         "square(50, outline, darkmagenta)"]
}

@function["rectangle"]{Constructs a rectangle with the given width, height, mode, and color.
                       
@image-examples[#:racket (rectangle 40 20 'outline 'black)
                         "rectangle(40, 20, outline, black)"
                         "rectangle(20, 40, solid, blue)"]
}

@function["rhombus"]{Constructs a four sided polygon with all equal sides and thus where opposite angles are equal
to each other. The top and bottom pair of angles is angle and the left and right are @pyret{180 - angle}.

@image-examples[#:racket (rhombus 40 45 'solid 'magenta)
                         "rhombus(40, 45, solid, magenta)"
                         "rhombus(80, 150, solid, mediumpurple)"]
}

@function["star"]{Constructs a start with five points. The @pyret{side-length} argument determines the side length
of the enclosing polygon.

@image-examples[#:racket (star 40 'solid 'gray)
                         "star(40, solid, gray)"]
}

@function["star-polygon"]{Constructs an arbitrary regular star polygon (a generalization of the regular polygons).
The polygon is enclosed by a regular polygon with @pyret{side-count} sides each @pyret{side-length} long. The
polygon is actually constructed by going from vertex to vertex around the regular polygon, but connecting every
@pyret{step-count}-th vertex (i.e., skipping every @pyret{step-count - 1} vertices).

For example, if @pyret{side-count} is @pyret{5} and @pyret{step-count} is @pyret{2}, then this function produces a
shape just like @pyret{star}.

@image-examples[#:racket (star-polygon 40 5 2 'solid 'seagreen)
                         "star-polygon(40, 5, 2, solid, seagreen)"
                         "star-polygon(40, 7, 3, outline, darkred)"
                         "star-polygon(20, 10, 3, solid, cornflowerblue)"]
}

@function["radial-star"]{Constructs a star-like polygon where the star is specified by two radii and a number of
points. The first radius determines where the points begin, the second determines where they end, and the
@pyret{point-count} argument determines how many points the star has.

@image-examples[#:racket (radial-star 8 8 64 'solid 'darkslategray)
                         "radial-star(8, 8, 64, solid, darkslategray)"
                         "radial-star(32, 30, 40, outline, black)"]
}

@function["regular-polygon"]{Constructs a regular polygon with @pyret{side-count} sides.

@image-examples[#:racket (regular-polygon 50 3 'outline 'red)
                         "regular-polygon(50, 3, outline, red)"
                         "regular-polygon(40, 4, outline, blue)"
                         "regular-polygon(20, 8, solid, red)"]

}

@section["Overlaying images"]

@function["overlay"]{Overlays all of its arguments building a single image. The first argument goes on top of the
second argument, which goes on top of the third argument, etc. The images are all lined up on their centers.

@image-examples[#:racket (overlay (rectangle 30 60 'solid 'orange)
                                  (ellipse 60 30 'solid 'purple))
                         "overlay(rectangle(30, 60, solid, orange), 
                                  ellipse(60, 30, solid, purple))"
                         "overlay(ellipse(10, 10, solid, red),
                                  overlay(ellipse(20, 20, solid, black),
                                  overlay(ellipse(30, 30, solid, red),
                                  overlay(ellipse(40, 40, solid, black),
                                  overlay(ellipse(50, 50, solid, red),
                                  ellipse(60, 60, solid, black))))))"]
}



}
