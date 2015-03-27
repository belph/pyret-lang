#lang scribble/base
@(require "../../scribble-api.rkt")
@(require "../abbrevs.rkt")
@(require (only-in scribble/core delayed-block))

@(define attr (a-id "Attribute" (xref "xml" "Attribute")))
@(define elt  (a-id "Element"   (xref "xml" "Element")))
@(define atts (L-of attr))
@(define elts (L-of elt))
@(define (attr-method name #:args (args #f) #:return (return #f) #:contract (contract #f))
  (method-doc "Attribute" "attribute" name #:alt-docstrings "" #:args args #:return return #:contract contract))
@(define (elt-method name #:args (args #f) #:return (return #f) #:contract (contract #f))
  (method-doc "Element" "tag" name #:alt-docstrings "" #:args args #:return return #:contract contract))

@(append-gen-docs
  `(module "xml"
  (path "src/js/base/runtime-anf.js")
  (data-spec
    (name "Attribute")
    (variants ("attribute"))
    (constr-spec
      (name "attribute")
      (members
        (("name" (type normal) (contract S))
         ("value" (type normal))))
      (with-members (
        (method-spec
          (name "tosource")
          (arity 1)
          (args ("self"))
          (return ,S)
          (contract (a-arrow ,attr ,S)))
        (method-spec
          (name "_torepr")
          (arity 2)
          (args ("self" "torepr"))
          (return ,S)
          (contract (a-arrow ,attr (a-arrow ,A ,S) ,S)))))))
  (data-spec
    (name "Element")
    (variants ("tag" "atomic"))
    (constr-spec
      (name "tag")
      (members
        (("name" (type normal) (contract S))
         ("attributes" (type normal) (contract atts))
         ("elts" (type normal) (contract elts)))))
    (constr-spec
      (name "atomic")
      (members
        (("val" (type normal) (contract A)))))
    (shared
       ((method-spec
          (name "tosource")
          (arity 1)
          (args ("self"))
          (return ,S)
          (contract (a-arrow ,elt ,S)))
        (method-spec
          (name "_torepr")
          (arity 1)
          (args ("self"))
          (return ,S)
          (contract (a-arrow ,elt ,S))))))))

@docmodule["xml"]{
@section{Pyret XML Library}

This library provides basic XML functionality. Users can construct and manipulate XML structures 
and produce them as a string of valid XML output.

@section{The @pyret{attribute} Data Type}
@data-spec["Attribute" (list
  @constructor-spec["Attribute" "attribute" (list `("name" ("type" "normal") ("contract" ,S))
                                                  `("value" ("type" "normal") ("contract" ,A)))])]
@nested[#:style 'inset]{
  @constructor-doc["Attribute" "attribute"  (list `("name" ("type" "normal") ("contract" ,S))
                                                  `("value" ("type" "normal") ("contract" ,A))) attr]
   This data structure represents a named key-value attribute pair belonging to an XML tag.
}

@section{The @pyret{tag} and @pyret{atomic} Data Types}

@data-spec["Element" (list
  @constructor-spec["Element" "tag" (list `("name" ("type" "normal") ("contract" ,S))
                                          `("attributes" ("type" "normal") ("contract" ,atts))
                                          `("elts" ("type" "normal") ("contract" ,elts)))]
  @constructor-spec["Element" "atomic" (list `("val" ("type" "normal") ("contract" ,A)))])]

@nested[#:style 'inset]{
  @constructor-doc["Element" "tag" (list `("name" ("type" "normal") ("contract" ,S))
                                          `("attributes" ("type" "normal") ("contract" ,atts))
                                          `("elts" ("type" "normal") ("contract" ,elts))) elt]
Represents an XML Tag with the given tag name, attributes, and child elements.
  @constructor-doc["Element" "atomic" (list `("val" ("type" "normal") ("contract" ,A))) elt]
Represents an atomic value (e.g. string, number, etc.) contained within an XML element, respectively.

}
@section{XML Methods}

The XML Library provides two methods on each datatype.

@attr-method["tosource"]
@elt-method["tosource"]

Returns an escaped-string representation of the XML tag.

@examples{
check:
  para = tag("p", [list: attribute("align", "center")], 
                  [list: atomic("Hello, world!"), atomic(" "), 
                  atomic("Thanks for reading!"), 
                  tag("span", [list: ], [list: atomic("Good-bye!")])])
  para.tosource() is "<p align=\"center\">Hello, world! Thanks for reading!<span>Good-bye!</span></p>"
end
}

@attr-method["_torepr"]
@elt-method["_torepr"]

Returns a pretty-printed representation of the XML tag, formatted
as a standard nested set of XML elements.

@examples{
para = tag("p", [list: attribute("align", "center")], 
                [list: atomic("Hello, world!"), atomic(" "), 
                atomic("Thanks for reading!"), 
                tag("span", [list: ], [list: atomic("Good-bye!")])])
# On the REPR:
> para
<p align="center">
  Hello, world!
   
  Thanks for reading!
  <span>Good-bye!</span>
</p>
}

}
