;;;; conditionals.lisp

(uiop:define-package #:marie/conditionals
  (:use #:cl
        #:marie/defs)
  (:export #:it))

(in-package #:marie/conditionals)

(defm map-and (fn &rest args)
  "Return true if FN returns true for all items in ARGS."
  `(and ,@(loop :for arg :in args :collect `(funcall ,fn ,arg))
        t))

(defm map-or (fn &rest args)
  "Return true if FN returns true for at least one item in ARGS."
  `(or ,@(loop :for arg :in args :collect `(funcall ,fn ,arg))
       nil))

(defm rmap-and (value &rest fns)
  "Return true if all functions in FNS return true for VALUE."
  `(and ,@(loop :for fn :in fns :collect `(funcall ,fn ,value))
        t))

(defm rmap-or (value &rest fns)
  "Return true if at least one function in FNS return true for VALUE."
  `(or ,@(loop :for fn :in fns :collect `(funcall ,fn ,value))
       nil))

(defm (logical-and ∧) (&body body)
  "Return true if all forms in BODY evaluates to true."
  `(when (and ,@body)
     t))

(defm (logical-or ∨) (&body body)
  "Return true if all forms in BODY evaluates to false."
  `(when (or ,@body)
     t))

(defm ¬ (arg)
  "Return the negation of ARG."
  `(not ,arg))

(defm when-let (bindings &body forms)
  "Use BINDINGS like with LET, then evaluate FORMS if all BINDINGS evaluate to a
true value. This is ALEXANDRIA:WHEN-LET."
  (let* ((binding-list (if (and (consp bindings) (symbolp (car bindings)))
                           (list bindings)
                           bindings))
         (variables (mapcar #'car binding-list)))
    `(let ,binding-list
       (when (and ,@variables)
         ,@forms))))

(defm when-let* (bindings &body body)
  "Use BINDINGS like with LET*, then evaluate FORMS if all BINDINGS evaluate to
a true value. This is ALEXANDRIA:WHEN-LET*."
  (let ((binding-list (if (and (consp bindings) (symbolp (car bindings)))
                          (list bindings)
                          bindings)))
    (labels ((bind (bindings body)
               (if bindings
                   `(let (,(car bindings))
                      (when ,(caar bindings)
                        ,(bind (cdr bindings) body)))
                   `(progn ,@body))))
      (bind binding-list body))))

(def true-false-p (x y)
  "Return true if X is true and Y is false."
  (if (and x (null y)) t nil))

(def false-true-p (x y)
  "Return true if X is false and Y is true."
  (true-false-p y x))

(def true-true-p (x y)
  "Return true if X is true and Y is true."
  (and x y t))

(defm aif (test-form then-form &optional else-form)
  "Anaphoric IF."
  `(let ((it ,test-form))
     (if it ,then-form ,else-form)))

(defm awhen (test-form &body then-form)
  "Anaphoric WHEN."
  `(aif ,test-form
        (progn ,@then-form)))

(defm aand (&rest args)
  "Anaphoric AND."
  (cond ((null args) t)
        ((null (cdr args)) (car args))
        (t `(aif ,(car args) (aand ,@(cdr args))))))

(defm acond (&rest clauses)
  "Anaphoric COND."
  (if (null clauses)
      nil
      (let ((clause (car clauses))
            (symbol (gensym)))
        `(let ((,symbol ,(car clause)))
           (if ,symbol
               (let ((it ,symbol)) ,@(cdr clause))
               (acond ,@(cdr clauses)))))))

(defun omega-reader (stream char)
  "Define the reader for Ω, so that Ω can be used to refer to the anaphora."
  (declare (ignore stream char))
  'MARIE/CONDITIONALS:IT)

(set-macro-character #\Ω #'omega-reader)
