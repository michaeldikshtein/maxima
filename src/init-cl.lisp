;********************************************************
; file:        init-cl.lisp                              
; description: Initialize Maxima                         
; date:        Wed Jan 13 1999 - 20:27                   
; author:      Liam Healy <Liam.Healy@nrl.navy.mil>      
;********************************************************

(in-package :maxima)
(use-package "COMMAND-LINE")
;;; An ANSI-CL portable initializer to replace init_max1.lisp

;;; Locations of various types of files. These variables are discussed
;;; in more detail in the file doc/implementation/dir_vars.txt. Since
;;; these are already in the maxima package, the maxima- prefix is
;;; redundant. It is kept for consistency with the same variables in
;;; shell scripts, batch scripts and environment variables.
;;; jfa 02/07/04
(defvar *maxima-prefix*)
(defvar *maxima-imagesdir*)
(defvar *maxima-sharedir*)
(defvar *maxima-symdir*)
(defvar *maxima-srcdir*)
(defvar *maxima-demodir*)
(defvar *maxima-testsdir*)
(defvar *maxima-docdir*)
(defvar *maxima-infodir*)
(defvar *maxima-htmldir*)
(defvar *maxima-plotdir*)
(defvar *maxima-layout-autotools*)
(defvar *maxima-userdir*)

(defun print-directories ()
  (format t "maxima-prefix=~a~%" *maxima-prefix*)
  (format t "maxima-imagesdir=~a~%" *maxima-imagesdir*)
  (format t "maxima-sharedir=~a~%" *maxima-sharedir*)
  (format t "maxima-symdir=~a~%" *maxima-symdir*)
  (format t "maxima-srcdir=~a~%" *maxima-srcdir*)
  (format t "maxima-demodir=~a~%" *maxima-demodir*)
  (format t "maxima-testsdir=~a~%" *maxima-testsdir*)
  (format t "maxima-docdir=~a~%" *maxima-docdir*)
  (format t "maxima-infodir=~a~%" *maxima-infodir*)
  (format t "maxima-htmldir=~a~%" *maxima-htmldir*)
  (format t "maxima-plotdir=~a~%" *maxima-plotdir*)
  (format t "maxima-layout-autotools=~a~%" *maxima-layout-autotools*)
  (format t "maxima-userdir=~a~%" *maxima-userdir*)
  ($quit))

(defvar *maxima-lispname* #+clisp "clisp"
	#+cmu "cmucl"
	#+sbcl "sbcl"
	#+gcl "gcl"
	#+allegro "acl6"
	#+openmcl "openmcl"
	#-(or clisp cmu sbcl gcl allegro openmcl) "unknownlisp")

(defun combine-path (list)
  (let ((result (first list)))
    (mapc #'(lambda (x) 
		(setf result 
		      (concatenate 'string result "/" x))) (rest list))
    result))

(defvar $file_search_lisp nil
  "Directories to search for Lisp source code.")

(defvar $file_search_maxima nil
  "Directories to search for Maxima source code.")

(defvar $file_search_demo nil
  "Directories to search for demos.")

(defvar $file_search_usage nil)
(defvar $chemin nil)

#+gcl
(defun maxima-getenv (envvar)
  (si::getenv envvar))

#+allegro
(defun maxima-getenv (envvar)
  (system:getenv envvar))

#+cmu
(defun maxima-getenv (envvar)
  (cdr (assoc envvar ext:*environment-list* :test #'string=)))

#+sbcl
(defun maxima-getenv (envvar)
  (sb-ext:posix-getenv envvar))

#+clisp
(defun maxima-getenv (envvar)
  (ext:getenv envvar))

#+mcl
(defun maxima-getenv (envvar)
  (ccl::getenv envvar))

(defun maxima-parse-dirstring (str)
  (let ((sep "/"))
    (if (position (character "\\") str)
	(setq sep "\\"))
    (setf str (concatenate 'string (string-right-trim sep str) sep))
    (concatenate 'string
		 (let ((dev (pathname-device str)))
		   (if (consp dev)
		       (setf dev (first dev)))
		   (if (and dev (not (string= dev "")))
		       (concatenate 'string
				    (string-right-trim 
				     ":" dev) ":")
		     ""))
		 "/"
		 (combine-path
		  (rest (pathname-directory str))))))

(defun set-pathnames-with-autoconf (maxima-prefix-env)
  (let ((libdir)
	(libexecdir)
	(datadir)
	(infodir)
	(package-version (combine-path (list *autoconf-package*
					 *autoconf-version*)))
	(binary-subdirectory (concatenate 'string 
					  "binary-" *maxima-lispname*)))
    (if maxima-prefix-env
	(progn
	  (setq libdir (combine-path (list maxima-prefix-env "lib")))
	  (setq libexecdir (combine-path (list maxima-prefix-env "libexec")))
	  (setq datadir (combine-path (list maxima-prefix-env "share")))
	  (setq infodir (combine-path (list maxima-prefix-env "info"))))
	(progn
	  (setq libdir (maxima-parse-dirstring *autoconf-libdir*))
	  (setq libexecdir (maxima-parse-dirstring *autoconf-libexecdir*))
	  (setq datadir (maxima-parse-dirstring *autoconf-datadir*))
	  (setq infodir (maxima-parse-dirstring *autoconf-infodir*))))
    (setq *maxima-imagesdir*
	  (combine-path (list libdir package-version binary-subdirectory)))
    (setq *maxima-sharedir*
	  (combine-path (list datadir package-version "share")))
    (setq *maxima-symdir*
	  (combine-path (list datadir package-version "share" "sym")))
    (setq *maxima-srcdir*
	  (combine-path (list datadir package-version "src")))
    (setq *maxima-demodir*
	  (combine-path (list datadir package-version "demo")))
    (setq *maxima-testsdir*
	  (combine-path (list datadir package-version "tests")))
    (setq *maxima-docdir*
	  (combine-path (list datadir package-version "doc")))
    (setq *maxima-infodir* infodir)
    (setq *maxima-htmldir*
	  (combine-path (list datadir package-version "doc" "html")))
    (setq *maxima-plotdir*
	  (combine-path (list libexecdir package-version)))))

(defun set-pathnames-without-autoconf (maxima-prefix-env)
  (let ((maxima-prefix (if maxima-prefix-env 
			   maxima-prefix-env
			   (maxima-parse-dirstring *autoconf-prefix*)))
	(binary-subdirectory (concatenate 'string 
					  "binary-" *maxima-lispname*)))

    (setq *maxima-imagesdir*
	  (combine-path (list maxima-prefix "src" binary-subdirectory)))
    (setq *maxima-sharedir*
	  (combine-path (list maxima-prefix "share")))
    (setq *maxima-symdir*
	  (combine-path (list maxima-prefix "share" "sym")))
    (setq *maxima-srcdir*
	  (combine-path (list maxima-prefix "src")))
    (setq *maxima-demodir*
	  (combine-path (list maxima-prefix "demo")))
    (setq *maxima-testsdir*
	  (combine-path (list maxima-prefix "tests")))
    (setq *maxima-docdir*
	  (combine-path (list maxima-prefix "doc")))
    (setq *maxima-infodir* (combine-path (list maxima-prefix "doc" "info")))
    (setq *maxima-htmldir* (combine-path (list maxima-prefix "doc" "html")))
    (setq *maxima-plotdir* (combine-path (list maxima-prefix "plotting")))))

(defun default-userdir ()
  (let ((home-env (maxima-getenv "HOME"))
	(base-dir "")
	(maxima-dir (if (string= *autoconf-win32* "true") 
			"maxima" 
			".maxima")))
    (setf base-dir 
	  (if (and home-env (string/= home-env ""))
	      ;; use home-env...
	      (if (string= home-env "c:\\")
		  ;; but not if home-env = c:\, which results in slow startups
		  ;; under windows. Ick.
		  "c:\\user\\"
		  home-env)
	      ;; we have to make a guess
	      (if (string= *autoconf-win32* "true")
		  "c:\\user\\"
		  "/tmp")))
    (combine-path (list (maxima-parse-dirstring base-dir) maxima-dir))))

(defun set-pathnames ()
  (let ((maxima-prefix-env (maxima-getenv "MAXIMA_PREFIX"))
	(maxima-layout-autotools-env (maxima-getenv "MAXIMA_LAYOUT_AUTOTOOLS"))
	(maxima-userdir-env (maxima-getenv "MAXIMA_USERDIR")))
    ;; MAXIMA_DIRECTORY is a deprecated substitute for MAXIMA_PREFIX
    (if (not maxima-prefix-env)
	(setq maxima-prefix-env (maxima-getenv "MAXIMA_DIRECTORY")))
    (if maxima-prefix-env
	(setq *maxima-prefix* maxima-prefix-env)
	(setq *maxima-prefix* (maxima-parse-dirstring *autoconf-prefix*)))
    (if maxima-layout-autotools-env
	(setq *maxima-layout-autotools*
	      (string-equal maxima-layout-autotools-env "true"))
	(setq *maxima-layout-autotools*
	      (string-equal *maxima-default-layout-autotools* "true")))
    (if *maxima-layout-autotools*
	(set-pathnames-with-autoconf maxima-prefix-env)
	(set-pathnames-without-autoconf maxima-prefix-env))
    (if maxima-userdir-env
	(setq *maxima-userdir* (maxima-parse-dirstring maxima-userdir-env))
	(setq *maxima-userdir* (default-userdir))))
  
  (let* ((ext #+gcl "o"
	      #+cmu (c::backend-fasl-file-type c::*target-backend*)
	      #+sbcl "fasl"
	      #+clisp "fas"
	      #+allegro "fasl"
	      #+(and openmcl darwinppc-target) "dfsl"
	      #+(and openmcl linuxppc-target) "pfsl"
	      #-(or gcl cmu sbcl clisp allegro openmcl)
	      "")
	 (lisp-patterns (concatenate 
			 'string "###.{"
			 (concatenate 'string ext ",lisp,lsp}")))
	 (maxima-patterns "###.{mac,mc}")
	 (demo-patterns "###.{dem,dm1,dm2,dm3,dmt}")
	 (usage-patterns "##.{usg,texi}")
	 (share-subdirs "{affine,algebra,calculus,combinatorics,contrib,contrib/nset,contrib/pdiff,diffequations,graphics,integequations,integration,macro,matrix,misc,numeric,physics,simplification,specfunctions,sym,tensor,trigonometry,utils,vector}"))
    (setq $file_search_lisp
	  (list '(mlist)
		;; actually, this entry is not correct.
		;; there should be a separate directory for compiled
		;; lisp code. jfa 04/11/02
		(combine-path (list *maxima-userdir* lisp-patterns))
		(combine-path (list *maxima-sharedir* lisp-patterns))
		(combine-path (list *maxima-sharedir* share-subdirs 
				    lisp-patterns))
		(combine-path (list *maxima-srcdir* lisp-patterns))))
    (setq $file_search_maxima
	  (list '(mlist)
		(combine-path (list *maxima-userdir* maxima-patterns))
		(combine-path (list *maxima-sharedir* maxima-patterns))
		(combine-path (list *maxima-sharedir* share-subdirs 
				    maxima-patterns))))
    (setq $file_search_demo
	  (list '(mlist)
		(combine-path (list *maxima-sharedir* demo-patterns))
		(combine-path (list *maxima-sharedir* share-subdirs 
				    demo-patterns))
		(combine-path (list *maxima-demodir* demo-patterns))))
    (setq $file_search_usage
	  (list '(mlist) 
		(combine-path (list *maxima-sharedir* usage-patterns))
		(combine-path (list *maxima-sharedir* share-subdirs
				    usage-patterns))
		(combine-path (list *maxima-docdir* usage-patterns))))
    (setq $chemin
	  (concatenate 'string *maxima-symdir* "/"))
    (setq cl-info::*info-paths* (list (concatenate 'string
						   *maxima-infodir* "/")))))

(defun get-dirs (path)
  #+(or :clisp :sbcl)
  (directory (concatenate 'string (namestring path) "/*/"))
  #-(or :clisp :sbcl)
  (directory (concatenate 'string (namestring path) "/*")))

(defun unix-like-basename (path)
  (let* ((pathstring (namestring path))
	 (len (length pathstring)))
    (if (equal (subseq pathstring (- len 1) len) "/")
	(progn (setf len (- len 1))
	       (setf pathstring (subseq pathstring 0 len))))
    (subseq pathstring (+ (position #\/ pathstring :from-end t) 1) len)))

(defun unix-like-dirname (path)
  (let* ((pathstring (namestring path))
	 (len (length pathstring)))
    (if (equal (subseq pathstring (- len 1) len) "/")
	(progn (setf len (- len 1))
	       (setf pathstring (subseq pathstring 0 len))))
    (subseq pathstring 0 (position #\/ pathstring :from-end t))))

(defun list-avail-action ()
  (let* ((maxima-verpkglibdir (if (maxima-getenv "MAXIMA-VERPKGLIBDIR")
				  (maxima-getenv "MAXIMA-VERPKGLIBDIR")
				  (if (maxima-getenv "MAXIMA_PREFIX")
				      (concatenate 
				       'string (maxima-getenv "MAXIMA_PREFIX")
				       "/lib/" *autoconf-package* "/"
				       *autoconf-version*)
				      (concatenate 
				       'string (maxima-parse-dirstring 
						*autoconf-libdir*) 
				       "/"
				       *autoconf-package* "/"
				       *autoconf-version*))))
	 (len (length maxima-verpkglibdir))
	 (base-dir nil)
	 (versions nil)
	 (version-string nil)
	 (lisps nil)
	 (lisp-string nil))
    (format t "Available versions:~%")
    (if (not (equal (subseq maxima-verpkglibdir (- len 1) len) "/"))
	(setf maxima-verpkglibdir (concatenate 
				   'string maxima-verpkglibdir "/")))
    (setf base-dir (unix-like-dirname maxima-verpkglibdir))
    (setf versions (get-dirs base-dir))
    (dolist (version versions)
      (setf lisps (get-dirs version))
      (setf version-string (unix-like-basename version))
      (dolist (lisp lisps)
	(setf lisp-string (unix-like-basename lisp))
	(when (search "binary-" lisp-string)
	  (setf lisp-string (subseq lisp-string (length "binary-") 
				  (length lisp-string)))
	  (format t "version ~a, lisp ~a~%" version-string lisp-string))))
    (bye)))

(defun process-maxima-args (input-stream batch-flag)
;    (format t "processing maxima args = ")
;    (mapc #'(lambda (x) (format t "\"~a\"~%" x)) (get-application-args))
;    (terpri)
  (let ((maxima-options nil))
    (setf maxima-options
	  (list 
	   (make-cl-option :names '("-h" "--help")
			   :action #'(lambda () 
				       (format t "usage: maxima [options]~%")
				       (list-cl-options maxima-options)
				       (bye))
			   :help-string "Display this usage message.")
	   (make-cl-option :names '("-l" "--lisp")
			   :argument "<lisp>"
			   :action nil
			   :help-string "Use lisp implementation <lisp>.")
	   (make-cl-option :names '("-u" "--use-version")
			   :argument "<version>"
			   :action nil
			   :help-string "Use maxima version <version>.")
	   (make-cl-option :names '("--list-avail")
			   :action 'list-avail-action
			   :help-string 
			   "List the installed version/lisp combinations.")
	   (make-cl-option :names '("-b" "--batch")
			   :argument "<file>"
			   :action #'(lambda (file)
				       (setf input-stream
					     (make-string-input-stream
					      (format nil "batch(\"~a\");" 
						      file)))
				       (setf batch-flag :batch))
			   :help-string
			   "Process maxima file <file> in batch mode.")
	   (make-cl-option :names '("--batch-lisp")
			   :argument "<file>"
			   :action #'(lambda (file)
				       (setf input-stream
					     (make-string-input-stream
					      (format nil
						      ":lisp (load \"~a\");"
						      file)))
				       (setf batch-flag :batch))
			   :help-string 
			   "Process lisp file <file> in batch mode.")
	   (make-cl-option :names '("--batch-string")
			   :argument "<string>"
			   :action #'(lambda (string)
				       (setf input-stream 
					     (make-string-input-stream string))
				       (setf batch-flag :batch))
			   :help-string 
			   "Process maxima command(s) <string> in batch mode.")
	   (make-cl-option :names '("-r" "--run-string")
			   :argument "<string>"
			   :action #'(lambda (string)
				       (setf input-stream
					     (make-string-input-stream string))
				       (setf batch-flag nil))
			   :help-string 
			   "Process maxima command(s) <string> in interactive mode.")
	   (make-cl-option :names '("-p" "--preload-lisp")
			   :argument "<lisp-file>"
			   :action #'(lambda (file)
				       (load file))
			   :help-string "Preload <lisp-file>.")
	   (make-cl-option :names '("--disable-readline")
			   :action #'(lambda ()
				       #+gcl
				       (si::readline-off)))
	   (make-cl-option :names '("-s" "--server")
			   :argument "<port>"
			   :action #'(lambda (port-string)
				       (start-server (parse-integer 
						      port-string)))
			   :help-string "Start maxima server on <port>.")
	   (make-cl-option :names '("-d" "--directories")
			   :action 'print-directories
			   :help-string
			   "Display maxima internal directory information.")
	   (make-cl-option :names '("-g" "--enable-lisp-debugger")
			   :action #'(lambda ()
				       (setf *debugger-hook* nil))
			   :help-string
			   "Enable underlying lisp debugger.")
	   (make-cl-option :names '("-v" "--verbose")
			   :action nil
			   :help-string 
			   "Display lisp invocation in maxima wrapper script.")
	   (make-cl-option :names '("--version")
			   :action #'(lambda ()
				       (format t "Maxima ~a~%" 
					       *autoconf-version*)
				       ($quit))
			   :help-string 
			   "Display the default installed version.")))
    (process-args (get-application-args) maxima-options))
  (values input-stream batch-flag))

(defun user::run ()
  "Run Maxima in its own package."
  (in-package "MAXIMA")
  (setf *load-verbose* nil)
  (setf *debugger-hook* #'maxima-lisp-debugger)
  (let ((input-stream *standard-input*)
	(batch-flag nil))
    #+allegro
    (progn
      (set-readtable-for-macsyma)
      (setf *read-default-float-format* 'lisp::double-float))
    
    (catch 'to-lisp
      (set-pathnames)
      (setf (values input-stream batch-flag) 
	    (process-maxima-args input-stream batch-flag))
      #+(or cmu sbcl clisp allegro mcl)
      (progn
	(loop 
	   (with-simple-restart (macsyma-quit "Macsyma top-level")
	     (macsyma-top-level input-stream batch-flag))))
      #-(or cmu sbcl clisp allegro mcl)
      (catch 'macsyma-quit
	(macsyma-top-level input-stream batch-flag)))))

(import 'user::run)

($setup_autoload "eigen.mac" '$eigenvectors '$eigenvalues)

(defun $to_lisp ()
  (format t "~&Type (to-maxima) to restart~%")
  (let ((old-debugger-hook *debugger-hook*))
    (catch 'to-maxima
      (unwind-protect
	  (maxima-read-eval-print-loop)
	(setf *debugger-hook* old-debugger-hook)
	(format t "Returning to Maxima~%"))))
)

(defun to-maxima ()
  (throw 'to-maxima t))

(defun maxima-read-eval-print-loop ()
  (setf *debugger-hook* #'maxima-lisp-debugger-repl)
  (loop
   (catch 'to-maxima-repl
     (format t "~a~%~a> ~a" *prompt-prefix* 
	     (package-name *package*) *prompt-suffix*)
     (let ((form (read)))
       (prin1 (eval form))))))

(defun maxima-lisp-debugger-repl (condition me-or-my-encapsulation)
  (format t "~&Maxima encountered a Lisp error:~%~% ~A" condition)
  (format t "~&~%Automatically continuing.~%To reenable the Lisp debugger set *debugger-hook* to nil.~%")
  (throw 'to-maxima-repl t))

(defun $jfa_lisp ()
  (format t "jfa was here"))

(defvar $help "type describe(topic) or example(topic);")

(defun $help () $help)			;

;; CMUCL needs because when maxima reaches EOF, it calls BYE, not $QUIT.
#+cmu
(defun bye ()
  (ext:quit))

#+sbcl
(defun bye ()
  (sb-ext:quit))

#+clisp
(defun bye ()
  (ext:quit))

#+allegro
(defun bye ()
  (excl:exit))

#+mcl
(defun bye ()
  (ccl::quit))

(defun $maxima_server (port)
  (load "/home/amundson/devel/maxima/archive/src/server.lisp")
  (user::setup port))
