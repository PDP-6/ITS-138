(defpackage #:maclisp)

(defun maclisp::putprop (name value property)
  (when (eq property 'maclisp::special)
    (proclaim `(special ,name)))
  (setf (get name property) value))

(defun defprop-fexpr (name fn1)
  (let ((fn2 (gensym)) (args (gensym)))
    `(progn
       (maclisp::putprop ',name ',fn1 'maclisp::fexpr)
       (setf (symbol-function ',fn2) ,fn1)
       (defmacro ,name (&rest ,args)
         (list ',fn2 (list 'quote ,args))))))

(defun defprop-macro (name fn)
  (let ((arg (gensym)) (rest (gensym)))
    `(defmacro ,name (&whole ,arg &rest ,rest)
       (declare (ignore ,rest))
       (funcall ,fn ,arg))))

(defmacro maclisp::defprop (name value property)
  (case property
    (maclisp::expr `(progn (maclisp::putprop ',name ',value 'maclisp::expr)
                           (setf (symbol-function ',name) ,value)))
    (maclisp::fexpr (defprop-fexpr name value))
    (maclisp::value `(defvar ,name ',(cdr value)))
    (maclisp::macro (defprop-macro name value))
    (t `(maclisp::putprop ',name ',value ',property))))

(defmacro maclisp::quote (data)
  `(quote ,data))

(defmacro maclisp::setq (x y)
  `(setq ,x ,y))

(deftype maclisp-lambda () `(cons (eql maclisp::lambda) list))

(defmacro maclisp::function (x)
  (etypecase x
    (symbol `(function ,x))
    (maclisp-lambda
     (let ((args (second x)))
       (when (eq args 'maclisp::nil)
         (setq args nil))
       `(function (lambda ,args ,@(cddr x)))))))

(defun specialize (vars)
  #+sbcl
  (declare (sb-ext:disable-package-locks var))
  (flet ((var (x)
           (etypecase x
             (symbol x)
             (cons (first x)))))
  `(declare (special ,@(mapcar #'var vars)))))

(defmacro maclisp::lambda (args &body body)
  (when (eq args 'maclisp::nil)
    (setq args nil))
  `(lambda ,args ,(specialize args) ,@body))

(defmacro maclisp::cond (&rest clauses)
  `(cond ,@clauses))

(defmacro maclisp::or (&rest clauses)
  `(or ,@clauses))

(defmacro maclisp::and (&rest clauses)
  `(and ,@clauses))

(defmacro maclisp::let (vars &body body)
  (when (eq vars 'maclisp::nil)
    (setq vars nil))
  `(let ,vars ,(specialize vars) ,@body))

(defmacro maclisp::prog (vars &body body)
  (when (eq vars 'maclisp::nil)
    (setq vars nil))
  `(prog ,vars ,(specialize vars) ,@body))

(defmacro maclisp::prog2 (&body body)
  `(prog2 ,@body))

(defmacro maclisp::go (x)
  `(go ,x))

(defmacro maclisp::return (x)
  `(return ,x))

(defmacro maclisp::ioc (x)
  (ecase x
    (maclisp::tv nil)
    (maclisp::g `(break))))

(defmacro maclisp::iog (x &body body)
  (declare (ignore x))
  `(let ((maclisp::^q nil)
         (maclisp::^r nil)
         (maclisp::^w nil))
     ,@body))

(defmacro copy (to from)
  `(setf (symbol-function ',to) (symbol-function ',from)))

(deftype pdp10-word () `(unsigned-byte 36))

(defconstant maclisp::nil nil)
(defconstant maclisp::t t)
(defvar maclisp::bporg 0)
(defvar *memory* (make-array 1000 :element-type 'pdp10-word :initial-element 0))

(copy maclisp::cons cons)
(copy maclisp::car car)
(copy maclisp::caar caar)
(copy maclisp::cadr cadr)
(copy maclisp::cdar cdar)
(copy maclisp::cddr cddr)
(copy maclisp::caaar caaar)
(copy maclisp::caddr caddr)
(copy maclisp::cadar cadar)
(copy maclisp::cdadr cdadr)
(copy maclisp::cddar cddar)
(copy maclisp::cdddr cdddr)
(copy maclisp::rplaca rplaca)
(copy maclisp::mapc mapc)
(copy maclisp::mapcar mapcar)
(copy maclisp::atom atom)
(copy maclisp::length length)
(copy maclisp::list list)
(copy maclisp::nconc nconc)
(copy maclisp::assoc assoc)
(copy maclisp::subst subst)
(copy maclisp::member member)
(copy maclisp::append append)
(copy maclisp::reverse reverse)
(copy maclisp::last last)
(copy maclisp::remprop remprop)
(copy maclisp::get get)
(copy maclisp::eq eq)
(copy maclisp::equal equal)
(copy maclisp::not not)
(copy maclisp::read read)
(copy maclisp::print print)
(copy maclisp::terpri terpri)
(copy maclisp::plus +)
(copy maclisp::difference -)
(copy maclisp::minus -)
(copy maclisp::add1 1+)
(copy maclisp::sub1 1-)
(copy maclisp::numberp numberp)
(copy maclisp::zerop zerop)
(copy maclisp::minusp minusp)
(copy maclisp::greaterp >)
(copy maclisp::lessp <)
(copy maclisp::gensym gensym)
(copy maclisp::apply apply)
(copy maclisp::eval eval)

(defun maclisp::null (x)
  (or (null x) (eq x 'maclisp::nil)))

(defun maclisp::cdr (cons)
  (etypecase cons
    (cons (cdr cons))
    (symbol (symbol-plist cons))))

(defun maclisp::rplacd (cons cdr)
  (etypecase cons
    (cons (rplacd cons cdr))
    (symbol (setf (symbol-plist cons) cdr))))

(defun maclisp::caadar (cons)
  (caar (cdar cons)))

(defun maclisp::cadaar (cons)
  (cadr (caar cons)))

(defun maclisp::cadadr (cons)
  (cadr (cadr cons)))

(defun maclisp::caddar (cons)
  (cadr (cdar cons)))

(defun maclisp::cadddr (cons)
  (cadr (cddr cons)))

(defun maclisp::caaddr (cons)
  (caar (cddr cons)))

(defun maclisp::cddddr (cons)
  (cddr (cddr cons)))

(defun maclisp::getl (symbol indicators)
  (do ((plist (symbol-plist symbol) (cddr plist)))
      ((or (null plist)
           (member (first plist) indicators))
       plist)))

(defun maclisp::sassoc (x list fn)
  (or (assoc x list) (funcall fn)))

(defun maclisp::tyo (x)
  (write-char (code-char x)))

(defun maclisp::readlist (list)
  (let ((x (make-string (length list)))
        (i 0))
    (dolist (c list (intern x '#:maclisp))
      (setf (char x i)
            (etypecase c
              (fixnum (code-char c))
              (symbol (char (symbol-name c) 0))))
      (incf i))))

(define-symbol-macro maclisp::oblist (maclisp-oblist))

(defun maclisp-oblist ()
  (let ((list nil))
    (do-symbols (sym '#:maclisp list)
      (push sym list))))

(defun maclisp::remob (&rest list)
  (dolist (sym list)
    (unintern sym '#:maclisp)))

(defun maclisp::lsh (x n)
  (ash (logand x #o77777777777) n))

(defun maclisp::boole (key &rest list)
  (let* ((v #.(vector boole-clr boole-and boole-andc2 boole-1
                      boole-andc1 boole-2 boole-xor boole-ior
                      boole-nor boole-eqv boole-c2 boole-orc2
                      boole-c1 boole-orc1 boole-nand boole-set))
         (b (svref v key))
         (fn (lambda (x y) (boole b x y))))
    (reduce fn list)))

(defun maclisp::maknum (x type)
  (ecase type
    (maclisp::fixnum
     (etypecase x
       (fixnum x)
       (symbol (warn "MAKNUM address of ~A" x) #o1234567)))))

(defun maclisp::examine (address)
  (aref *memory* address))

(defun maclisp::deposit (address value)
  (setf (aref *memory* address) value))

(defun maclisp-load (file)
  (with-open-file (f file)
    (let ((*standard-input* f)
          (*package* (find-package '#:maclisp))
          (*read-base* 8.)
          (*print-base* 8.)
          (val nil))
      (loop for x = (read nil nil :eof) until (eq x :eof)
            do (print x) (setq val (eval x))
            finally (return val)))))
