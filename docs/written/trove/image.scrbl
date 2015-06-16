#lang at-exp s-exp "../../image-modlang.rkt"
@;
@; HEAVILY adapted from the 2htdp docs
@;
@(require "../../scribble-api.rkt" "../abbrevs.rkt"
          racket/base
          scribble/core scribble/html-properties
          scribble/base
          "../../image-syntax.rkt")

@(define I (a-id "Image"))
@(define XP (a-id "X-Place" (xref "pyret-image" "X-Place")))
@(define YP (a-id "Y-Place" (xref "pyret-image" "Y-Place")))

@(append-gen-docs
  `(module "pyret-image"
     (path "src/js/base/runtime-anf.js")
     (data-spec 
      (name "Image")
      (variants ("polygon")) ;; Not going to be listed anyway
      (shared
        ((method-spec
         (name "flip-horizontal")
         (arity 1)
         (args ("self"))
         (return ,I)
         (contract (a-arrow ,I ,I)))
        (method-spec
         (name "flip-vertical")
         (arity 1)
         (args ("self"))
         (return ,I)
         (contract (a-arrow ,I ,I)))
        (method-spec
         (name "scale-x")
         (arity 2)
         (args ("self" "scale"))
         (return ,I)
         (contract (a-arrow ,I ,N ,I)))
        (method-spec
         (name "scale-y")
         (arity 2)
         (args ("self" "scale"))
         (return ,I)
         (contract (a-arrow ,I ,N ,I)))
        (method-spec
         (name "scale-xy")
         (arity 3)
         (args ("self" "x-scale" "y-scale"))
         (return ,I)
         (contract (a-arrow ,I ,N ,N ,I)))
        (method-spec
         (name "scale")
         (arity 2)
         (args ("self" "scale"))
         (return ,I)
         (contract (a-arrow ,I ,N ,I)))
        (method-spec
         (name "rotate")
         (arity 2)
         (args ("self" "theta"))
         (return ,I)
         (contract (a-arrow ,I ,N ,I)))
        (method-spec
         (name "crop")
         (arity 5)
         (args ("self" "x" "y" "width" "height"))
         (return ,I)
         (contract (a-arrow ,I ,N ,N ,N ,N ,I)))
        (method-spec
         (name "crop-align")
         (arity 5)
         (args ("self" "x-place" "y-place" "width" "height"))
         (return ,I)
         (contract (a-arrow ,I ,XP ,YP ,N ,N ,I)))
        (method-spec
         (name "width")
         (arity 1)
         (args ("self"))
         (return ,N)
         (contract (a-arrow ,I ,N)))
        (method-spec
         (name "height")
         (arity 1)
         (args ("self"))
         (return ,N)
         (contract (a-arrow ,I ,N)))
        (method-spec
         (name "put-pinhole")
         (arity 3)
         (args ("self" "x" "y"))
         (return ,I)
         (contract (a-arrow ,I ,N ,N ,I)))
        (method-spec
         (name "clear-pinhole")
         (arity 1)
         (args ("self"))
         (return ,I)
         (contract (a-arrow ,I ,I)))
        (method-spec
         (name "pinhole-x")
         (arity 1)
         (args ("self"))
         (return ,A)
         (contract (a-arrow ,I ,A)))
        (method-spec
         (name "pinhole-y")
         (arity 1)
         (args ("self"))
         (return ,A)
         (contract (a-arrow ,I ,A)))
        (method-spec
         (name "center-pinhole")
         (arity 1)
         (args ("self"))
         (return ,I)
         (contract (a-arrow ,I ,I))))))))


@(define (image-method name #:args (args #f) #:return (return #f) #:contract (contract #f) . body)
   (apply method-doc "Image" "polygon" name #:alt-docstrings "" #:args args #:return return #:contract contract body))

@docmodule["pyret-image"]{
@section{Construction Tape Ahead}
The ultimate goal of this library is to replicate the functionality
of Racket's @pyret{2htdp/image} library. This is a work in progress!
Consider everything on this page subject to change.

@section{Basic Images}
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
                         line(30, 30, black)
                         #:racket (line -30 30 "red")
                         "line(-30, 20, red)"
                         "line(30, -20, red)"]
}

@function["add-line"]{
Adds a line to the image image, starting from the point (@pyret{x1},@pyret{y1}) and
going to the point (@pyret{x2},@pyret{y2}). Unlike @pyret{add-line-to-scene}, if the line passes
outside of @pyret{image}, the image gets larger to accommodate the line.
@image-examples[#:racket (add-line (ellipse 40 40 'outline 'maroon) 0 40 40 0 'maroon)
                         "add-line(ellipse(40, 40, outline, maroon), 0, 40, 40, 0, maroon)"
                         "add-line(rectangle(40, 40, solid, gray), -10, 50, 50, -10, maroon)"
                "add-line(rectangle(100, 100, solid, darkolivegreen),25, 25, 75, 75,
                          pen(goldenrod, 30, style-solid, cap-round, join-round))"]}

@function["add-curve"]{
Adds a curve to image, starting at the point (@pyret{x1},@pyret{y1}), and ending at the point (@pyret{x2},@pyret{y2}).

The @pyret{angle1} and @pyret{angle2} arguments specify the angle that the curve has as it leaves the
initial point and as it reaches the final point, respectively.

The @pyret{pull1} and @pyret{pull2} arguments control how long the curve tries to stay with that angle.
Larger numbers mean that the curve stays with the angle longer.

Unlike @pyret{add-curve-to-scene}, if the line passes outside of @pyret{image}, the image gets larger to
accommodate the curve.
@image-examples[#:racket (add-curve (rectangle 100 100 'solid 'black)
                                    20 20 0 1/3
                                    80 80 0 1/3
                                    'white)
                "add-curve(rectangle(100, 100, solid, black),
                           20, 20, 0, 1/3,
                           80, 80, 0, 1/3, white)"
                "add-curve(rectangle(100, 100, solid, black),
                           20, 20, 0, 1,
                           80, 80, 0, 1, white)"
                "add-curve(add-curve(rectangle(40, 100, solid, black),
                                     20, 10, 180, 1/2,
                                     20, 90, 180, 1/2,
                                     pen(white, 4, style-solid,
                                         cap-round, join-round)),
                           20, 10, 0, 1/2,
                           20, 90, 0, 1/2, pen(white, 4, style-solid,
                                               cap-round, join-round))"
                "add-curve(rectangle(100, 100, solid, black),
                           -20, -20, 0, 1, 120, 120, 0, 1, red)"]}

@section{Polygons}

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

@function["polygon"]{Constructs a polygon connecting the given vertices.

@image-examples[#:racket (polygon (list (make-posn 0 0)
                                        (make-posn -10 20)
                                        (make-posn 60 0)
                                        (make-posn -10 -20))
                                  "solid"
                                  "burlywood")
"polygon([list: posn(0, 0), posn(-10, 20), posn(60, 0), posn(-10, -20)],
         solid, burlywood)"
"polygon([list: posn(0, 0), posn(0, 40), posn(20, 40), posn(20, 60),
                posn(40, 60), posn(40, 20), posn(20, 20), posn(20, 0)], solid, plum)"
"underlay(rectangle(80, 80, solid, mediumseagreen),
          polygon([list: posn(0, 0), posn(50, 0), posn(0, 50), posn(50, 50)], outline,
                  pen(darkslategray, 10, style-solid, cap-round, join-round)))"
"underlay(rectangle(80, 80, solid, mediumseagreen),
          polygon([list: posn(0, 0), posn(50, 0), posn(0, 50), posn(50, 50)], outline,
                  pen(darkslategray, 10, style-solid, cap-projecting, join-miter)))"]}

@function["add-polygon"]{
Adds a closed polygon to the image @pyret{image}, with vertices as specified in @pyret{posns}
(relative to the top-left corner of @pyret{image}). Unlike @pyret{add-polygon-to-scene}, if the
polygon goes outside the bounds of @pyret{image}, the result is enlarged to accommodate both.

@image-examples[#:racket (add-polygon (rectangle 55 34 "solid" "light blue")
                                      (list (make-posn 50 10)
                                            (make-posn 20 15)
                                            (make-posn 50 20)
                                            (make-posn 10 25)
                                            (make-posn 35 30))
                                      "outline" "red")
"add-polygon(rectangle(55, 34, solid, lightblue),
             [list: posn(50, 10), posn(20, 15), posn(50, 20), posn(10, 25), posn(35, 30)], outline, red)"
"add-polygon(square(65, solid, lightblue),
             [list: posn(30, -20), posn(50, 50), posn(-20, 30)], solid, forestgreen)"
"add-polygon(square(180, solid, yellow),
             [list: posn(109, 160), posn(26, 148), posn(46, 36),
                    posn(93, 44), posn(89, 68), posn(122, 72)], outline, darkblue)"
"add-polygon(square(50, solid, lightblue),
             [list: posn(25, -10), posn(60, 25), posn(25, 60), posn(-10, 25)], solid, pink)"]}

@function["add-polygon-to-scene"]{
Adds a closed polygon to the image @pyret{image}, with vertices as specified in @pyret{posns}
(relative to the top-left corner of @pyret{image}). Unlike @pyret{add-polygon}, if the
polygon goes outside the bounds of @pyret{image}, the result is clipped to @pyret{image}.

@image-examples[#:racket (scene+polygon (rectangle 55 34 "solid" "light blue")
                                        (list (make-posn 50 10)
                                              (make-posn 20 15)
                                              (make-posn 50 20)
                                              (make-posn 10 25)
                                              (make-posn 35 30))
                                        "outline" "red")
"add-polygon-to-scene(rectangle(55, 34, solid, lightblue),
                      [list: posn(50, 10), posn(20, 15), posn(50, 20),
                             posn(10, 25), posn(35, 30)], outline, red)"
"add-polygon-to-scene(square(65, solid, lightblue),
                      [list: posn(30, -20), posn(50, 50),
                             posn(-20, 30)], solid, forestgreen)"
"add-polygon-to-scene(square(180, solid, yellow),
                      [list: posn(109, 160), posn(26, 148), posn(46, 36),
                             posn(93, 44), posn(89, 68), posn(122, 72)],
                outline, darkblue)"
"add-polygon-to-scene(square(50, solid, lightblue),
                      [list: posn(25, -10), posn(60, 25),
                             posn(25, 60), posn(-10, 25)], solid, pink)"]}

@section{Overlaying images}

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

@function["overlay-align"]{Overlays all of its image arguments, much like the @pyret{overlay} function, but using 
                           @pyret{x-place} and @pyret{y-place} to determine where the images are lined up. For example, 
                           if @pyret{x-place} is @pyret{x-center}and @pyret{y-place} is @pyret{y-center}, then the images are 
                           lined up on their centers.
                           
                           @image-examples[#:racket (overlay/align "left" "middle"
                                                                   (rectangle 30 60 "solid" "orange")
                                                                   (ellipse 60 30 "solid" "purple"))
                                           "overlay-align(x-left, y-center, rectangle(30, 60, solid, orange),
                                                                ellipse(60, 30, solid, purple))"
                                           "overlay-align(x-right, y-bottom, rectangle(20, 20, solid, silver),
                                                          overlay-align(x-right, y-bottom, rectangle(30, 30, solid, seagreen),
                                                          overlay-align(x-right, y-bottom, rectangle(40, 40, solid, silver),
                                                          rectangle(50, 50, solid, seagreen))))"]}

@function["overlay-offset"]{Just like @pyret{overlay}, this function lines up its image arguments on top of each other. 
                            Unlike @pyret{overlay}, it moves @pyret{i2} by @pyret{x} pixels to the right and 
                            @pyret{y} down before overlaying them.
                                      
                            @image-examples[#:racket (overlay/offset (circle 40 "solid" "red")
                                                                     10 10
                                                                     (circle 40 "solid" "blue"))
                                                     "overlay-offset(circle(40, solid, red), 10, 10, circle(40, solid, blue))"
                                                     "overlay-offset(overlay-offset(rectangle(60, 20, solid, black),
                                                                                   -50, 0, circle(20, solid, darkorange)), 
                                                                    70, 0, circle(20, solid, darkorange))"
                                                     "overlay-offset(overlay-offset(circle(30, solid, rgba-color(0, 150, 0, 127)),
                                                                                   26, 0, circle(30, solid, rgba-color(0, 0, 255, 127))), 
                                                                    0, 26, circle(30, solid, rgba-color(200, 0, 0, 127)))"]}


@function["overlay-align-offset"]{Overlays image @pyret{i1} on top of @pyret{i2}, using @pyret{x-place} and @pyret{y-place} 
                                  as the starting points for the overlaying, and then adjusts @pyret{i2} by @pyret{x} to the 
                                  right and @pyret{y} pixels down.

                                  This function combines the capabilities of @pyret{overlay-align} and @pyret{overlay-offset}.
                                  
                                  @image-examples[#:racket (overlay/align/offset
                                                            "right" "bottom"
                                                            (star-polygon 20 20 3 "solid" "navy")
                                                            10 10
                                                            (circle 30 "solid" "cornflowerblue"))
                                                           "overlay-align-offset(x-right, y-bottom, star-polygon(20, 20, 3, solid, navy),
                                                                                10, 10, circle(30, solid, cornflowerblue))"
                                                           "overlay-align-offset(x-left, y-bottom, star-polygon(20, 20, 3, solid, navy),
                                                                                -10, 10, circle(30, solid, cornflowerblue))"]}

@function["overlay-xy"]{Constructs an image by overlaying @pyret{i1} on top of @pyret{i2}. The images are initially lined up 
                        on their upper-left corners and then @pyret{i2} is shifted to the right by @pyret{x} pixels to and down 
                        by @pyret{y} pixels.

                        This is the same as @pyret{underlay-xy(i2, (-1 * x), (-1 * y), i1)}.

                        See also @pyret{overlay-offset} and @pyret{underlay-offset}.
                        
                        @image-examples[#:racket (overlay/xy (rectangle 20 20 "outline" "black")
                                                             20 0
                                                             (rectangle 20 20 "outline" "black"))
                                                 "overlay-xy(rectangle(20, 20, outline, black), 20, 0, rectangle(20, 20, outline, black))"
                                                 "overlay-xy(rectangle(20, 20, solid, red), 10, 10, rectangle(20, 20, solid, black))"
                                                 "overlay-xy(rectangle(20, 20, solid, red), -10, -10, rectangle(20, 20, solid, black))"
                                                 "overlay-xy(overlay-xy(ellipse(40, 40, outline, black), 10, 15,
                                                                        ellipse(10, 10, solid, forestgreen)), 
                                                             20, 15, ellipse(10, 10, solid, forestgreen))"]}

@function["underlay"]{Underlays its arguments building a single image.
                      
                      It behaves like overlay, but with the arguments in the reverse order. 
                      That is, the first argument goes underneath of the second argument. 
                      The images are all lined up on their centers.
                      
                      @image-examples[#:racket (underlay (rectangle 30 60 "solid" "orange")
                                                         (ellipse 60 30 "solid" "purple"))
                                               "underlay(rectangle(30, 60, solid, orange), 
                                                         ellipse(60, 30, solid, purple))"
                                               "underlay(ellipse(10, 60, solid, red),
                                                         underlay(ellipse(20, 50, solid, black),
                                                         underlay(ellipse(30, 40, solid, red),
                                                         underlay(ellipse(40, 30, solid, black),
                                                         underlay(ellipse(50, 20, solid, red),
                                                                  ellipse(60, 10, solid, black))))))"]}

@function["underlay-align"]{Underlays its image arguments, much like the @pyret{underlay} function, 
                            but using @pyret{x-place} and @pyret{y-place} to determine where the 
                            images are lined up. For example, if @pyret{x-place} is @pyret{x-middle} 
                            and @pyret{y-place} is @pyret{y-center}, then the images are lined up on their centers.
                            
                            @image-examples[#:racket (underlay/align "left" "middle"
                                                                     (rectangle 30 60 "solid" "orange")
                                                                     (ellipse 60 30 "solid" "purple"))
                                               "underlay-align(x-left, y-center, rectangle(30, 60, solid, orange),
                                                                                 ellipse(60, 30, solid, purple))"
                                               "underlay-align(x-right, y-top, rectangle(50, 50, solid, seagreen),
                                                              underlay-align(x-right, y-top, rectangle(40, 40, solid, silver),
                                                              underlay-align(x-right, y-top, rectangle(30, 30, solid, seagreen),
                                                                             rectangle(20, 20, solid, silver))))"]}

@function["underlay-offset"]{Just like @pyret{underlay}, this function lines up its first image argument underneath the second. 
                             Unlike @pyret{underlay}, it moves @pyret{i2} by @pyret{x} pixels to the right and @pyret{y} 
                             down before underlaying them.
                             
                             @image-examples[#:racket (underlay/offset (circle 40 "solid" "red")
                                                                       10 10
                                                                       (circle 40 "solid" "blue"))
                                                      "underlay-offset(circle(40, solid, red), 10, 10, circle(40, solid, blue))"
                                                      "underlay-offset(circle(40, solid, gray), 0, -10,
                                                                       underlay-offset(circle(10, solid, navy), 
                                                                                       -30, 0, circle(10, solid, navy)))"
                                                      "underlay-offset(circle(40, solid, gray), 0, -10,
                                                                       underlay-offset(circle(10, solid, navy), 
                                                                                       30, 0, circle(10, solid, navy)))"
                                             "underlay-offset(circle(40, solid, gray), 0, 0, circle(10, solid, navy))"]}

@function["underlay-align-offset"]{Underlays image @pyret{i1} underneath @pyret{i2}, using @pyret{x-place} 
                                   and @pyret{y-place} as the starting points for the combination, and then 
                                   adjusts @pyret{i2} by @pyret{x} to the right and @pyret{y} pixels down.
                                   
                                   This function combines the capabilities of @pyret{underlay-align} and @pyret{underlay-offset}.
                                   
                                   @image-examples[#:racket (underlay/align/offset
                                                             "right" "bottom"
                                                             (star-polygon 20 20 3 "solid" "navy")
                                                             10 10
                                                             (circle 30 "solid" "cornflowerblue"))
                                                            "underlay-align-offset(x-right, y-bottom, star-polygon(20, 20, 3, solid, navy),
                                                                                   10, 10, circle(30, solid, cornflowerblue))"
                                                            "underlay-align-offset(x-right, y-bottom,
                                                               underlay-align-offset(x-left, y-bottom,
                                                                 underlay-align-offset(x-right, y-top,
                                                                   underlay-align-offset(x-left, y-top, 
                                                                                         rhombus(120, 90, solid, navy), 16, 16,
                                                                                         star-polygon(20, 11, 3, solid, cornflowerblue)),
                                                                                       -16, 16, 
                                                                                       star-polygon(20, 11, 3, solid, cornflowerblue)), 
                                                                                     16, -16,
                                                                                     star-polygon(20, 11, 3, solid, cornflowerblue)),
                                                                                   -16, -16,
                                                                                   star-polygon(20, 11, 3, solid, cornflowerblue))"]}

@function["underlay-xy"]{Constructs an image by underlaying @pyret{i1} underneath @pyret{i2}. The images are initially lined up 
                        on their upper-left corners and then @pyret{i2} is shifted to the right by @pyret{x} pixels to and down 
                        by @pyret{y} pixels.

                        This is the same as @pyret{overlay-xy(i2, (-1 * x), (-1 * y), i1)}.

                        See also @pyret{underlay-offset} and @pyret{overlay-offset}.
                        
                        @image-examples[#:racket (underlay/xy (rectangle 20 20 "outline" "black")
                                                              20 0
                                                              (rectangle 20 20 "outline" "black"))
                                                 "underlay-xy(rectangle(20, 20, outline, black), 20, 0, rectangle(20, 20, outline, black))"
                                                 "underlay-xy(rectangle(20, 20, solid, red), 10, 10, rectangle(20, 20, solid, black))"
                                                 "underlay-xy(rectangle(20, 20, solid, red), -10, -10, rectangle(20, 20, solid, black))"
                                                 "underlay-xy(underlay-xy(ellipse(40, 40, solid, gray), 10, 15,
                                                                        ellipse(10, 10, solid, forestgreen)), 
                                                             20, 15, ellipse(10, 10, solid, forestgreen))"]}

@function["beside"]{Constructs an image by placing @pyret{i1} and @pyret{i2} in a horizontal row, aligned along their centers.
                    @image-examples[#:racket (beside (ellipse 20 70 "solid" "gray")
                                                     (ellipse 20 50 "solid" "darkgray")
                                                     (ellipse 20 30 "solid" "dimgray")
                                                     (ellipse 20 10 "solid" "black"))
                                             "beside(ellipse(20, 70, solid, gray),
                                                     beside(ellipse(20, 50, solid, darkgray), 
                                                     beside(ellipse(20, 30, solid, dimgray), 
                                                     ellipse(20, 10, solid, black))))"]}

@function["beside-list"]{Similar to @pyret{beside}, except that it accepts a nonempty list of images.
                               
                         @image-examples[#:racket (beside (ellipse 20 70 "solid" "gray")
                                                          (ellipse 20 50 "solid" "darkgray")
                                                          (ellipse 20 30 "solid" "dimgray")
                                                          (ellipse 20 10 "solid" "black"))
                                                  "beside-list([list: ellipse(20, 70, solid, gray),
                                                                      ellipse(20, 50, solid, darkgray),
                                                                      ellipse(20, 30, solid, dimgray),
                                                                      ellipse(20, 10, solid, black)])"
                                                  "beside-list([list: ellipse(20, 70, solid, gray),
                                                                      ellipse(20, 50, solid, darkgray)])"
                                                  "beside-list([list: ellipse(20, 70, solid, gray),
                                                                      ellipse(20, 50, solid, darkgray),
                                                                      ellipse(20, 30, solid, dimgray)])"]}

@function["beside-align"]{Constructs an image by placing all of the argument images in a horizontal row, lined up as indicated by the
                          @pyret{y-place} argument. For example, if @pyret{y-place} is @pyret{y-center}, then the images are placed 
                          side by side with their centers lined up with each other.
                          
                          @image-examples[#:racket (beside/align "bottom"
                                                                 (ellipse 20 70 "solid" "lightsteelblue")
                                                                 (ellipse 20 50 "solid" "mediumslateblue")
                                                                 (ellipse 20 30 "solid" "slateblue")
                                                                 (ellipse 20 10 "solid" "navy"))
                                                   "beside-align(y-bottom, ellipse(20, 70, solid, lightsteelblue),
                                                                 beside-align(y-bottom, ellipse(20, 50, solid, mediumslateblue), 
                                                                 beside-align(y-bottom, ellipse(20, 30, solid, slateblue), 
                                                                 ellipse(20, 10, solid, navy))))"
                                                   "beside-align(y-top, ellipse(20, 70, solid, mediumorchid),
                                                                 beside-align(y-top, ellipse(20, 50, solid, darkorchid), 
                                                                 beside-align(y-top, ellipse(20, 30, solid, purple), 
                                                                 ellipse(20, 10, solid, indigo))))"]}

@function["beside-align-list"]{Similar to @pyret{beside-align}, except that it accepts a nonempty list of images.
                                          
                               @image-examples[#:racket (beside/align "bottom"
                                                                      (ellipse 20 70 "solid" "lightsteelblue")
                                                                      (ellipse 20 50 "solid" "mediumslateblue")
                                                                      (ellipse 20 30 "solid" "slateblue")
                                                                      (ellipse 20 10 "solid" "navy"))
                                                        "beside-align-list(y-bottom, [list: ellipse(20, 70, solid, lightsteelblue),
                                                                                            ellipse(20, 50, solid, mediumslateblue),
                                                                                            ellipse(20, 30, solid, slateblue),
                                                                                            ellipse(20, 10, solid, navy)])"]}

@function["above"]{Constructs an image by placing @pyret{i1} and @pyret{i2} in a vertical row, aligned along their centers.
                    @image-examples[#:racket (above (ellipse 70 20 "solid" "gray")
                                                    (ellipse 50 20 "solid" "darkgray")
                                                    (ellipse 30 20 "solid" "dimgray")
                                                    (ellipse 10 20 "solid" "black"))
                                             "above(ellipse(70, 20, solid, gray),
                                                    above(ellipse(50, 20, solid, darkgray), 
                                                    above(ellipse(30, 20, solid, dimgray), 
                                                    ellipse(10, 20, solid, black))))"
                                    "above(ellipse(70, 20, solid, gray), ellipse(50, 20, solid, darkgray))"
                                    "above(ellipse(70, 20, solid, gray),
                                           above(ellipse(50, 20, solid, darkgray),
                                                 ellipse(30, 20, solid, dimgray)))"]}

@function["above-list"]{Similar to @pyret{above}, except that it accepts a nonempty list of images.
                               
                        @image-examples[#:racket (above (ellipse 70 20 "solid" "gray")
                                                        (ellipse 50 20 "solid" "darkgray")
                                                        (ellipse 30 20 "solid" "dimgray")
                                                        (ellipse 10 20 "solid" "black"))
                                                  "above-list([list: ellipse(70, 20, solid, gray),
                                                                     ellipse(50, 20, solid, darkgray),
                                                                     ellipse(30, 20, solid, dimgray),
                                                                     ellipse(10, 20, solid, black)])"]}

@function["above-align"]{Constructs an image by placing all of the argument images in a vertical row, lined up as indicated by the
                         @pyret{x-place} argument. For example, if @pyret{x-place} is @pyret{x-middle}, then the images are placed 
                         above each other with their centers lined up.
                          
                         @image-examples[#:racket (above/align "right"
                                                               (ellipse 70 20 "solid" "gold")
                                                               (ellipse 50 20 "solid" "goldenrod")
                                                               (ellipse 30 20 "solid" "darkgoldenrod")
                                                               (ellipse 10 20 "solid" "sienna"))
                                                  "above-align(x-right, ellipse(70, 20, solid, gold),
                                                               above-align(x-right, ellipse(50, 20, solid, goldenrod), 
                                                               above-align(x-right, ellipse(30, 20, solid, darkgoldenrod), 
                                                               ellipse(10, 20, solid, sienna))))"
                                                  "above-align(x-left, ellipse(70, 20, solid, yellowgreen),
                                                               above-align(x-left, ellipse(50, 20, solid, olivedrab), 
                                                               above-align(x-left, ellipse(30, 20, solid, darkolivegreen), 
                                                               ellipse(10, 20, solid, darkgreen))))"]}

@function["above-align-list"]{Similar to @pyret{above-align}, except that it accepts a nonempty list of images.
                                         
                              @image-examples[#:racket (above/align "right"
                                                                    (ellipse 70 20 "solid" "gold")
                                                                    (ellipse 50 20 "solid" "goldenrod")
                                                                    (ellipse 30 20 "solid" "darkgoldenrod")
                                                                    (ellipse 10 20 "solid" "sienna"))
                                                       "above-align-list(x-right, [list: ellipse(70, 20, solid, gold),
                                                                                         ellipse(50, 20, solid, goldenrod),
                                                                                         ellipse(30, 20, solid, darkgoldenrod),
                                                                                         ellipse(10, 20, solid, sienna)])"]}

@section["Placing Images"]

@function["empty-scene"]{
Creates an empty scene, i.e., a white rectangle with a black outline.

@image-examples[#:racket (empty-scene 160 90)
                         "empty-scene(160, 90)"]}

@function["place-image"]{Places @pyret{image} onto @pyret{scene} with its center at the coordinates (x,y) 
                         and crops the resulting image so that it has the same size as @pyret{scene}. The 
                         coordinates are relative to the top-left of @pyret{scene}.
                         
                         @image-examples[#:racket (place-image (triangle 32 "solid" "red")
                                                               24 24
                                                               (rectangle 48 48 "solid" "gray"))
                                                  "place-image(triangle(32, solid, red), 24, 24, rectangle(48, 48, solid, gray))"
                                                  "place-image(triangle(64, solid, red), 24, 24, rectangle(48, 48, solid, gray))"
                                                  "place-image(circle(4, solid, white), 18, 20,
                                                               place-image(circle(4, solid, white), 0, 6,
                                                               place-image(circle(4, solid, white), 14, 2,
                                                               place-image(circle(4, solid, white), 8, 14,
                                                               rectangle(24, 24, solid, goldenrod)))))"]}

@function["place-image-align"]{Like @pyret{place-image}, but uses @pyret{image}’s @pyret{x-place} and @pyret{y-place} 
                               to anchor the image. Also, like @pyret{place-image}, @pyret{place-image-align} crops 
                               the resulting image so that it has the same size as @pyret{scene}.
                               
                               @image-examples[#:racket (place-image/align (triangle 48 "solid" "yellowgreen")
                                                                           64 64 "right" "bottom"
                                                                           (rectangle 64 64 "solid" "mediumgoldenrod"))
                                                        "place-image-align(triangle(48, solid, yellowgreen), 64, 64, x-right, y-bottom,
                                                                           rectangle(64, 64, solid, mediumgoldenrod))"
                                                        "beside-list([list: place-image-align(circle(8, solid, tomato), 0, 0, 
                                                                               x-center, y-center, rectangle(32, 32, outline, black)),
                                                                            place-image-align(circle(8, solid, tomato), 8, 8, 
                                                                               x-center, y-center, rectangle(32, 32, outline, black)),
                                                                            place-image-align(circle(8, solid, tomato), 16, 16, 
                                                                               x-center, y-center, rectangle(32, 32, outline, black)),
                                                                            place-image-align(circle(8, solid, tomato), 24, 24, 
                                                                               x-center, y-center, rectangle(32, 32, outline, black)),
                                                                            place-image-align(circle(8, solid, tomato), 32, 32, 
                                                                               x-center, y-center, rectangle(32, 32, outline, black))])"]}

@function["place-images"]{Places each of @pyret{images} into @pyret{scene} like @pyret{place-image} would, using the
                          coordinates in @pyret{posns} as the @pyret{x} and @pyret{y} arguments to @pyret{place-image}.
                          
                          @image-examples[#:racket (place-images
                                                    (list (circle 4 "solid" "white")
                                                          (circle 4 "solid" "white")
                                                          (circle 4 "solid" "white")
                                                          (circle 4 "solid" "white"))
                                                    (list (make-posn 18 20)
                                                          (make-posn 0 6)
                                                          (make-posn 14 2)
                                                          (make-posn 8 14))
                                                    (rectangle 24 24 "solid" "goldenrod"))
                                                   "place-images([list: circle(4, solid, white),
                                                                        circle(4, solid, white),
                                                                        circle(4, solid, white),
                                                                        circle(4, solid, white)],
                                                                 [list: posn(18, 20),
                                                                        posn(0, 6),
                                                                        posn(14, 2),
                                                                        posn(8, 14)],
                                                                 rectangle(24, 24, solid, goldenrod))"]}

@function["place-images-align"]{Like @pyret{place-images}, except that it places the
images with respect to @pyret{x-place} and @pyret{y-place}.

@image-examples[#:racket (place-images/align
                          (list (triangle 48 "solid" "yellowgreen")
                                (triangle 48 "solid" "yellowgreen")
                                (triangle 48 "solid" "yellowgreen")
                                (triangle 48 "solid" "yellowgreen"))
                          (list (make-posn 64 64)
                                (make-posn 64 48)
                                (make-posn 64 32)
                                (make-posn 64 16))
                          "right" "bottom"
                          (rectangle 64 64 "solid" "mediumgoldenrod"))
                "place-images-align([list: triangle(48, solid, yellowgreen),
                                            triangle(48, solid, yellowgreen),
                                            triangle(48, solid, yellowgreen),
                                            triangle(48, solid, yellowgreen)],
                                     [list: posn(64, 64), posn(64, 48), posn(64, 32), posn(64, 16)],
                                     x-right, y-bottom,
                                     rectangle(64, 64, solid, mediumgoldenrod))"]}

@function["add-line-to-scene"]{
Adds a line to the image @pyret{scene}, starting from the point (@pyret{x1},@pyret{y1}) and going to
the point (@pyret{x2},@pyret{y2}); unlike @pyret{add-line}, this function crops the resulting image
to the size of @pyret{scene}.

@image-examples[#:racket (scene+line (ellipse 40 40 "outline" "maroon")
              0 40 40 0 "maroon")
                         "add-line-to-scene(ellipse(40, 40, outline, maroon), 0, 40, 40, 0, maroon)"
                         "add-line-to-scene(rectangle(40, 40, solid, gray), -10, 50, 50, -10, maroon)"
                "add-line-to-scene(rectangle(100, 100, solid, darkolivegreen),
                                    25, 25, 100, 100,
                                    pen(goldenrod, 30, style-solid, cap-round, join-round))"]}

@function["add-curve-to-scene"]{
Adds a curve to @pyret{scene}, starting at the point (@pyret{x1},@pyret{y1}), and ending at the point (@pyret{x2},@pyret{y2}).

The @pyret{angle1} and @pyret{angle2} arguments specify the angle that the curve has as it leaves the
initial point and as it reaches the final point, respectively.

The @pyret{pull1} and @pyret{pull2} arguments control how long the curve tries to stay with that angle.
Larger numbers mean that the curve stays with the angle longer.

Unlike @pyret{add-curve}, this function crops the curve, only showing the parts that fit onto @pyret{scene}.

@image-examples[#:racket (scene+curve (rectangle 100 100 "solid" "black")
                                      20 20 0 1/3
                                      80 80 0 1/3
                                      "white")
"add-curve-to-scene(rectangle(100, 100, solid, black),
                    20, 20, 0, 1/3,
                    80, 80, 0, 1/3, white)"
"add-curve-to-scene(rectangle(100, 100, solid, black),
                    20, 20, 0, 1,
                    80, 80, 0, 1, white)"
"add-curve-to-scene(add-curve(rectangle(40, 100, solid, black),
                              20, 10, 180, 1/2,
                              20, 90, 180, 1/2, white),
                    20, 10, 0, 1/2,
                    20, 90, 0, 1/2, white)"
"add-curve-to-scene(rectangle(100, 100, solid, black),
                    -20, -20, 0, 1, 120, 120, 0, 1, red)"]}

@function["frame"]{Returns an image just like @pyret{image}, except with a black, 
                   single pixel frame drawn around the bounding box of the image.
                   
                   @image-examples[#:racket (frame (ellipse 40 40 "solid" "gray"))
                                            "frame(ellipse(40, 40, solid, gray))"
                                            "beside-list([list: ellipse(20, 70, solid, lightsteelblue),
                   frame(ellipse(20, 50, solid, mediumslateblue)),
                   ellipse(20, 30, solid, slateblue),
                   ellipse(20, 10, solid, navy)])"]}

@section["Image Methods"]

@image-method["flip-horizontal"]{

Flips the image left to right.

@image-examples[#:racket (beside
                          (rotate 30 (square 50 "solid" "red"))
                          (flip-horizontal
                           (rotate 30 (square 50 "solid" "blue"))))
                         "beside(square(50, solid, red).rotate(30),
                                 square(50, solid, blue).rotate(30).flip-horizontal())"]}

@image-method["flip-vertical"]{

Flips the image top to bottom.

@image-examples[#:racket (above
                          (star 40 "solid" "firebrick")
                          (scale/xy 1 1/2 (flip-vertical (star 40 "solid" "gray"))))
                         "above(star(40, solid, firebrick),
                                star(40, solid, gray).flip-vertical().scale-xy(1, 1/2))"]}

@image-method["scale-x"]{

Scales the image by @pyret{x-factor} horizontally.

(This method is equivalent to @pyret{image.scale-xy(x-factor, 1)})}

@image-method["scale-y"]{

Scales the image by @pyret{y-factor} vertically.

(This method is equivalent to @pyret{image.scale-xy(1, y-factor)})}

@image-method["scale-xy"]{

Scales the image by @pyret{x-factor} horizontally and by
@pyret{y-factor} vertically.

@image-examples[#:racket (scale/xy 3 2 (ellipse 20 30 "solid" "blue"))
                         "ellipse(20, 30, solid, blue).scale-xy(3, 2)"
                         "ellipse(60, 60, solid, blue)"]}

@image-method["scale"]{

Scales the image by @pyret{factor}.

@image-examples[#:racket (scale 2 (ellipse 20 30 "solid" "blue"))
                         "ellipse(20, 30, solid, blue).scale(2)"
                         "ellipse(40, 60, solid, blue)"]}

@image-method["rotate"]{

Rotates the image by the given @pyret{theta} degrees counterclockwise.

@image-examples[#:racket (rotate 45 (ellipse 60 20 "solid" "olivedrab"))
                         "ellipse(60, 20, solid, olivedrab).rotate(45)"
                         "ellipse(60, 20, solid, olivedrab).rotate(45).rotate(-45)"
                         "ellipse(60, 20, solid, olivedrab).rotate(30).scale-x(2).rotate(60)"
                         "ellipse(60, 20, solid, olivedrab).rotate(30).scale-x(2)"
                         "ellipse(60, 20, solid, olivedrab).rotate(30).scale-x(2).rotate(0)"
                         "ellipse(60, 20, solid, olivedrab).rotate(30).scale-x(2).rotate(30)"
                         "rectangle(50, 50, outline, black).rotate(5)"
                         "beside-align(y-center, rectangle(40, 20, solid, darkseagreen),
                                       rectangle(20, 100, solid, darkseagreen)).rotate(45)"
                         "beside-align(y-center, rectangle(40, 20, solid, darkseagreen),
                                                 rectangle(20, 100, solid, darkseagreen))"
                "beside-align(y-center, rectangle(40, 20, solid, darkseagreen),
                              rectangle(20, 100, solid, darkseagreen)).rotate(0)"
                "beside-align(y-center, rectangle(40, 20, solid, darkseagreen),
                              rectangle(20, 100, solid, darkseagreen)).rotate(45/2)"]}

@image-method["crop"]{

Crops the image to the rectangle with the upper left point at
(@pyret{x}, @pyret{y}) and with @pyret{width} and @pyret{height}.

@image-examples[#:racket (crop 0 0 40 40 (circle 40 "solid" "chocolate"))
                         "circle(40, solid, chocolate).crop(0, 0, 40, 40)"
                         "ellipse(80, 120, solid, dodgerblue).crop(40, 60, 40, 60)"
                         "above(beside(circle(40, solid, palevioletred).crop(40, 40, 40, 40),
                                       circle(40, solid, lightcoral).crop(0, 40, 40, 40)),
                                beside(circle(40, solid, lightcoral).crop(40, 0, 40, 40),
                                       circle(40, solid, palevioletred).crop(0, 0, 40, 40)))"
                "beside(circle(40, solid, palevioletred).crop(40, 40, 40, 40),
                        circle(40, solid, lightcoral).crop(0, 40, 40, 40))"
                "above(circle(40, solid, palevioletred).crop(40, 40, 40, 40),
                       circle(40, solid, lightcoral).crop(40, 0, 40, 40))"]}

@image-method["crop-align"]{

Crops the image to a rectangle whose size is @pyret{width} and @pyret{height} and is positioned
based on @pyret{x-place} and @pyret{y-place}.

@image-examples[#:racket (crop/align "left" "top" 40 40 (circle 40 "solid" "chocolate"))
                         "circle(40, solid, chocolate).crop-align(x-left, y-top, 40, 40)"
                         "ellipse(80, 120, solid, dodgerblue).crop-align(x-right, y-bottom, 40, 60)"
                         "circle(25, solid, mediumslateblue).crop-align(x-center, y-center, 50, 30)"
                         "above(beside(circle(40, solid, palevioletred).crop-align(x-right, y-bottom, 40, 40),
                                       circle(40, solid, lightcoral).crop-align(x-left, y-bottom, 40, 40)),
                                beside(circle(40, solid, lightcoral).crop-align(x-right, y-top, 40, 40),
                                       circle(40, solid, palevioletred).crop-align(x-left, y-top, 40, 40)))"]}

@image-method["width"]{

Returns the width of the image.

@examples{
check:
  ellipse(30, 40, solid, orange).width() is 30
  circle(30, solid, orange).width() is 60
  beside(circle(20, solid, orange), circle(20, solid, purple)).width() is 80
  rectangle(0, 10, solid, purple).width() is 0
end}}

@image-method["height"]{

Returns the height of the image.

@examples{
check:
  ellipse(30, 40, solid, orange).height() is 40
  circle(30, solid, orange).height() is 60
  overlay(circle(20, solid, orange), circle(30, solid, purple)).height() is 60
  rectangle(10, 0, solid, purple).height() is 0
end}}

@section{Pinholes}

@image-method["center-pinhole"]{
Creates a pinhole in the image's center.
@image-examples[#:racket (center-pinhole (rectangle 40 20 "solid" "red"))
                         "rectangle(40, 20, solid, red).center-pinhole()"
                         "rectangle(40, 20, solid, orange).center-pinhole().rotate(30)"]}

@image-method["put-pinhole"]{
Creates a pinhole in the image at the point (@pyret{x}, @pyret{y}).
@image-examples[#:racket (put-pinhole 2 18 (rectangle 40 20 "solid" "forestgreen"))
                         "rectangle(40, 20, solid, forestgreen).put-pinhole(2, 18)"]}

@image-method["pinhole-x"]{
Returns the x coordinate of the image's pinhole
@examples{
check:
  rectangle(10, 10, solid, red).center-pinhole().pinhole-x() is 5
  rectangle(10, 10, solid, red).pinhole-x() is false
end}}

@image-method["pinhole-y"]{
Returns the y coordinate of the image's pinhole
@examples{
check:
  rectangle(10, 10, solid, red).center-pinhole().pinhole-x() is 5
  rectangle(10, 10, solid, red).pinhole-y() is false
end}}

@image-method["clear-pinhole"]{Removes the pinhole from the image (if it has one).}

@function["overlay-pinhole"]{
Overlays all of the image arguments on their pinholes.
If any of the arguments do not have pinholes, then the center of the image is used instead.
@image-examples[#:racket (overlay/pinhole
                          (put-pinhole 25 10 (ellipse 100 50 "solid" "red"))
                          (put-pinhole 75 40 (ellipse 100 50 "solid" "blue")))
                "overlay-pinhole(ellipse(100, 50, solid, red).put-pinhole(25, 10),
                                 ellipse(100, 50, solid, blue).put-pinhole(75, 40))"
                "overlay-pinhole(circle(30, solid, yellow),
                                 overlay-pinhole(ellipse(100, 40, solid, purple).put-pinhole(20, 20).rotate(60 * 0),
                                 overlay-pinhole(ellipse(100, 40, solid, purple).put-pinhole(20, 20).rotate(60 * 1),
                                 overlay-pinhole(ellipse(100, 40, solid, purple).put-pinhole(20, 20).rotate(60 * 2),
                                 overlay-pinhole(ellipse(100, 40, solid, purple).put-pinhole(20, 20).rotate(60 * 3),
                                 overlay-pinhole(ellipse(100, 40, solid, purple).put-pinhole(20, 20).rotate(60 * 4),
                                 ellipse(100, 40, solid, purple).put-pinhole(20, 20).rotate(60 * 5))))))).clear-pinhole()"]}

@function["underlay-pinhole"]{
Underlays all of the image arguments on their pinholes.
If any of the arguments do not have pinholes, then the center of the image is used instead.
@image-examples[#:racket (underlay/pinhole
                          (put-pinhole 25 10 (ellipse 100 50 "solid" "red"))
                          (put-pinhole 75 40 (ellipse 100 50 "solid" "blue")))
                         "underlay-pinhole(ellipse(100, 50, solid, red).put-pinhole(25, 10),
                                           ellipse(100, 50, solid, blue).put-pinhole(75, 40))"]}




}
