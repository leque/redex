#lang racket/load

(module good:simple-contexts racket
  (require redex)
  
  (define-language ectxt
    [e a
       (e e)]
    [E the-hole
       (E e)
       (e E)]
    [a variable-not-otherwise-mentioned])
  
  (define (decomposer t)
    (list* (list 'the-hole t)
           (match t
             [(list e_1 e_2)
              (append
               (for/list ([d_lhs (in-list (decomposer e_1))])
                 (match-define (list E_lhs p_lhs) d_lhs)
                 (list (list E_lhs e_2) p_lhs))
               (for/list ([d_rhs (in-list (decomposer e_2))])
                 (match-define (list E_rhs p_rhs) d_rhs)
                 (list (list e_1 E_rhs) p_rhs)))]
             [_
              empty])))
  
  (define plugger 
    (term-match/single
     ectxt
     [(the-hole e_p)
      (term e_p)]
     [((E e_2) e_p)
      (term (,(plugger (term (E e_p))) e_2))]
     [((e_1 E) e_p)
      (term (e_1 ,(plugger (term (E e_p)))))]))
  
  (define (property-1 t)
    (for/and ([d (in-list (decomposer t))])
      (equal? t (plugger d))))
  
  (printf "\tProperty 1:\n")
  (redex-check ectxt e (property-1 (term e))))

(printf "Expressions without holes: [Good]\n")
(require 'good:simple-contexts)
(newline)

(module broken-p1:complicated-contexts racket
  (require redex)
  
  (define-language ectxt
    [e a
       the-hole
       (e e)]
    [E e]
    [a variable-not-otherwise-mentioned])
  
  (define (decomposer t)
    (list* (list 'the-hole t)
           (match t
             [(list e_1 e_2)
              (append
               (for/list ([d_lhs (in-list (decomposer e_1))])
                 (match-define (list E_lhs p_lhs) d_lhs)
                 (list (list E_lhs e_2) p_lhs))
               (for/list ([d_rhs (in-list (decomposer e_2))])
                 (match-define (list E_rhs p_rhs) d_rhs)
                 (list (list e_1 E_rhs) p_rhs)))]
             [_
              empty])))
  
  (define plugger 
    (term-match/single
     ectxt
     [(a e_p)
      (term a)]
     [(the-hole e_p)
      (term e_p)]
     [((e_1 e_2) e_p)
      (term (,(plugger (term (e_1 e_p))) ,(plugger (term (e_2 e_p)))))]))
  
  (define (property-1 t)
    (for/and ([d (in-list (decomposer t))])
      (equal? t (plugger d))))
  
  (printf "\tProperty 1:\n")
  (redex-check ectxt e (property-1 (term e))))

(printf "Expressions with holes: [Bad]\n")
(require 'broken-p1:complicated-contexts)
(newline)

(module broken-p2:complicated-contexts racket
  (require redex)
  
  (define-language ectxt
    [e a
       the-hole
       (the-hide-hole e)
       (e e)]
    [a variable-not-otherwise-mentioned])
  
  (define (decomposer t)
    (list* (list 'the-hole t)
           (match t
             [(list 'the-hide-hole e_1)
              empty]
             [(list e_1 e_2)
              (append
               (for/list ([d_lhs (in-list (decomposer e_1))])
                 (match-define (list E_lhs p_lhs) d_lhs)
                 (list (list E_lhs (list 'the-hide-hole e_2)) p_lhs))
               (for/list ([d_rhs (in-list (decomposer e_2))])
                 (match-define (list E_rhs p_rhs) d_rhs)
                 (list (list (list 'the-hide-hole e_1) E_rhs) p_rhs)))]
             [_
              empty])))
  
  (define plugger
    (term-match/single
     ectxt
     [(a any_p)
      (term a)]
     [(the-hole any_p)
      (term any_p)]
     [((the-hide-hole e) any_p)
      (term e)]
     [((e_1 e_2) any_p)
      (term (,(plugger (term (e_1 any_p))) ,(plugger (term (e_2 any_p)))))]))
  
  (define (property-1 t)
    (for/and ([d (in-list (decomposer t))])
      (define p (plugger d))
      (equal? t p)))
  
  (printf "\tProperty 1:\n")
  (redex-check ectxt e 
               (property-1 (term e)))
  
  (define (property-2 E1 E2 e)
    (equal? (plugger (list E1 (plugger (list E2 e))))
            (plugger (list (plugger (list E1 E2)) e))))
  
  (printf "\tProperty 2:\n")
  (redex-check ectxt (e_1 e_2 e)
               (property-2 (term e_1) (term e_2) (term e))))

(printf "Expressions with holes & hide-hole: [Good/Bad]\n")
(require 'broken-p2:complicated-contexts)
(newline)

(module unknown:complicated-contexts racket
  (require redex)
  
  (define-language ectxt
    [e a
       the-hole
       (the-hide-hole e)
       (e e)]
    [a variable-not-otherwise-mentioned])
  
  (define (decomposer t)
    (list* (list 'the-hole t)
           (match t
             [(list 'the-hide-hole e_1)
              empty]
             [(list e_1 e_2)
              (append
               (for/list ([d_lhs (in-list (decomposer e_1))])
                 (match-define (list E_lhs p_lhs) d_lhs)
                 (list (list E_lhs (list 'the-hide-hole e_2)) p_lhs))
               (for/list ([d_rhs (in-list (decomposer e_2))])
                 (match-define (list E_rhs p_rhs) d_rhs)
                 (list (list (list 'the-hide-hole e_1) E_rhs) p_rhs)))]
             [_
              empty])))
  
  (define plugger
    (term-match/single
     ectxt
     [(a any_p)
      (term a)]
     [(the-hole any_p)
      (term any_p)]
     [((the-hide-hole e) any_p)
      (term e)]
     [((e_1 e_2) any_p)
      (term (,(plugger (term (e_1 any_p))) ,(plugger (term (e_2 any_p)))))]))
  
  (define (property-1 t)
    (for/and ([d (in-list (decomposer t))])
      (define p (plugger d))
      (equal? t p)))
  
  (printf "\tProperty 1:\n")
  (redex-check ectxt e 
               (property-1 (term e)))
  
  (define (valid-context? t)
    (define loop
      (term-match/single
       ectxt
       [a 0]
       [the-hole 1]
       [(the-hide-hole e) 0]
       [(e_1 e_2)
        (+ (loop (term e_1))
           (loop (term e_2)))]))
    (= (loop t) 1))
  
  (define (property-2a t)
    (for/and ([d (in-list (decomposer t))])
      (match-define (list E e) d)
      (valid-context? E)))
  
  (printf "\tProperty 2a:\n")
  (redex-check ectxt e 
               (property-2a (term e)))
  
  (require (for-syntax syntax/parse))
  (define-syntax (mechadebug stx)
    (syntax-parse 
     stx
     [(_ (e:expr ...))
      (with-syntax ([(x ...) (generate-temporaries #'(e ...))])
        (syntax/loc stx
          (let* ([x (mechadebug e)]
                 ...
                 [c (x ...)])
            (printf "~S => ~S\n" `([e = ,x] ...) c)
            c)))]
     [(_ v:id)
      (syntax/loc stx
        v)]))
  
  (define (property-2 E1 E2 e)
    (newline)
    (mechadebug
     (equal? (plugger (list E1 (plugger (list E2 e))))
             (plugger (list (plugger (list E1 E2)) e)))))
  
  (define-syntax-rule (implies p q)
    (or (not p) q))
  
  (printf "\tProperty 2:\n")
  (test-equal (property-2 (term ((the-hide-hole the-hole) the-hole))
                          (term the-hole)
                          (term A))
               #t)
  #;(redex-check ectxt (e_1 e_2 e)
               (implies (and (valid-context? (term e_1)) (valid-context? (term e_2)))
                        (property-2 (term e_1) (term e_2) (term e))))
  
  (test-results))

(printf "Expressions with holes & hide-hole, p2 variation: [Good/Bad]\n")
(require 'unknown:complicated-contexts)
(newline)

(module hide-hole-preservation racket
  (require redex)
  
  (define-language ectxt
    [e a
       the-hole
       (the-hide-hole e)
       (e e)]
    [a variable-not-otherwise-mentioned])
  
  (define (decomposer t)
    (list* (list 'the-hole t)
           (match t
             [(list 'the-hide-hole e_1)
              empty]
             [(list e_1 e_2)
              (append
               (for/list ([d_lhs (in-list (decomposer e_1))])
                 (match-define (list E_lhs p_lhs) d_lhs)
                 (list (list E_lhs (list 'the-hide-hole e_2)) p_lhs))
               (for/list ([d_rhs (in-list (decomposer e_2))])
                 (match-define (list E_rhs p_rhs) d_rhs)
                 (list (list (list 'the-hide-hole e_1) E_rhs) p_rhs)))]
             [_
              empty])))
  
  (define plugger
    (term-match/single
     ectxt
     [(a any_p)
      (term a)]
     [(the-hole any_p)
      (term any_p)]
     [((the-hide-hole e) any_p)
      (term (the-hide-hole e))]
     [((e_1 e_2) any_p)
      (term (,(plugger (term (e_1 any_p))) ,(plugger (term (e_2 any_p)))))]))
  
  (define (property-1 t)
    (for/and ([d (in-list (decomposer t))])
      (define p (plugger d))
      (equal? t p)))
  
  (printf "\tProperty 1:\n")
  (redex-check ectxt e 
               (property-1 (term e)))
  
  (define (valid-context? t)
    (define loop
      (term-match/single
       ectxt
       [a 0]
       [the-hole 1]
       [(the-hide-hole e) 0]
       [(e_1 e_2)
        (+ (loop (term e_1))
           (loop (term e_2)))]))
    (= (loop t) 1))
  
  (define (property-2a t)
    (for/and ([d (in-list (decomposer t))])
      (match-define (list E e) d)
      (valid-context? E)))
  
  (printf "\tProperty 2a:\n")
  (redex-check ectxt e 
               (property-2a (term e)))
  
  (define (property-2 E1 E2 e)
    (equal? (plugger (list E1 (plugger (list E2 e))))
            (plugger (list (plugger (list E1 E2)) e))))
  
  (define-syntax-rule (implies p q)
    (or (not p) q))
  
  (printf "\tProperty 2:\n")
  (test-equal (property-2 (term ((the-hide-hole the-hole) the-hole))
                          (term the-hole)
                          (term A))
               #t)
  (redex-check ectxt (e_1 e_2 e)
               (implies (and (valid-context? (term e_1)) (valid-context? (term e_2)))
                        (property-2 (term e_1) (term e_2) (term e))))
  
  (test-results))

(printf "hide-hole preserving plugger, p2 variation: [Bad/Good]\n")
(require 'hide-hole-preservation)
(newline)

(module multi-result-plug racket
  (require redex)
  
  (define-language ectxt
    [e a
       the-hole
       (e e)]
    [a variable-not-otherwise-mentioned])
  
  (define (decomposer t)
    (list* (list 'the-hole t)
           (match t
             [(list e_1 e_2)
              (append
               (for/list ([d_lhs (in-list (decomposer e_1))])
                 (match-define (list E_lhs p_lhs) d_lhs)
                 (list (list E_lhs e_2) p_lhs))
               (for/list ([d_rhs (in-list (decomposer e_2))])
                 (match-define (list E_rhs p_rhs) d_rhs)
                 (list (list e_1 E_rhs) p_rhs)))]
             [_
              empty])))
  
  (define plugger
    (term-match/single
     ectxt
     [(a any_p)
      empty]
     [(the-hole any_p)
      (list (term any_p))]
     [((e_1 e_2) any_p)
      (append 
       (for/list ([p_lhs (in-list (plugger (term (e_1 any_p))))])
         (list p_lhs (term e_2)))
       (for/list ([p_rhs (in-list (plugger (term (e_2 any_p))))])
         (list (term e_1) p_rhs)))]))
  
  (define (property-1a t)
    (for/and ([d (in-list (decomposer t))])
      (for/or ([p (in-list (plugger d))])
        (equal? t p))))
  (define (property-1b t u)
    (for/and ([p (in-list (plugger (list t u)))])
      (for/or ([d (in-list (decomposer p))])
        (equal? (list t u) d))))
  
  (printf "\tProperty 1a:\n")
  (redex-check ectxt e 
               (property-1a (term e)))
  (printf "\tProperty 1b:\n")
  (redex-check ectxt (e_1 e_2) 
               (property-1b (term e_1) (term e_2)))
  
  (define (property-2 t u v)
    (define (concat-map f xs)
      (apply append (map f xs)))
    (define tu-v
      (concat-map (λ (w) (plugger (list w v)))
                  (plugger (list t u))))
    (define t-uv
      (concat-map (λ (w) (plugger (list t w)))
                  (plugger (list u v))))
    (and (for/and ([r tu-v]) (member r t-uv))
         (for/and ([r t-uv]) (member r tu-v))))
  
  (printf "\tProperty 2:\n")
  (redex-check ectxt (e_1 e_2 e_3)
               (property-2 (term e_1) (term e_2) (term e_3)))
  
  (define num-holes
    (term-match/single
     ectxt
     [a 0]
     [the-hole 1]
     [(e_1 e_2)
      (+ (num-holes (term e_1))
         (num-holes (term e_2)))]))
  
  (printf "\tProperty 2’:\n")
  (redex-check ectxt (e_1 e_2 e_3)
               (or (zero? (num-holes (term e_2)))
                   (property-2 (term e_1) (term e_2) (term e_3))))
  
  (printf "\tProperty 2’’:\n")
  (redex-check ectxt (e_1 e_2 e_3)
               (or (not (= 1 (num-holes (term e_1)) (num-holes (term e_2))))
                   (property-2 (term e_1) (term e_2) (term e_3)))))

(printf "multi-result plug, variations on p1 and p2: Good?\n")
(require 'multi-result-plug)
(newline)