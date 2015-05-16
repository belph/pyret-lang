#lang racket

#|
## IMAGE EXAMPLE HELPERS
## =====================
## Provides functionality
## for displaying images in
## documentation as Pyret
## examples
|#

;; TODO: Clean up requires
(require ;"scribble-api.rkt" "written/abbrevs.rkt" 
         (except-in scribble/eval examples)
          2htdp/image
          scribble/base
          scribble/core scribble/html-properties
          racket/runtime-path
          racket/base
          racket/system
          (prefix-in xml: xml)
          (for-meta 2 racket/base)
          (for-template scribble/core scribble/html-properties)
          (for-syntax racket/base syntax/parse racket/list))

(provide USE-PYRET
         process-examples)

;; Path to phase 1 main-wrapper.js
(define-runtime-path pyret-compiler
  (build-path ".." "build" "phase1" "main-wrapper.js"))

(define-runtime-path scribble-api
  (build-path "." "scribble-api.rkt"))

(define-runtime-path abbrevs
  (build-path "." "written" "abbrevs.rkt"))

(runtime-require scribble-api)
(runtime-require abbrevs)

#;(define-runtime-path matrices-arr
  (build-path ".." ".." "junk-drawer" "pyret" "trove" "matrices.arr"))

(define node
  (match (system-type)
    ['windows (find-executable-path "node.exe")]
    [else     (find-executable-path "node"    )]))

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

(define (make-pyret-temp-file)
  (make-temporary-file "pyretdoctmp~a.arr" #f #f))

;; A little bit of reflection is needed,
;; so force this import
(define ALL-GEN-DOCS
  (begin (namespace-require scribble-api)
         (namespace-variable-value
          'ALL-GEN-DOCS #t #f
          (module->namespace scribble-api))))

(define (module-exports modname)
  (let ((mod (findf (λ(m)(equal? (second m) modname)) ALL-GEN-DOCS))
        (get-name 
         (λ(lst)  (second (findf 
                           (λ(eltlst) 
                             (and (list? eltlst) 
                                  (equal? (first eltlst) 'name))) lst)))))
    (map get-name (cdddr mod))))

(define IMAGE-IMPORT-STATEMENT
  (string-append "import " (string-join (module-exports "pyret-image") ", ") " from pyret-image"))

(define (prep-image-example pair)
  (match pair
    [(cons sym exmp)
     ;; '(<(car pair)> . ' + torepr(draw-svg(<(cdr pair)>).tosource()) + ')'
     (string-append "print('("
                    (format "~a" sym)
                    " . ' + torepr(draw-svg(" 
                    exmp
                    ").tosource()) + ')')")]))

(define (prep-pyret-file-contents examples)
  ;; print( '(' + <examples (joined with ' + ')> + ')' )
  ;(string-append "print('(' + " 
                 (map prep-image-example examples))
                 ;" + ')')"))

(define (check-didnt-fail port)
  (cons? (regexp-match #px"The program didn't define any tests[.\n]{,5}$" (port->string port))))

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
  ;; (subprocess ...) returns a file port which might
  ;; block if the output is too big
  ;(if (> (length examples) 10)
  ;    (let-values (((fst rst) (split-at examples 10)))
  ;      (append (process-examples fst return-continuation)
  ;              (process-examples rst return-continuation)))
  (with-handlers ([exn:fail? (λ(e)(return-continuation examples))]
                  [procedure? (λ(p)(p))])
  (let* ((file (make-pyret-temp-file))
         (prepped (prep-pyret-file-contents examples))
         (fileport (open-output-file file  #:exists 'replace)))
    (display IMAGE-IMPORT-STATEMENT fileport)
    (newline fileport)
    (for ((printstmt prepped))
      (display printstmt fileport)
      (newline fileport)
      )
    (close-output-port fileport)
    (eprintf ".")
    (define pyret-output (get-pyret-output file))
    (unless (check-didnt-fail (open-input-string pyret-output))
      (raise (λ()(newline)(error 
                           (format "Pyret raised an error while running your examples: \n ~a" 
                                   pyret-output)))))
    (let loop ((result (open-input-string pyret-output))
               (sofar '()))
              (let ((in (read result)))
                (cond [(eof-object? in) (reverse (cdr sofar))] ;; The first value of sofar will be the 
                                                               ;; #t return value from (system ...)
                      [(cons? in) (loop result (cons in sofar))]
                      [else (loop result sofar)]))))))