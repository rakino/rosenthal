;; SPDX-FileCopyrightText: 2023 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages tree-sitter)
  #:use-module (guix gexp)
  #:use-module (guix packages))

(define tree-sitter-grammar
  (@@ (gnu packages tree-sitter) tree-sitter-grammar))

(define-public tree-sitter-yaml
  (let ((base
         (tree-sitter-grammar
          "yaml" "YAML"
          "1bimf5fq85wn8dwlk665w15n2bj37fma5rsfxrph3i9yb0lvzi3q"
          "0.5.0"
          #:repository-url "https://github.com/ikatyang/tree-sitter-yaml"
          #:get-cleanup-snippet
          (lambda (grammar-directories)
            #~(begin
                (use-modules (guix build utils))
                (delete-file-recursively "docs")
                (delete-file "binding.gyp")
                (delete-file-recursively "bindings")
                (for-each
                 (lambda (lang)
                   (with-directory-excursion lang
                     (delete-file "src/grammar.json")
                     (delete-file "src/node-types.json")
                     (delete-file "src/parser.c")
                     (delete-file-recursively "src/tree_sitter")))
                 '#$grammar-directories))))))
    (package
      (inherit base)
      (arguments
       (append '(#:tests? #f)           ;FIXME
               (package-arguments base))))))
