;;; -*- lexical-binding:t; -*-

(setq user-emacs-directory (expand-file-name "./.emacs.d/"))

(setq make-backup-files nil 
      create-lockfiles nil)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

(use-package esxml)

(use-package htmlize
  :config
  (setq org-html-htmlize-output-type 'css))

(use-package ox-slimhtml)

(use-package ox-publish
  :ensure nil
  :straight nil)

(setq jh/site-title "Jacob's Tech Stack"
      jh/remember-dark-mode-script "<script>
       if (localStorage.darkMode === 'true' || (!('darkMode' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }")

(defun jh/org-html-head (info)
  "Returns the HTML head for my site."
  (concat
   (sxml-to-xml
    `(head
      (title ,(concat (org-export-data (plist-get info :title) info) " - " jh/site-title))
      (meta (@ (charset "utf-8")))
      (meta (@ (author "Jacob Hilker")))
      (meta (@ (name "viewport") 
               (content "width=device-width, initial-scale=1.0")))
      (link (@ (rel "stylesheet") (href "/css/style.css")))
      (link (@ (rel "stylesheet") (href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css")))))))

(defun jh/org-html-header ()
  "Returns header for my site." 
  (concat
   (esxml-to-xml
    `(header ((class . "z-10 items-center text-gray-800 bg-gray-200 dark:bg-navy-700 dark:text-gray-200 grid-in-header"))
             (div ((class . "flex items-center justify-between h-[52px] 2xl:h-[62px]"))
                  (nav ((class . "items-center hidden h-full space-x-3 lg:flex"))
                       (a ((href . "/") (class . "navlink")) "Home")
                       (a ((href .  "/polybar/") (class . "navlink")) "Polybar")))))))

(defun jh/org-html-sidebar ()
  "Returns sidebar for site."
  (concat 
   (esxml-to-xml
    `(aside ((class . "flex-col items-center hidden bg-blueGray-300 dark:bg-blueGray-700 dark:text-gray-100 grid-in-sidebar lg:flex"))
            (span ((class . "p-2 font-bold uppercase")) ,jh/site-title)))
   )
)

(defun jh/org-html-template (content info)
  (concat 
   "<!DOCTYPE html>"
   (sxml-to-xml
   `(html (@ (lang "en"))
         ,(jh/org-html-head info)
         (body 
          (div (@ (class "grid h-screen grid-areas-mobile grid-rows-layout lg:grid-areas-desktop grid-cols-layout"))
               ,(jh/org-html-header)
               ,(jh/org-html-sidebar)
               (main (@ (class "px-3 pt-3 overflow-y-scroll grid-in-main org-sm max-w-none 2xl:org-lg org-royal scrollbar-thin dark:org-dark scroll-smooth motion-reduce:scroll-auto ")) 
                     ,(when (equal "config" (plist-get info :page-type))
                        (format "<h1>%s</h1>" (org-export-data (plist-get info :title) info)))
                     ,content)))))))

(org-export-define-derived-backend 'jh/html 'slimhtml
 :translate-alist '((template . jh/org-html-template)))

(defun get-article-output-path (org-file pub-dir)
  (let ((article-dir (concat pub-dir
                             (downcase
                              (file-name-as-directory
                               (file-name-sans-extension
                                (file-name-nondirectory org-file)))))))

    (if (string-match "\\/home.org$" org-file)
        pub-dir
        (progn
          (unless (file-directory-p article-dir)
            (make-directory article-dir t))
          article-dir))))



(defun jh/org-html-publish-to-html (plist filename pub-dir)
  "publish an org file to html, using the filename as the output directory."
  (let ((article-path (get-article-output-path filename pub-dir)))
    (cl-letf (((symbol-function 'org-export-output-file-name)
               (lambda (extension &optional subtreep pub-dir)
                 (concat article-path "index" extension))))
      (org-publish-org-to 'jh/html
                          filename
                          (concat "." (or (plist-get plist :html-extension)
                                          "html"))
                          plist
                          article-path))))
                     

(setq org-publish-project-alist 
      `(("org:pages"
         :base-directory "./org/"
         :base-extension "org"
         :recursive nil
         :publishing-function jh/org-html-publish-to-html
         :exclude "polybar"
         :publishing-directory "./public/")
        ("org:configs"
         :base-directory "./org/"
         :base-extension "org"
         :recursive t
         :publishing-function jh/org-html-publish-to-html
         :publishing-directory "./public/"
         :exclude "home"
         :page-type "config"
         :with-toc t
         :headline-levels 3)
        ("org" :components ("org:pages" "org:configs"))
        ("css"
         :base-directory "./static/"
         :base-extension "css"
         :recursive t
         :publishing-function org-publish-attachment
         :publishing-directory "./public/"
         :exclude "css/tailwind")))
