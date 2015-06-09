#lang racket
(require (for-syntax syntax/parse syntax/stx racket/list racket/bool
                     scribble/base
                     scribble/core
                     scribble/html-properties
                     racket/base
                     racket/string
                     racket/match
                     (prefix-in xml: xml)
                     "image-helpers.rkt")
         (for-meta 2 racket/base)
         scribble/base scribble/core scribble/html-properties
         racket/base
         (for-template scribble/core racket/base scribble/base))
(provide (for-syntax process-image-examples) image-examples)

(define-for-syntax (preproc-svg str stx)
  (xml->scribblable-syntax (xml:read-xml/element (open-input-string str)) stx))

(define-for-syntax (xml->scribblable-syntax xml stx)
  (define (attribute->assoc attr)
    (match attr
      [(xml:attribute start stop name val) (quasisyntax/loc stx (cons '#,(datum->syntax stx name) 
                                                   #,(datum->syntax stx (format "~a" val))))]))
  (define (stx-ident sym)
    (datum->syntax stx sym))
  (match xml
    [(xml:element start stop name attrs content)
     (with-syntax (#;[element (stx-ident 'element)]
                   #;[make-style (stx-ident 'make-style)]
                   #;[alt-tag (stx-ident 'alt-tag)]
                   #;[attributes (stx-ident 'attributes)]
                   [alttag (stx-ident (symbol->string name))]
                   [(attribs ...) (stx-ident (map attribute->assoc attrs))]
                   [(rest ...) (stx-ident (map (λ(x) (xml->scribblable-syntax x stx)) content))])
     (quasisyntax/loc stx (element (make-style #f
                            (list (alt-tag alttag)
                                  (attributes (list attribs ...))))
                (list rest ...))))]
    [else xml]))

(define-for-syntax (do-process-examples examples stx return-continuation)
  (eprintf ".")
  ((λ(list) (eprintf ".")
  (map (λ(pair) (cons (car pair) ((λ(s) (preproc-svg s stx)) (cdr pair)))) list))
       (process-examples examples return-continuation)))

;; Used for rendering Racket expressions as strings properly
(define-for-syntax (stringify stx)
   (let ((str (format "~v" (syntax->datum stx))))
     (if (equal? (first (string->list str)) #\')
         (substring str 1 (string-length str))
         str)))

;; Returns the string form of a raw-parsed Pyret expression
(define-for-syntax (proc-pyret-fun name args)
  (let* ((namestr (format "~a" (syntax->datum name)))
         (argstr  (format "~a" (syntax->datum args)))
         ;; Commas get printed as unquotes by format, but 
         ;; outside of that we want the ~a output.
         (fixargstr (regexp-replace* #rx" \\(unquote ([-A-Za-z0-9]*)\\)"
                                    argstr ", \\1"))
         (retstr  (format "~a~a" namestr fixargstr)))
    (datum->syntax name retstr)))

(begin-for-syntax
  (define-splicing-syntax-class rkt-equiv
    #:description "Racket 2htdp/image equivalent of Image example"
    #:attributes (expr)
    (pattern (~seq (~or #:racket #:rkt #:rkt-equiv #:racket-equiv #:equiv)
                   expr:expr)))
  (define-splicing-syntax-class stxpyret-example
    #:description "Example of image-producing code in Pyret"
    #:attributes (expr)
    (pattern (~seq expr:str))
    (pattern (~seq funname:id (args:expr ...))
             #:with expr (proc-pyret-fun #'funname #'(args ...))))
  (define-splicing-syntax-class img-example
    #:description "Image example prior to Pyret processing"
    #:attributes (rkt pyret)
    (pattern (~seq racket:rkt-equiv
                   example:stxpyret-example)
             #:with rkt #'racket.expr
             #:with pyret #'example.expr)
    (pattern (~seq example:stxpyret-example)
             #:with rkt #'#f
             #:with pyret #'example.expr))
  (define-splicing-syntax-class postproc-img-example
    #:description "Image example after Pyret processing"
    #:attributes (rkt pyretstr img)
    (pattern (~seq (~optional racket:rkt-equiv #:defaults ([racket #'#f]))
                   example:stxpyret-example
                   img:expr)
             #:with rkt (if (syntax->datum #'racket) #'racket.expr #'#f)
             #:with pyretstr #'example.expr))
  (define-splicing-syntax-class image-examples-stx
    #:description "Series of pyret-image examples"
    #:attributes (contents)
    (pattern (~seq (~literal image-examples) raw-contents ...)
             #:with contents #'(raw-contents ...))
    (pattern (~seq (~literal @image-examples) contents))))

(define-for-syntax (pyret-example . body)
  #`(element (make-style "pyret-highlight" 
                         (list (make-alt-tag "pre")))
             (list #,@body)))

;; Creates one example
#;(define-for-syntax (make-image-example racket pyret-str pyret-img)
  #;(define equiv-str
    (quasisyntax/loc racket
      #,(racket-comment racket)))
  (with-syntax ([equiv-str (pyret-example (string-join (racket-comment (syntax->datum racket)) "\n"))])
  (define spaced-pyret-img
    (quasisyntax/loc racket
      (element #f (list (hspace 4) #,pyret-img))))
  (if (syntax->datum racket) ;; racket != #f
      (quasisyntax/loc racket
        (element #f (list equiv-str
                          #,(pyret-example pyret-str)
                          #,spaced-pyret-img)))
      (if pyret-img
          #`(element #f (list #,(pyret-example pyret-str)
                              #,spaced-pyret-img))
          #`(element #f #,(pyret-example pyret-str))))))

(define-for-syntax (make-image-example racket pyret-str pyret-img)
  (define racket-equiv? (not (equal? (syntax->datum racket) #f)))
  (define has-image? (not (equal? pyret-img #f)))
  ;; Ellipses for splicing
  (with-syntax ([(equiv-str ...) (if racket-equiv? (list (pyret-example
                                                          (string-join (racket-comment
                                                                        (syntax->datum racket))
                                                                       "\n"))) (list))]
                [pyret-str (pyret-example (prettify/pyret (syntax->datum pyret-str)))]
                [(pyret-img ...) (if has-image? (list (quasisyntax/loc racket
                                                        (element #f (list (hspace 4) #,pyret-img)))) (list))])
    (syntax/loc racket
      (element #f (list equiv-str ... pyret-str pyret-img ...)))))

(define-for-syntax (normalize sym)
  (string->symbol (format "~a" sym)))

(define-for-syntax (preproc-examples template assocs stx)
  (let/ec return
  (let-values (((pyret placeholders) (split-placeholder-list assocs))
               ((call-proc-examples) (λ(py sx) (call/ec (λ(ec) (do-process-examples py sx ec))))))
    (when (or (empty? placeholders) (not USE-PYRET))
      (return stx))
    (let ((processed (call-proc-examples pyret stx)))
      (for ([proc-pair processed]
            [ph-pair placeholders])
        ;; Enforce our invariant
        ;; (process-examples should leave the order of the
        ;; list alone)
        ;; Side Note: I truly have no idea why (normalize ...) is
        ;; needed, but it wouldn't pass this check without it.
        (unless (symbol=? (normalize (car proc-pair))
                          (normalize (car ph-pair)))
          (error (format "Something went wrong during processing. Symbols: '~a '~a"
                         (car proc-pair) (car ph-pair))))
        (placeholder-set! (cdr ph-pair) (cdr proc-pair)))
      (make-reader-graph template)))))

(define-for-syntax (image-examples? stx)
  (and (stx-pair? stx)
       (let ((head (syntax->datum (stx-car stx))))
         (or (equal? head 'image-examples)
             (equal? head '@image-examples)))))

(define-for-syntax (image-examples->placeholders stx)
  (syntax-parse stx
    [() (values '() '())]
    [(frst:img-example rst ...)
     (let-values (((lst acc) (image-examples->placeholders #'(rst ...)))
                  ((plac) (make-placeholder #f)))
       (values (if (syntax->datum #'frst.rkt) ;; If a racket equivalent was given
                   (list* #'#:racket #'frst.rkt #'frst.pyret plac lst)
                   (list* #'frst.pyret plac lst))
               (cons (cons plac (syntax->datum #'frst.pyret)) acc)))]
    [else (raise-syntax-error #f "Invalid example" stx)]))

(define-for-syntax tick-mod
  (let ()
    (define count 0)
    (λ()(begin0 (equal? count 0)
                (set! count (modulo (add1 count) 30))))))
(define-for-syntax (get-placeholders stx (acc '()))
  ;; Kept for posterity
  #|(syntax-parse stx
    [(ex:image-examples-stx etc ...)
     (let-values (((rst acc) (get-placeholders #'(etc ...) acc))
                  ((fst facc) (image-examples->placeholders #'ex.contents)))
       (values
        (append (cons (datum->syntax stx 'image-examples) fst) rst)
        (append facc acc)))]
    [((nested ...) rst ...)
     (let*-values (((rst acc) (get-placeholders #'(rst ...) acc))
                   ((fst acc) (get-placeholders #'(nested ...) acc)))
       (values
        (cons fst rst)
        acc))]
    [(head rst ...)
     (let-values (((rst acc) (get-placeholders #'(rst ...) acc)))
       (values (cons #'head rst) acc))]
    [other (values #'other acc)])|#
  (cond [(not (stx-pair? stx)) (values stx acc)]
        [(image-examples? (stx-car stx))
         ;; DO NOT REMOVE
         ;; Why is this needed? Who knows. Scribble segfaults without this fprintf.
         (fprintf (open-output-string 'junk) "~a~n" (map syntax->datum (stx-cdr (stx-car stx))))
         (if (tick-mod) (eprintf ".") (void))
         (let-values (((rst acc) (get-placeholders (stx-cdr stx) acc))
                      ((fst facc) (image-examples->placeholders (stx-cdr (stx-car stx)))))
           
           (values
            (cons (cons #'image-examples fst) rst)
            (append facc acc)))]
        [(stx-pair? (stx-car stx))
         (let*-values (((rst acc) (get-placeholders (stx-cdr stx) acc))
                       ((fst acc) (get-placeholders (stx-car stx) acc)))
             (values
              (cons fst rst) acc))]
        [else
         (let-values (((rst acc) (get-placeholders (stx-cdr stx) acc)))
           (values (cons (stx-car stx) rst) acc))]))



;; Splits the given list of (<placeholder> . <pyret expression>)
;; into two lists of (<generated-symbol> . <placeholder>) and
;; (<generated-symbol> . <pyret expression>) (Note: Both generated
;; symbols are the same)
(define-for-syntax (split-placeholder-list lst)
  (define (make-entries pair (acc1 '()) (acc2 '()))
    (let ((sym (gensym 'pyret-img-)))
      (values (cons (cons sym (cdr pair)) acc1)
              (cons (cons sym (car pair)) acc2))))
  (for/fold ((sym-ph '())
             (sym-pyret '()))
            ((pair lst))
    (make-entries pair sym-ph sym-pyret)))

(define-for-syntax (un-list stx)
  (match stx
    [(cons a b) #`(#,(un-list a) #,@(un-list b))]
    [else stx]))

(define-for-syntax (process-image-examples stx)
  (let* ((raw-ret
   (let-values (((x y) (get-placeholders stx)))
     (preproc-examples x y stx)))
         (ret (if (cons? raw-ret) (un-list raw-ret) raw-ret)))
    ret))

(define-for-syntax (parse-image-example stx)
  (if USE-PYRET
      (syntax-parse stx
        [(ex:postproc-img-example)
         (make-image-example #'ex.rkt #'ex.pyretstr #'ex.img)])
      (syntax-parse stx
        [(ex:img-example)
         (make-image-example #'ex.rkt #'ex.pyretstr #'ex.rkt)])))
         

(define-syntax (image-examples stx)
  (define (do-example-parses stx)
    (if USE-PYRET
        (syntax-parse stx
          [(ex:postproc-img-example rst ...)
           (quasisyntax/loc stx
             (#,(parse-image-example #'ex) #,@(do-example-parses #'(rst ...))))]
          [() stx])
        (syntax-parse stx
          [(ex:img-example rst ...)
           (quasisyntax/loc stx
             (#,(parse-image-example #'ex) #,@(do-example-parses #'(rst ...))))])))
  (syntax-parse stx
    [(examples:image-examples-stx)
     (let ((example-parses (do-example-parses #'examples.contents)))
     #`(nested
        #:style (make-style "examples" (cons (make-alt-tag "div") (list "style.css")))
               (para (bold "Examples:"))
               #,@example-parses))]))
