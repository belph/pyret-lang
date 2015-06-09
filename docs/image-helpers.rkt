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
          racket/pretty
          (prefix-in xml: xml)
          (for-meta 2 racket/base)
          (for-template scribble/core scribble/html-properties)
          (for-syntax racket/base syntax/parse racket/list))

(provide USE-PYRET
         racket-comment
         process-examples
         prettify/pyret)

(define DEBUG-IMAGES #f)

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
                    (if DEBUG-IMAGES
                        " . ' + torepr(draw-debug("
                        " . ' + torepr(draw-svg(")
                    (fix-spacing exmp)
                    ").tosource()) + ')')")]))

(define (prep-pyret-file-contents examples)
  ;; print( '(' + <examples (joined with ' + ')> + ')' )
  ;(string-append "print('(' + " 
                 (map prep-image-example examples))
                 ;" + ')')"))

(define (check-didnt-fail port)
  (cons? (regexp-match #px"The program didn't define any tests[.\n]{,5}$" (port->string port))))

(define (fix-spacing str)
  (regexp-replace* #rx" (?:(?!cases|constructor)([_a-zA-Z][_a-zA-Z0-9]*(?:-+[_a-zA-Z0-9]+)*)) \\("
                   str " \\1("))

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
    
  (let* ((file (make-pyret-temp-file))
         (prepped (prep-pyret-file-contents examples))
         (fileport (with-handlers ([exn:fail? (λ(e)(return-continuation examples))])
                     (open-output-file file  #:exists 'replace))))
    
    (define filename (file-name-from-path file))
    (define filename-rx (regexp (format "~a: line ([0-9]+)" filename)))
    (define (get-line-range start end)
      (let* ((best-start (get-best-line start))
             (best-end (get-best-line end))
             (rel-keys (sort (filter (λ(x)(<= best-start x best-end)) (hash-keys examples-in-file)) <))
             (rel-lines (flatten (map (λ(key)(string-split (hash-ref examples-in-file key) "\n")) rel-keys)))
             (line-padding (λ(lineno) (list->string (build-list (- (string-length (number->string best-end))
                                                                   (string-length (number->string lineno))) (λ(n)#\Space))))))
        (string-join (for/list ((lineno (in-range best-start best-end))
                                (linestr rel-lines))
                       (format "~a~a  ~a" (line-padding lineno) lineno linestr)) "\n")))
        
        
    (port-count-lines! fileport)
    (define (register-example example)
      (let-values (((line col pos) (port-next-location fileport)))
        (if (hash-has-key? examples-in-file line)
            (raise (λ()(error (format "Multiple expressions on one line: ~nline: ~a~nold contents: ~a~nnew contents: ~a" 
                           line (hash-ref examples-in-file line) example))))
            (hash-set! examples-in-file line example))))
    (define (get-best-line lineno)
      (define (max-<= x)
        (λ(a b) (if (or (> a x) (> b a)) b a)))
      ;; First example line is on line 2
      (foldr (max-<= lineno) 2 (hash-keys examples-in-file)))
    (define (fetch-line lineno)
      (let ((bestline (get-best-line lineno)))
        (format (string-append 
                 "~nRegion of error:~n~a"
                 "~nHint: It looks like the problem might be with this example: ~n~a~n~n")
                (get-line-range (- lineno 10) (+ lineno 10))
                (hash-ref examples-in-file bestline))))
    (define (fetch-from-error errmsg)
      (let ((rxp-startRow (regexp-match #rx"startRow: ([0-9]+)" errmsg))
            (rxp-pyret-stack (regexp-match filename-rx errmsg)))
        (cond [(pair? rxp-startRow) (fetch-line (string->number (cadr rxp-startRow)))]
              [(pair? rxp-pyret-stack) (fetch-line (string->number (cadr rxp-pyret-stack)))]
              [else   ""])))
    (display IMAGE-IMPORT-STATEMENT fileport)
    (newline fileport)
    (for ((printstmt prepped))
      (register-example printstmt)
      (display printstmt fileport)
      
      (newline fileport)
      )
    (close-output-port fileport)
    (eprintf ".")
    (define pyret-output (get-pyret-output file))
    (unless (check-didnt-fail (open-input-string pyret-output))
      (newline)(error 
                           (format "Pyret raised an error while running your examples: \n ~a~a" 
                                   pyret-output
                                   (fetch-from-error pyret-output))))
    (let loop ((result (open-input-string pyret-output))
               (sofar '()))
              (let ((in (read result)))
                (cond [(eof-object? in) (reverse (cdr sofar))] ;; The first value of sofar will be the 
                                                               ;; #t return value from (system ...)
                      [(cons? in) (loop result (cons in sofar))]
                      [else (loop result sofar)])))))

(pretty-print-columns 50)
(define (racket-comment datum)
  (define EXAMPLES-PREFIX "# Racket equivalent: ")
  (define BUFFER (list->string (cons #\# (build-list 
                                          (sub1 (string-length EXAMPLES-PREFIX)) 
                                          (λ(n)#\Space)))))
  (define prt (open-output-string))
  (pretty-write datum prt)
  (define pretty-str (begin0 (get-output-string prt)
                             (close-output-port prt)))
  (let ((split-up (string-split pretty-str "\n")))
    (cons (string-append EXAMPLES-PREFIX (car split-up)) 
          (map (λ(s)(string-append BUFFER s)) (cdr split-up)))))

(define/contract (prettify/pyret example)
  (string? . -> . string?)
  (define prt (open-output-string))
  (parameterize ([pretty-print-columns 80])
    (pretty-display (prep-example-string example) prt))
  (begin0 (fixup-str (get-output-string prt))
          (close-output-port prt)))

(define (fixup-str s)
  (define FIRSTLASTPAREN #rx"(?:^\\()|(?:\\)$)")
  (define PARENRX #px"\\s*'?\\(")
  (define SINGLECOMMARX #px"\\s*\n\\s*,[ ]*\n")
  (define SPACECOMMA #px"\\s*,(\\s*)")
  (define (do-replacements s . rpl)
    (if (empty? rpl) s
        (apply do-replacements (regexp-replace* (caar rpl) s (cdar rpl)) (cdr rpl))))
  (do-replacements s
                   (cons PARENRX "(")
                   (cons SINGLECOMMARX ",\n")
                   (cons SPACECOMMA ",\\1")
                   (cons FIRSTLASTPAREN "")))

(define (prep-example-string s)
  (define raw-read (read (open-input-string (string-append "(" s ")"))))
  (define (smartcons a d)
    (match a
      [(list "unquote" sym) (cons "," (cons sym d))]
      [else (cons a d)]))
  (define (deep-map/splice f lst)
    (cond [(empty? lst) lst]
          [(cons? (car lst)) (smartcons (deep-map/splice f (car lst))
                                   (deep-map/splice f (cdr lst)))]
          [else (smartcons (f (car lst)) (deep-map/splice f (cdr lst)))]))
  (deep-map/splice (λ(s)(format "~a" s)) raw-read))
  