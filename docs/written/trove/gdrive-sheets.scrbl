#lang scribble/base
@; Documentation for `gdrive-sheets'. If you're wondering where the actual
@; code is, check the CPO repository.
@(require "../../scribble-api.rkt"
          (except-in "../abbrevs.rkt" L-of))

@(define (L-of typ) `(a-app (a-id "List" (xref "lists" "List")) ,typ))
@(define sheet-type (a-id "Spreadsheet" (xref "gdrive-sheets" "Spreadsheet")))
@(define ws-type (a-id "Worksheet" (xref "gdrive-sheets" "Worksheet")))
@(define v-type (a-id "Visibility" (xref "gdrive-sheets" "Visibility")))
@(define cell-range-type (L-of (L-of A)))

@(define (spreadsheet-method name #:args (args #f) #:return (return #f) #:contract (contract #f))
   (method-doc "Spreadsheet" "spreadsheet" name #:alt-docstrings "" #:args args #:return return #:contract contract))
@(define (worksheet-method name #:args (args #f) #:return (return #f) #:contract (contract #f))
   (method-doc "Worksheet" "worksheet" name #:alt-docstrings "" #:args args #:return return #:contract contract))

@(append-gen-docs
  `(module
       "gdrive-sheets"
       (path "src/js/base/runtime-anf.js")
       (fun-spec
        (name "load-sheet-raw")
        (arity 1)
        (args ("name"))
        (return ,sheet-type)
        (contract (a-arrow ,S ,sheet-type)))
       (fun-spec
        (name "load-sheet")
        (arity 3)
        (args ("name" "constr" "skip-header"))
        (return ,sheet-type)
        (contract (a-arrow ,S ,F ,B ,sheet-type)))
       (fun-spec
        (name "load-spreadsheet")
        (arity 2)
        (args ("name" "visibility"))
        (return ,sheet-type)
        (contract (a-arrow ,S ,v-type ,sheet-type)))
       (fun-spec
        (name "new-spreadsheet")
        (arity 1)
        (args ("name"))
        (return ,sheet-type)
        (contract (a-arrow ,S ,sheet-type)))
       (data-spec
        (name "Visibility")
        (variants ("public" "private")))
       (data-spec
        (name "Spreadsheet")
        (shared (
          (method-spec
           (name "sheet-by-name")
           (arity 2)
           (args ("self" "name"))
           (return ,ws-type)
           (contract (a-arrow ,sheet-type ,S ,ws-type)))
          (method-spec
           (name "sheet-by-pos")
           (arity 2)
           (args ("self" "pos"))
           (return ,ws-type)
           (contract (a-arrow ,sheet-type ,N ,ws-type)))
          (method-spec
           (name "delete-sheet-by-name")
           (arity 2)
           (args ("self" "name"))
           (return ,No)
           (contract (a-arrow ,sheet-type ,S ,No)))
          (method-spec
           (name "delete-sheet-by-pos")
           (arity 2)
           (args ("self" "pos"))
           (return ,No)
           (contract (a-arrow ,sheet-type ,N ,No)))
          (method-spec
           (name "add-worksheet")
           (arity 2)
           (args ("self" "name"))
           (return ,ws-type)
           (contract (a-arrow ,sheet-type ,S ,ws-type))))))
       (data-spec
        (name "Worksheet")
        (shared (
          (method-spec
           (name "cell-at")
           (arity 3)
           (args ("self" "col" "row"))
           (return ,A)
           (contract (a-arrow ,ws-type ,S ,N ,A)))
          (method-spec
           (name "set-cell-at")
           (arity 4)
           (args ("self" "col" "row" "new-val"))
           (return ,No)
           (contract (a-arrow ,ws-type ,S ,N ,A ,No)))
          (method-spec
           (name "set-cell-range")
           (arity 4)
           (args ("self" "start-col" "start-row" "entries"))
           (return ,No)
           (contract (a-arrow ,ws-type ,S ,N ,cell-range-type)))
          (method-spec
           (name "all-cells")
           (arity 1)
           (args ("self"))
           (return ,cell-range-type)
           (contract (a-arrow ,ws-type ,cell-range-type)))
          (method-spec
           (name "all-cells-as")
           (arity 3)
           (args ("self" "constr" "skip-header"))
           (return ,(L-of A))
           (contract (a-arrow ,ws-type ,F ,B ,(L-of A))))
          (method-spec
           (name "cell-range")
           (arity 5)
           (args ("self" "start-col" "start-row" "end-col" "end-row"))
           (return ,cell-range-type)
           (contract (a-arrow ,ws-type ,S ,N ,S ,N ,cell-range-type)))
          (method-spec
           (name "cell-range-as")
           (arity 6)
           (args ("self" "start-col" "start-row" "end-col" "end-row" "constr"))
           (return ,(L-of A))
           (contract (a-arrow ,ws-type ,S ,N ,S ,N ,F ,(L-of A))))
          (method-spec
           (name "update-name")
           (arity 2)
           (args ("self" "name"))
           (return ,No)
           (contract (a-arrow ,ws-type ,S ,No)))
          (method-spec
           (name "resize-rows")
           (arity 2)
           (args ("self" "num-rows"))
           (return ,No)
           (contract (a-arrow ,ws-type ,N ,No)))
          (method-spec
           (name "resize-cols")
           (arity 2)
           (args ("self" "num-cols"))
           (return ,No)
           (contract (a-arrow ,ws-type ,N ,No))))))))

@docmodule["gdrive-sheets"]{

This page documents the bindings Pyret has to the Google Sheets API.
By no means does this page represent a polished and ready-to-push library;
it is entirely meant to provide a jumping-off point for the design of such
an API.

@section{The Visibility Datatype}

@type-spec["Visibility" '()]
@singleton-doc["Visibility" "public" v-type]
@singleton-doc["Visibility" "private" v-type]

These values are used to determine whether a given spreadsheet should be accessed
as a publicly-available spreadsheet or not.

@section{The Spreadsheet Datatype}

@type-spec["Spreadsheet" '()]

The @pyret{Spreadsheet} type represents spreadsheets from Google Sheets.

@section{Spreadsheet Creation/Loading Functions}

@function["load-sheet-raw"]

@function["load-sheet"]

@function["load-spreadsheet"]

@function["new-spreadsheet"]

@section{Spreadsheet Methods}

@spreadsheet-method["sheet-by-name"]

@spreadsheet-method["sheet-by-pos"]

@spreadsheet-method["delete-sheet-by-name"]

@spreadsheet-method["delete-sheet-by-pos"]

@spreadsheet-method["add-worksheet"]

@section{The Worksheet Datatype}

@type-spec["Worksheet" '()]

The @pyret{Worksheet} type represents worksheets contained within @pyret{Spreadsheet}s.

@section{Worksheet Methods}

@worksheet-method["cell-at"]

@worksheet-method["set-cell-at"]

@worksheet-method["set-cell-range"]

@worksheet-method["all-cells"]

@worksheet-method["all-cells-as"]

@worksheet-method["cell-range"]

@worksheet-method["cell-range-as"]

@worksheet-method["update-name"]

@worksheet-method["resize-rows"]

@worksheet-method["resize-cols"]
}
