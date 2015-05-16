#lang scribble/base
@(require "image-syntax.rkt"
          (except-in racket/base #%module-begin)
          scribble/base
          scribble/core
          
          (for-meta 2 racket/base)
          (for-syntax 
           racket/path
           (except-in racket/base #%module-begin)))

@(provide (except-out (all-from-out scribble/base/lang) #%module-begin)
          (all-from-out racket/base)
          (all-from-out scribble/base)
          (all-from-out scribble/core)
          (for-syntax (all-from-out racket/base))
          (rename-out (modbegin #%module-begin))
          image-examples)

@(define-syntax (modbegin stx)
   (syntax-case stx ()
     [(_ . body)
      (begin
        (newline)
        (eprintf "Processing image examples in ~a ."
                         (path->string (file-name-from-path 
                                        (syntax-source stx))))
        (let ((processed (process-image-examples #'body)))
          (eprintf "done.~n")
          (quasisyntax/loc stx
            (#%module-begin 
             doc values ()
             #,@processed))))]))