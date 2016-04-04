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

@; NOTE: This spreadsheet should be publicly shared!
@(define example-sheet-id "10ds2lMAGmp69zz3mPAP_jrTsi2TKS5HbmujacvLUcuQ")
@(define example-sheet-url (format "https://docs.google.com/spreadsheets/d/~a/edit?usp=sharing" example-sheet-id))

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

@bold{Maintainer's Note:} I need to do some more testing, but it might be the case that,
as it currently stands, only privately-available sheets can be modified. Obviously, that's
no good. Stay tuned.

@subsection{Making a Spreadsheet Public}

To make a spreadsheet publicly accessible, one must perform the following steps:

Open the sheet on Google Sheets. Then, navigate to "File">"Publish to the web." Then
click "Publish."

@section{The Spreadsheet Datatype}

@type-spec["Spreadsheet" '()]

The @pyret{Spreadsheet} type represents spreadsheets from Google Sheets.

In the context of spreadsheets, a "name" is the sheet's id, which can be found from
its URL. For example, the examples in this file use the sheet at the address
@para{@tt[example-sheet-url]}
This sheet has a name of @pyret{"@example-sheet-id"}.

@section{Spreadsheet Creation/Loading Functions}

@function["load-sheet-raw"]
@function["load-sheet"]

@bold{Maintainer's Note:} I'm including these since they are being exported, but I am
~80% sure they are bitrot that need to be removed.

@function["load-spreadsheet"]

This function loads the given spreadsheet with the given visibility. If one
attempts to load a private sheet with @pyret{public} visibility (or if an
invalid sheet is given), an error will be thrown.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", public)
  ssheet.title is "test-sheet"
end
}

@function["new-spreadsheet"]

This function creates a new spreadsheet with the given title.

@examples{
check:
  ssheet = new-spreadsheet("my-spreadsheet")
end
}

@section{Spreadsheet Methods}

@spreadsheet-method["sheet-by-name"]

Returns the worksheet in this spreadsheet which has the given name.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.title is "students"
end
}

@spreadsheet-method["sheet-by-pos"]

Returns the worksheet in this spreadsheet at the given position.
@bold{@italic{Note: Positions are one-indexed.}}

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-pos(1)
  students.title is "students"
end
}

@spreadsheet-method["delete-sheet-by-name"]

Deletes the sheet in this spreadsheet with the given name.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  foo = ssheet.add-worksheet("foo")
  foo.title is "foo"
  ssheet.delete-sheet-by-name("foo")
  ssheet.sheet-by-name("foo") # Throws Error
end
}

@spreadsheet-method["delete-sheet-by-pos"]

Deletes the sheet in this spreadsheet with the given position.
@bold{@italic{Note: Positions are one-indexed.}}

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  foo = ssheet.add-worksheet("foo")
  foo.title is "foo"
  ssheet.delete-sheet-by-pos(2)
  ssheet.sheet-by-name("foo") # Throws Error
end
}

@spreadsheet-method["add-worksheet"]

Adds a new worksheet to this spreadsheet with the given name.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  ssheet.add-worksheet("foo")
  foo = ssheet.sheet-by-name("foo")
  foo.title is "foo"
end
}

@section{The Worksheet Datatype}

@type-spec["Worksheet" '()]

The @pyret{Worksheet} type represents worksheets contained within @pyret{Spreadsheet}s.

@section{Worksheet Methods}

@bold{@italic{Note: Positions are one-indexed.}}

@worksheet-method["cell-at"]

Returns the contents of the cell at the given position in this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.cell-at("A", 2) is "Alice"
  students.cell-at("B", 2) is "3450234.0"
  students.cell-at("D", 4) is "Black"
end
}

@worksheet-method["set-cell-at"]

Sets the contents of the cell at the given position in this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.cell-at("C", 4) is "2.8"
  students.set-cell-at("C", 4.0)
  students.cell-at("C", 4) is "4.0"
  # Eve is glad she majored in Computer Science.
end
}

@worksheet-method["set-cell-range"]

Sets the contents of the given range of cells (from @pyret{start-col} and
@pyret{start-row}) in this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.set-cell-range("D", 1, [list: [list: "Sam", "34254252", "3.9", "Green"]])
  students.cell-at("D", 1) is "Sam"
  students.cell-at("D", 2) is "3425452"
end
}

@worksheet-method["all-cells"]

Returns the contents of all cells in this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.all-cells() is
  [list: [list: "Name", "ID", "GPA", "Favorite Color"],
         [list: "Alice", "3450234.0", "4.0", "Blue"],
         [list: "Bob", "234592.0", "3.5", "Red"],
         [list: "Eve", "2.934054395E9", "2.8", "Black"]]
end
}

@worksheet-method["all-cells-as"]

Applies each row of this worksheet as arguments to the given function
and returns the list of results. If @pyret{skip-header} is @pyret{true},
then the first row of the worksheet is skipped.

@examples{
data Student:
  | student(name :: String, id :: Number, gpa :: Number, favorite-color :: String)
end

fun student-from-strings(name, id, gpa, favorite-color):
  shadow id = cases(O.Option) string-to-number(id):
    | some(v) => v
    | none => raise("Invalid id: " + id)
  end
  shadow gpa = cases(O.Option) string-to-number(gpa):
    | some(v) => v
    | none => raise("Invalid GPA: " + gpa)
  end
  student(name, id, gpa, favorite-color)
end
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.all-cells-as(student-from-strings, true) is
  [list: student("Alice", 3450234, 4, "Blue"),
         student("Bob", 234592, 3.5, "Red"),
         student("Eve", 2934054395, 2.8, "Black")]
end
}

@worksheet-method["cell-range"]

Returns the contents of the cells between columns @pyret{start-col} and
@pyret{end-col} and between rows @pyret{start-row} and @pyret{end-row}.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.cell-range("C", 2, "D", 4) is
  [list: [list: "4.0", "Blue"],
         [list: "3.5", "Red"],
         [list: "2.8", "Black"]]
end
}

@worksheet-method["cell-range-as"]

Like @pyret{cell-range}, but applies @pyret{constr} to the rows in the given
range, as done with @pyret{all-cells-as}.

@examples{
data DehumanizedStudent:
  | dehumanized-student(id :: Number, gpa :: Number)
end

fun str-to-num(s): 
  cases(O.Option) string-to-number(s):
    | some(v) => v
    | none => raise("Things broke")
  end
end

ds = lam(id, gpa): dehumanized-student(str-to-num(id), str-to-num(gpa)) end

check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  students.cell-range-as("B", 2, "C", 4, ds) is
  [list: dehumanized-student(3450234, 4),
         dehumanized-student(234592, 3.5),
         dehumanized-student(2934054395, 2.8)]
end
}

@worksheet-method["update-name"]

Updates the name of this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  # Maintainer's Note: Should need to be is=~
  students.title is "students"
  students.update-name("minions")
  students.title is "minions"
end
}

@worksheet-method["resize-rows"]

Updates the number of rows in this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  # Maintainer's Note: Should need to be is=~
  students.row-count is 1000
  students.resize-rows(500)
  students.row-count is 500
end
}

@worksheet-method["resize-cols"]

Updates the number of columns in this worksheet.

@examples{
check:
  ssheet = load-spreadsheet("@example-sheet-id", private)
  students = ssheet.sheet-by-name("students")
  # Maintainer's Note: Should need to be is=~
  students.col-count is 26
  students.resize-cols(30)
  students-col-count is 30
end
}

}
