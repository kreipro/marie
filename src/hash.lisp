;;;; -*- mode: lisp; syntax: common-lisp; base: 10; coding: utf-8-unix; external-format: (:utf-8 :eol-style :lf); -*-
;;;; hash.lisp --- utilities for dealing with sequences

(uiop:define-package #:marie/src/hash
    (:use #:cl
	  #:marie/src/definitions
          #:marie/src/sequences)
  (:export #:ordered-hash-table
           #:ordered-hash-table-p))

(in-package #:marie/src/hash)


;;; Ordered Hashtable
;;; keeps the keys in the order they were put in a hash table

(declaim (inline make-ordered-hash-table%))
(defstruct (ordered-hash-table
            (:constructor make-ordered-hash-table%)
            (:predicate ordered-hash-table-p)
            (:print-object print-ordered-hash-table)
            (:copier nil))
  (hashtable nil :type (or null hash-table) :read-only t)
  (keys (list) :type list))

(def make-ordered-hash-table (&key (test 'eql) 
                                  (size 7) 
                                  (rehash-size 1.5) 
                                  (rehash-threshold 1.0))
  (make-ordered-hash-table%
   :hashtable (make-hash-table :test test
                               :size size
                               :rehash-size rehash-size
                               :rehash-threshold rehash-threshold)))

(defun print-ordered-hash-table (hash-table stream)
  (print-unreadable-object (hash-table stream :type t :identity t)
    (let ((hashtable (ordered-hash-table-hashtable hash-table)))
      (format stream "~A ~D"
              (hash-table-test hashtable)
              (hash-table-count hashtable)))))

(declaim (inline ordered-hash-table-count))
(def ordered-hash-table-count (hash-table)
  (declare (type ordered-hash-table hash-table))
  (hash-table-count (ordered-hash-table-hashtable hash-table)))
(declaim (notinline ordered-hash-table-count))

(declaim (inline get-ordered-hash))
(def get-ordered-hash (key hash-table &optional default)
  (declare (type ordered-hash-table hash-table))
  (gethash key (ordered-hash-table-hashtable hash-table) default))
(declaim (notinline get-ordered-hash))

(defun (setf get-ordered-hash) (value key hash-table &optional default)
  (declare (type ordered-hash-table hash-table))
  (let ((hashtable (ordered-hash-table-hashtable hash-table)))
    (unless (member key (ordered-hash-table-keys hash-table)
                    :test (hash-table-test hashtable))
      (push key (ordered-hash-table-keys hash-table)))
    (setf (gethash key hashtable default) value)))

(def remove-ordered-hash (key hash-table)
  (declare (type ordered-hash-table hash-table))
  (let ((hashtable (ordered-hash-table-hashtable hash-table)))
    (when (remhash key hashtable)
      (setf (ordered-hash-table-keys hash-table)
            (delete key (ordered-hash-table-keys hash-table)
                    :test (hash-table-test hashtable)))
      t)))

(def clear-ordered-hash (hash-table)
  (declare (type ordered-hash-table hash-table))
  (clrhash (ordered-hash-table-hashtable hash-table))
  (setf (ordered-hash-table-keys hash-table) (list))
  hash-table)

(def ordered-hash-keys (hash-table)
  (declare (type ordered-hash-table hash-table))
  (reverse (ordered-hash-table-keys hash-table)))

(def show-ordered-hash-table (hash-table)
  "Print the contents of HASH-TABLE."
  (declare (type ordered-hash-table hash-table))
  (maphash #'(lambda (k v)
               (format t "~S => ~S~%" k v)
               (force-output *standard-output*))
           (ordered-hash-table-hashtable hash-table)))

(def show-ordered-hash-table* (hash-table &optional (pad 0))
  "Print the contents of hash table TABLE recursively."
  (declare (type (or ordered-hash-table hash-table) hash-table))
  (let ((hashtable
          (if (ordered-hash-table-p hash-table)
              (ordered-hash-table-hashtable hash-table)
              hash-table)))
    (loop :for key :being :the :hash-keys :in hashtable
          :for value :being :the :hash-values :in hashtable
          :do (cond ((or (ordered-hash-table-p value)
                         (hash-table-p value))
                     (format t "~A~S => ~S~%"
                             (make-string pad :initial-element #\space)
                             key
                             value)
                     (show-ordered-hash-table* value (+ pad 2)))
                    (t
                     (format t "~A~S => ~S~%"
                             (make-string pad :initial-element #\space)
                             key
                             value))))))

(def get-ordered-hash* (path hash-table)
  "Return the value specified by path starting from HASH-TABLE."
  (declare (type (or ordered-hash-table hash-table) hash-table))
  (cond ((singlep path) (get-ordered-hash (car path) hash-table))
        ((null (ordered-hash-table-p (get-ordered-hash (car path) hash-table))) nil)
        (t (get-ordered-hash* (cdr path)
                              (get-ordered-hash (car path) hash-table)))))
