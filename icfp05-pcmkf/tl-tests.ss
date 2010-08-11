#lang scheme
(require redex
         scheme/package
         "tl.ss"
         "common.ss")

;; Tests
;;; Values
(test-->> -->_tl
          '(/ mt (λ (x) x))
          '(/ mt (λ (x) x)))
(test-->> -->_tl
          '(/ mt ("nil"))
          '(/ mt ("nil")))
(test-->> -->_tl
          '(/ mt ("S" ("0")))
          '(/ mt ("S" ("0"))))
(test-->> -->_tl
          '(/ mt (! "x"))
          '(/ mt (! "x")))

;;; Applications
(test-->> -->_tl 
          '(/ mt ((λ (x) x) ("nil")))
          '(/ mt ("nil")))

;;; Store applications
(test-->> -->_tl
          '(/ (snoc mt ["x" -> (λ (x) ("nil"))])
              ((! "x") ("0")))
          '(/ (snoc mt ["x" -> (λ (x) ("nil"))])
              ("nil")))

;;; Letrec
(test-->> -->_tl
          '(/ mt (letrec (["x" (λ (x) ("nil"))])
                   ("foo")))
          '(/ (snoc mt ["x" -> (λ (x) ("nil"))])
              ("foo")))
(test-->> -->_tl
          '(/ mt (letrec (["x" (λ (x) ("nil"))])
                   ((! "x") ("0"))))
          '(/ (snoc mt ["x" -> (λ (x) ("nil"))])
              ("nil")))

;;; Case
(test-->> -->_tl
          '(/ mt (case ("S" ("0"))
                   [("S" n) => n]
                   [("0") => ("0")]))
          '(/ mt ("0")))
(test-->> -->_tl
          '(/ mt (case ("S" ("0"))
                   [("0") => ("0")]
                   [("S" n) => n]))
          '(/ mt ("0")))

; Store case
(test-->> -->_tl
          '(/ mt (letrec (["x" ("S" ("0"))])
                   (case (! "x")
                     [("S" n) => n]
                     [("0") => ("0")])))
          '(/ (snoc mt ["x" -> ("S" ("0"))])
              ("0")))

;; w-c-m
(test-->> -->_tl
          `(/ mt (w-c-m ,(num 1) ,(num 2)))
          `(/ mt ,(num 2)))
(test-->> -->_tl
          `(/ mt (w-c-m ,(num 1) (w-c-m ,(num 3) ,(num 2))))
          `(/ mt ,(num 2)))
(test-->> -->_tl
          `(/ mt (w-c-m ,(num 1) ((λ (x) x) ,(num 2))))
          `(/ mt ,(num 2)))

;; c-c-m
(test-->> -->_tl
          `(/ mt (c-c-m))
          `(/ mt ("nil")))
(test-->> -->_tl
          `(/ mt (w-c-m ,(num 1) (c-c-m)))
          `(/ mt ("cons" ,(num 1) ("nil"))))
(test-->> -->_tl
          `(/ mt (w-c-m ,(num 1) (w-c-m ,(num 2) (c-c-m))))
          `(/ mt ("cons" ,(num 2) ("nil"))))
(test-->> -->_tl
          `(/ mt (w-c-m ,(num 1) ((λ (x) x) (w-c-m ,(num 2) (c-c-m)))))
          `(/ mt ("cons" ,(num 1) ("cons" ,(num 2) ("nil")))))

;; abort
(test-->> -->_tl
          `(/ mt (abort ,(num 2)))
          `(/ mt ,(num 2)))
(test-->> -->_tl
          `(/ mt ((λ (x) x) (abort ,(num 2))))
          `(/ mt ,(num 2)))

;; arith
(test-->> -->_tl
          `(/ mt ,(:let 'x (num 1) 'x))
          `(/ mt ,(num 1)))
(test-->> -->_tl
          `(/ mt ,(with-arith (num 1)))
          `(/ ,arith-store ,(num 1)))
(test-->> -->_tl
          `(/ mt ,(with-arith `((! "+") ,(num 1) ,(num 1))))
          `(/ ,arith-store ,(num 2)))
(test-->> -->_tl
          `(/ mt ,(with-arith `((! "*") ,(num 2) ,(num 2))))
          `(/ ,arith-store ,(num 4)))
(test-->> -->_tl
          `(/ mt ,(with-arith `((! "=") ,(num 2) ,(num 2))))
          `(/ ,arith-store ("#t")))
(test-->> -->_tl
          `(/ mt ,(with-arith `((! "=") ,(num 2) ,(num 3))))
          `(/ ,arith-store ("#f")))
(test-->> -->_tl
          `(/ mt ,(with-arith `((! "-") ,(num 3) ,(num 2))))
          `(/ ,arith-store ,(num 1)))
(test-->> -->_tl
          `(/ mt ,(with-arith (:if '("#t") (num 1) (num 2))))
          `(/ ,arith-store ,(num 1)))
(test-->> -->_tl
          `(/ mt ,(with-arith (:if '("#f") (num 1) (num 2))))
          `(/ ,arith-store ,(num 2)))

;; fact
(package-begin
 (define fact-impl
   `(λ (n)
      ,(:if `((! "=") n ,(num 0))
            (:let 'marks '(c-c-m)
                  '(abort marks))
            `(w-c-m n
                    ,(:let 'sub1-fact
                           (:let 'sub1 `((! "-") n ,(num 1))
                                 `((! "fact") sub1))
                           `((! "*") n sub1-fact))))))
 (define fact-tr-impl
   `(λ (n a)
      ,(:if `((! "=") n ,(num 0))
            (:let 'marks '(c-c-m)
                  '(abort marks))
            `(w-c-m n
                    ,(:let 'sub1 `((! "-") n ,(num 1))
                           (:let 'multa `((! "*") n a)
                                 `((! "fact-tr") sub1 multa)))))))
 (define (test-fact n)
   (test-->> -->_tl
             `(/ mt ,(with-arith
                      `(letrec (["fact" ,fact-impl])
                         ((! "fact") ,(num n)))))
             `(/ (snoc ,arith-store ["fact" -> ,fact-impl])
                 ,(lst (build-list n (lambda (i) (num (- n i))))))))
 (define (test-fact-tr n)
   (test-->> -->_tl
             `(/ mt ,(with-arith
                      `(letrec (["fact-tr" ,fact-tr-impl])
                         ((! "fact-tr") ,(num n) ,(num 1)))))
             `(/ (snoc ,arith-store ["fact-tr" -> ,fact-tr-impl])
                 ,(lst (list (num 1))))))
 (for ([i (in-range 1 4)]) (test-fact i))
 (for ([i (in-range 1 4)]) (test-fact-tr i)))

(test-results)