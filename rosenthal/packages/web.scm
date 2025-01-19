;; SPDX-FileCopyrightText: 2022, 2025 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages web)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system go)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages web))

(define-public buku-run-dev
  (let ((revision "23")
        (commit "54fcdd77fc1e8e657b785b7d4ca8dc915e5f336b"))
    (package
      (inherit buku-run)
      (name "buku-run-dev")
      (version (git-version "0.1.1" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/carnager/buku_run")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "079ygn39px71bypa54jn4z55iq24lxxcy7jv3ijy08iinqbfvldc")))))))

;; TODO: Package Forgejo without vendored dependencies.
(define-public forgejo
  (package
    (name "forgejo")
    (version "10.0.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://codeberg.org/forgejo/forgejo/releases/download/v"
                    version "/forgejo-src-" version ".tar.gz"))
              (sha256
               (base32
                "0lwqn8l7dys7nnha47a05n865dsb13f973fkm167m3x8mwm8vm5i"))))
    (build-system go-build-system)
    (arguments
     (list #:go go-1.23
           #:install-source? #f
           #:tests? #f                  ;TODO
           #:import-path "code.gitea.io/gitea"
           #:build-flags
           #~(list (string-append
                    "-ldflags="
                    " -X main.ReleaseVersion=" #$(package-version this-package)
                    " -X main.Version=" #$(package-version this-package)
                    " -X main.ForgejoVersion=" #$(package-version this-package)
                    " -X code.gitea.io/gitea/modules/setting.AppWorkPath=/var/lib/forgejo"
                    " -X code.gitea.io/gitea/modules/setting.CustomPath=" #$output "/etc/forgejo"
                    " -X code.gitea.io/gitea/modules/setting.CustomConf=/etc/forgejo/app.ini"))
           #:modules
           '(((guix build gnu-build-system) #:prefix gnu:)
             (guix build go-build-system)
             (guix build union)
             (guix build utils))
           #:phases
           #~(modify-phases %standard-phases
               (replace 'unpack
                 (assoc-ref gnu:%standard-phases 'unpack))
               (add-after 'unpack 'support-module
                 (lambda _
                   (unsetenv "GO111MODULE")
                   (substitute* "go.mod"
                     (("^toolchain.*") ""))))
               (replace 'build
                 (lambda* (#:key build-flags (parallel-build? #t)
                           #:allow-other-keys)
                   (let* ((njobs (if parallel-build? (parallel-job-count) 1)))
                     (setenv "GOMAXPROCS" (number->string njobs)))
                   (apply invoke "go" "install"
                          "-v" "-x"
                          "-ldflags=-s -w"
                          "-trimpath"
                          build-flags)))
               (replace 'install
                 (lambda _
                   (mkdir-p (in-vicinity #$output "/etc/forgejo"))
                   (copy-file
                    "custom/conf/app.example.ini"
                    (in-vicinity #$output "etc/forgejo/app.ini"))
                   (for-each
                    (lambda (dir)
                      (copy-recursively
                       dir (string-append #$output "/etc/forgejo/" dir)))
                    '("options" "public" "templates"))
                   (with-directory-excursion (in-vicinity #$output "bin")
                     (rename-file "gitea" "forgejo"))))
               (replace 'install-license-files
                 (assoc-ref gnu:%standard-phases 'install-license-files)))))
    (synopsis "Lightweight software forge")
    (description
     "Forgejo is a self-hosted lightweight software forge.  Easy to install and
low maintenance, it just does the job.")
    (home-page "https://forgejo.org/")
    (license license:gpl3+)))
