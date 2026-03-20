TAOP      = ./bin/taop
TAOP_SRC  = taop.asd
TAOP_SRC += $(wildcard taop/*lisp)
TAOP_SRC += $(wildcard taop/utils/*lisp)
TAOP_SRC += $(wildcard taop/shakes/*lisp)

ifndef CL
ifeq ($(shell which sbcl),)
CL = ccl --no-init
else
CL = sbcl --no-userinit
endif
endif

QLDIR      = ./build/quicklisp
QUICKLISP  = $(QLDIR)/quicklisp.lisp
QLSETUP    = $(QLDIR)/setup.lisp

PUBNAMES   = $(QLDIR)/local-projects/pubnames

taop: $(TAOP) ;

clean:
	rm -rf $(QLDIR)
	rm -f $(TAOP)
	rm -f system-index.txt

$(QUICKLISP):
	mkdir -p $(QLDIR)
	curl -o $@ https://beta.quicklisp.org/quicklisp.lisp

$(QLSETUP): $(QUICKLISP)
	$(CL) $(CL_OPTS)                                              \
             --load $(QUICKLISP)                                      \
             --eval '(quicklisp-quickstart:install :path "$(QLDIR)")' \
             --eval '(quit)'

$(QLDIR)/local-projects/pubnames: $(QLSETUP)
	git clone --depth 1 https://github.com/dimitri/pubnames.git $@

quicklisp: $(QLSETUP) ;
pubnames: $(PUBNAMES) ;

qload: quicklisp pubnames ./build/qload.lisp
	$(CL) --load $(QLSETUP)                                        \
              --eval '(push "$(PWD)/" ql:*local-project-directories*)' \
	      --load ./build/qload.lisp

$(TAOP): $(TAOP_SRC) $(QLSETUP) | $(QLDIR)/local-projects/pubnames
	TAOP=$(TAOP) $(CL)                                            \
             --load $(QLSETUP)                                        \
             --eval '(push "$(PWD)/" ql:*local-project-directories*)' \
             --load ./build/build.lisp

.PHONY: taop
.PHONY: clean
.PHONY: quicklisp
.PHONY: pubnames
