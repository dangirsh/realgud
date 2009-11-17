;;; dbgr-cmdbuf.el --- debugger process buffer things
(require 'cl)

(require 'load-relative)
(require-relative-list
 '("dbgr-arrow" "dbgr-helper" "dbgr-loc" "dbgr-lochist"))

(eval-when-compile 
  (require 'cl)
  (defvar dbgr-cmdbuf-info)
  )

(defstruct dbgr-cmdbuf-info
  "The debugger object/structure specific to a process buffer."
  name                 ;; Name of debugger
  cmd-args             ;; Command-line invocation arguments
  prior-prompt-regexp  ;; regular expression prompt (e.g.
                       ;; comint-prompt-regexp) *before* setting
                       ;; loc-regexp
  regexp-hash          ;; hash table of regular expressions appropriate for
                       ;; this debugger. Eventually loc-regexp, file-group
                       ;; and line-group below will removed and stored here.

  ;; FIXME: REMOVE THIS and use regexp-hash
  loc-regexp   ;; Location regular expression string
  file-group
  line-group

  loc-hist     ;; ring of locations seen in the course of execution
               ;; see dbgr-lochist
)
(make-variable-buffer-local 'dbgr-cmdbuf-info)

(provide 'dbgr-cmdbuf)
(require 'load-relative)
(dolist (rel-file '("dbgr-arrow" "dbgr-helper" "dbgr-lochist" "dbgr-loc"))
  (require-relative rel-file))

(defalias 'dbgr-cmdbuf-info? 'dbgr-cmdbuf-info-p)

(defmacro dbgr-cmdbuf-info-set? ()
  "Return true if dbgr-cmdbuf-info is set."
  (and (boundp 'dbgr-cmdbuf-info) 
       dbgr-cmdbuf-info
       (dbgr-cmdbuf-info? dbgr-cmdbuf-info)))

;; Without the \?, dbgr-cmdbuf? somehow doesn't get loaded properly.
(defun dbgr-cmdbuf\? ( &optional buffer)
  "Return true if BUFFER is a debugger command buffer."
  (with-current-buffer-safe 
   (or buffer (current-buffer))
   (dbgr-cmdbuf-info-set?)))

;; FIXME: DRY = access via a macro. See also analogous
;; code in dbgr-srcbuf
(defun dbgr-cmdbuf-info-cmd-args=(info value)
  (setf (dbgr-cmdbuf-info-cmd-args info) value))

(defun dbgr-cmdbuf-info-prior-prompt-regexp=(info value)
  (setf (dbgr-cmdbuf-info-prior-prompt-regexp info) value))

(defun dbgr-cmdbuf-command-string(cmd-buffer)
  "Get the command string invocation for this command buffer"
    (cond
     ((dbgr-cmdbuf? cmd-buffer)
      (with-current-buffer cmd-buffer
	(let* 
	    ((cmd-args (dbgr-sget 'dbgr-cmdbuf-info 'cmd-args))
	     (result (car cmd-args)))
	  (and cmd-args 
	       (reduce (lambda(result x)
			 (setq result (concat result " " x)))
		       cmd-args)))))
     (t nil)))

;; FIXME pat-hash should not be optional. And while I am at it, remove
;; parameters loc-regexp, file-group, and line-group which can be found
;; inside pat-hash
;;
;; To do this however we need to fix up the caller
;; dbgr-track-set-debugger by changing dbgr-pat-hash to store a hash
;; rather than the loc, file, and line fields; those fields then get
;; removed.

(defun dbgr-cmdbuf-init
  (cmd-buf &optional debugger-name loc-regexp file-group line-group
	  regexp-hash)
  "Initialize CMD-BUF for a working with a debugger.
DEBUGGER-NAME is the name of the debugger.
as a main program."
  (with-current-buffer cmd-buf
    (setq dbgr-cmdbuf-info
	  (make-dbgr-cmdbuf-info
	   :name debugger-name
	   :loc-regexp loc-regexp
	   :file-group (or file-group -1)
	   :line-group (or line-group -1)
	   :loc-hist (make-dbgr-loc-hist)
	   :regexp-hash regexp-hash))

    (put 'dbgr-cmdbuf-info 'variable-documentation 
	 "Debugger object for a process buffer.")))

(defun dbgr-cmdbuf-debugger-name (&optional cmd-buf)
  "Return the debugger name recorded in the debugger process buffer."
  (with-current-buffer-safe (or cmd-buf (current-buffer))
    (dbgr-sget 'dbgr-cmdbuf-info 'name))
)

(defun dbgr-proc-loc-hist(cmd-buf)
  "Return the history ring of locations that a debugger process has stored."
  (with-current-buffer-safe cmd-buf 
    (dbgr-sget 'dbgr-cmdbuf-info 'loc-hist))
)

(defun dbgr-proc-src-marker(cmd-buf)
  "Return a marker to current source location stored in the history ring."
  (with-current-buffer cmd-buf
    (lexical-let* ((loc (dbgr-loc-hist-item (dbgr-proc-loc-hist cmd-buf))))
      (and loc (dbgr-loc-marker loc)))))

(provide 'dbgr-cmdbuf)

;;; Local variables:
;;; eval:(put 'dbgr-debug-enter 'lisp-indent-hook 1)
;;; End:

;;; dbgr-cmdbuf.el ends here
