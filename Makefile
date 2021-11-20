script: publish.org
	@emacs.exe -Q --batch -l org --eval '(org-babel-tangle-file "publish.org")'

org: build-site.el
	@emacs.exe -Q --batch --script build-site.el --eval '(org-publish "org" t)'

css: build-site.el
	@emacs.exe -Q --batch --script build-site.el --eval '(org-publish "css" t)'

site:
	$(MAKE) org; $(MAKE) css
