#lang racket/base

#|
## IMAGE EXAMPLE HELPERS
## =====================
## Provides functionality
## for displaying images in
## documentation as Pyret
## examples
|#

(require (except-in scribble/eval examples)
          racket/runtime-path
          racket/base
          racket/match
          racket/contract
          racket/pretty
          (only-in racket/port with-output-to-string port->string)
          (only-in racket/system system)
          (only-in racket/file make-temporary-file)
          (only-in racket/string string-join string-split)
          (only-in racket/path file-name-from-path)
          (only-in racket/list flatten)
          (for-syntax racket/base))

(provide USE-PYRET
         racket-comment
         process-examples
         respace-example)

;; Flag for rendering all images with their
;; bounding boxes and center points
(define DEBUG-IMAGES #t)

;; Runtime paths relative to this file
;; (i.e. relative to docs/)

;; Path to phase 1 main-wrapper.js
(define-runtime-path pyret-compiler
  (build-path ".." "build" "phase1" "main-wrapper.js"))

(define-runtime-path scribble-api
  (build-path "." "scribble-api.rkt"))

(define-runtime-path abbrevs
  (build-path "." "written" "abbrevs.rkt"))

(runtime-require scribble-api)
(runtime-require abbrevs)

;; Locates path for node.js
(define node
  (match (system-type)
    ['windows (find-executable-path "node.exe")]
    [else     (find-executable-path "node"    )]))

;; Runs the given Pyret file and returns the
;; program's output to stdout
(define/contract (get-pyret-output file)
  (path? . -> . string?)
  (let ((command (string-append "node "
                                (path->string pyret-compiler)
                                " "
                                (path->string file))))
    (parameterize ((current-input-port (open-input-string "")))
      (with-output-to-string
       (λ()(system command))))))



;; If we can't find the compiler, just fall back on Racket output
(define USE-PYRET (and (file-exists? pyret-compiler) (file-exists? node)))

;; Creates a new temporary file (to hold the examples)
(define (make-pyret-temp-file (fail-thunk #f))
  ;; Need to catch exn:fail? here for cases when the
  ;; background expander calls this function (in which
  ;; case the temporary file creation will fail, and
  ;; an exn:fail? exception is raised)
  (with-handlers ([exn:fail? (λ(e) (if fail-thunk
                                       (fail-thunk)
                                       (raise e)))])
    (make-temporary-file "pyretdoctmp~a.arr" #f #f)))

;; A little bit of reflection is needed,
;; so force this import
(define ALL-GEN-DOCS
  (begin (namespace-require scribble-api)
         (namespace-variable-value
          'ALL-GEN-DOCS #t #f
          (module->namespace scribble-api))))

;; Returns a list of identifiers which the given module exports,
;; as per what has been registered with ALL-GEN-DOCS.
;;
;; This is used so that we can import all identifiers from the
;; pyret-image module without any type of namespace prefix
;; (This methods always makes sure to import even undocumented
;;  exports, making it more preferable over doing something like
;;  generating an import statement from the identifiers which
;;  have been documented)
(define (module-exports modname)
  (let ((mod (findf (λ(m)(equal? (cadr m) modname)) ALL-GEN-DOCS))
        (get-name 
         (λ(lst)  (cadr (findf 
                           (λ(eltlst) 
                             (and (list? eltlst) 
                                  (equal? (car eltlst) 'name))) lst)))))
    (map get-name (cdddr mod))))

;; The actual import statement for the example file
(define IMAGE-IMPORT-STATEMENT
  (string-append "import " (string-join (module-exports "pyret-image") ", ")
                 " from pyret-image"))

;; Wraps the given (example-identifier . example-source) pair in a pyret
;; expression which, when the file is run, will print out the identifier
;; and *evaluated* example-source as a dotted pair of the same style.
(define (prep-image-example pair)
  (match pair
    [(cons sym exmp)
     ;; '(<(car pair)> . ' + torepr(draw-svg(<(cdr pair)>).tosource()) + ')'
     (string-append "print('("
                    (format "~a" sym)
                    (if DEBUG-IMAGES
                        " . ' + torepr(draw-debug("
                        " . ' + torepr(draw-svg(")
                    (fixup-str exmp #f)
                    ").tosource()) + ')')")]))

;; Wraps each example in the given association list (see prep-image-example)
(define (prep-pyret-file-contents examples)
  (map prep-image-example examples))

;; When successful, the last portion of the program output should be
;; "The program didn't define any tests.", as opposed to some error
;; message.
(define (check-didnt-fail port)
  (regexp-match? #px"The program didn't define any tests[.\n]{,5}$"
                 (port->string port)))

#|
## How this whole thing works:
## --------------------------
## 1) Make some temp file
## 2) Serialize the pyret examples into a
##    call to the `pyret-image` library
## 3) Format the examples so that the
##    program prints out a string of the
##    form '((symname . svg) (symname . svg) ...)
## 4) Pass this program to pyret, wait 16 1/2 hours
##    for the compiler to spin up and run
##    (Hence the batching of this whole process)
## 5) Call (read) on this serialized output.
##    Only a valid s-expression is returned, so
##    any error output will just cause the
##    loop at the end to default to the eof error
## 6) That's it. Serialized Pyret output. Now just
##    parse the SVG strings into scribble-able XML and
##    you're good to go.
|#
(define (process-examples examples return-continuation)
  (define examples-in-file (make-hash))
  (let* ((file (make-pyret-temp-file (λ()(return-continuation examples))))
         (prepped (prep-pyret-file-contents examples))
         (fileport (with-handlers ([exn:fail?
                                    (λ(e)(return-continuation examples))])
                     (open-output-file file  #:exists 'replace))))
    ;; The name of the fresh temporary file
    (define filename (file-name-from-path file))
    ;; Matches Pyret error messages referencing the
    ;; temporary file
    (define filename-rx (regexp (format "~a: line ([0-9]+)" filename)))
    ;; Returns the region of the temporary file
    ;; which spans the (area near the) line range
    ;; provided, formatted with line numbers.
    (define (get-line-range start end)
      (let* ((best-start (get-best-line start))
             (best-end (get-best-line end))
             (rel-keys (sort (filter (λ(x)(<= best-start x best-end))
                                     (hash-keys examples-in-file)) <))
             (rel-lines (flatten (map (λ(key)(string-split
                                              (hash-ref examples-in-file key)
                                              "\n")) rel-keys)))
             (line-padding (λ(lineno)
                             (list->string
                              (build-list
                               (- (string-length (number->string best-end))
                                  (string-length (number->string lineno)))
                               (λ(n)#\Space))))))
        (string-join (for/list ((lineno (in-range best-start best-end))
                                (linestr rel-lines))
                       (format "~a~a  ~a" (line-padding lineno)
                               lineno linestr)) "\n")))
    ;; For tracking the locations of examples in the
    ;; examples file
    (port-count-lines! fileport)
    (define (register-example example)
      (let-values (((line col pos) (port-next-location fileport)))
        (if (hash-has-key? examples-in-file line)
            (error (format (string-append "Multiple expressions on"
                                          " one line: ~nline: ~a~nold "
                                          "contents: ~a~nnew contents: ~a")
                           line (hash-ref examples-in-file line) example))
            (hash-set! examples-in-file line example))))
    (define (get-best-line lineno)
      ;; Creates a function which returns the
      ;; maximum of the two given values, so
      ;; long as it is smaller than the given
      ;; x value
      (define (max-<= x)
        (λ(a b) (if (or (> a x) (> b a)) b a)))
      ;; First example line is on line 2
      (foldr (max-<= lineno) 2 (hash-keys examples-in-file)))
    ;; Returns a formatted error message which displays the
    ;; example located where Pyret raised an error
    (define (fetch-line lineno)
      (let ((bestline (get-best-line lineno)))
        (format (string-append 
                 "~nRegion of error:~n~a"
                 "~n~nHint: It looks like the problem "
                 "might be with this example: ~n~a~n~n")
                (get-line-range (- lineno 10) (+ lineno 10))
                (hash-ref examples-in-file bestline))))
    ;; If there is a line number reference in the Pyret stack
    ;; trace provided, returns a formatted error message with
    ;; the example which was located at that line number
    (define (fetch-from-error errmsg)
      (let ((rxp-startRow (regexp-match #rx"startRow: ([0-9]+)" errmsg))
            (rxp-pyret-stack (regexp-match filename-rx errmsg)))
        (cond [(pair? rxp-startRow) (fetch-line
                                     (string->number (cadr rxp-startRow)))]
              [(pair? rxp-pyret-stack) (fetch-line
                                        (string->number (cadr rxp-pyret-stack)))]
              [else   ""])))
    ;; Add the image import statement to the examples file on the first line
    (display IMAGE-IMPORT-STATEMENT fileport)
    (newline fileport)
    ;; Add each of the prepared example strings to the examples file
    ;; and register their locations
    (for ((printstmt prepped))
      (register-example printstmt)
      (display printstmt fileport)
      (newline fileport))
    (close-output-port fileport)
    ;; Status indicators: the fun way
    (eprintf ".")
    ;; Now that all examples are added, run the file
    ;; through Pyret and collect the output
    (define pyret-output (get-pyret-output file))
    ;; If Pyret raises an error, spit out our error message
    (unless (check-didnt-fail (open-input-string pyret-output))
      (newline)(error (format "Pyret raised an error while running your examples: \n ~a~a" 
                              pyret-output
                              (fetch-from-error pyret-output))))
    ;; If Pyret does not raise an error, collect the examples and return:
    (let loop ((result (open-input-string pyret-output)) ; <- stdout as a string
               (sofar '())) ; <- the collected examples thus far
              (let ((in (read result))) ; <- we can use the standard reader to get an example
                                        ;    (hence the decision to serialize the results out
                                        ;     as a series of dotted pairs)
                (cond [(eof-object? in) (reverse (cdr sofar))] ;; The first value of sofar will be the 
                                                               ;; #t return value from (system ...)
                      [(pair? in) (loop result (cons in sofar))]
                      [else (loop result sofar)])))))

(pretty-print-columns 50)
(define (racket-comment datum)
  (define EXAMPLES-PREFIX "# Racket equivalent: ")
  (define BUFFER (list->string
                  (cons #\# (build-list 
                             (sub1 (string-length EXAMPLES-PREFIX)) 
                             (λ(n)#\Space)))))
  (define prt (open-output-string))
  (pretty-write datum prt)
  (define pretty-str (begin0 (get-output-string prt)
                             (close-output-port prt)))
  (let ((split-up (string-split pretty-str "\n")))
    (cons (string-append EXAMPLES-PREFIX (car split-up)) 
          (map (λ(s)(string-append BUFFER s)) (cdr split-up)))))

;; Reformats the given string to be more suitable for
;; Pyret evaluation (non-string examples in the @image-examples
;; macro tend to raise errors due to the reader placing
;; spaces between function names and arguments)
(define (fixup-str s (drop-parens? #t))
  ;; Matches the first and last parentheses of the given string
  ;; (which are located at the start and end)
  (define FIRSTLASTPAREN #rx"(?:^\\()|(?:\\)$)")
  ;; Locates any instances of parentheses which have a
  ;; tick mark or spaces preceding them
  (define PARENRX #px"\\s*'?\\(")
  ;; Locates any commas located on their own line
  (define SINGLECOMMARX #px"\\s*\n\\s*,[ ]*\n")
  ;; Locates any commas surrounded by spaces
  (define SPACECOMMA #px"\\s*,(\\s*)")
  ;; Takes a series of regexp replacements via a varargs
  ;; association list and performs (sequentially in the
  ;; order given) each substitution on the given string.
  (define (do-replacements s . rpl)
    (if (null? rpl) s
        (apply do-replacements (regexp-replace* (caar rpl) s (cdar rpl)) (cdr rpl))))
  ;; Does the replacements, dropping the first and
  ;; last parentheses as needed
  (if drop-parens?
      (do-replacements s
                       (cons PARENRX "(")
                       (cons SINGLECOMMARX ",\n")
                       (cons SPACECOMMA ",\\1")
                       (cons FIRSTLASTPAREN ""))
      (do-replacements s
                       (cons PARENRX "(")
                       (cons SINGLECOMMARX ",\n")
                       (cons SPACECOMMA ",\\1"))))

(define (trim-max n str)
  (define pattern (pregexp (format "^\\s{,~a}(.*)$" n)))
  (define (trim s)
    (regexp-replace pattern s "\\1"))
  (define split-up (string-split str "\n"))
  (string-join (cons (car split-up)
                     (map trim (cdr split-up))) "\n"))

(define (respace-example stx)
  ;; This if is needed since the source location
  ;; may be dropped when preprocessing is finished
  ;; (which is okay, because this will have been
  ;;  called already by then)
  (if (syntax-column stx)
      (datum->syntax stx (trim-max (add1 (syntax-column stx))
                                   (syntax->datum stx)))
      stx))
  