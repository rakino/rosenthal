;; SPDX-FileCopyrightText: 2022, 2025 Hilton Chain <hako@ultrarare.space>
;; SPDX-FileCopyrightText: 2025 William Goodspeed
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages admin)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix build-system meson)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages m4))

(define-public dinit
  (package
    (name "dinit")
    (version "0.19.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/davmac314/dinit")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0gw5jvh9bxnnwdv7ajscs03d6x2hcs9i3hxkqfjs19d4wr5rghyq"))))
    (build-system meson-build-system)
    (arguments
     (list #:configure-flags
           #~(list "-Dshutdown-prefix=dinit-"
                   "-Dunit-tests=true"
                   "-Digr-tests=true"
                   (string-append "-Ddinit-sbindir=" #$output "/sbin"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-paths
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* "src/shutdown.cc"
                     (("(/sbin/swapoff|/bin/umount)" path)
                      (search-input-file inputs path))))))))
    (native-inputs (list m4))
    (inputs (list util-linux))
    (home-page "https://davmac.org/projects/dinit/")
    (synopsis "Service manager with dependency management")
    (description
     "Dinit is a service manager for Unix-like operating systems that allows
the user to manage services with dependencies and parallel startup.")
    (license license:asl2.0)))

(define-public libseat-sans-logind
  (let ((base libseat))
    (package
      (inherit base)
      (name "libseat-sans-logind")
      (arguments
       (substitute-keyword-arguments (package-arguments base)
         ((#:configure-flags configure-flags)
          #~(append #$configure-flags
                    (list "-Dlibseat-logind=disabled")))))
      (propagated-inputs '()))))

(define-public seatd-sans-logind
  (let ((base seatd))
    (package
      (inherit base)
      (name "seatd-sans-logind")
      (arguments
       (substitute-keyword-arguments (package-arguments base)
         ((#:configure-flags configure-flags)
          #~(append #$configure-flags
                    (list "-Dlibseat-logind=disabled")))))
      (propagated-inputs '()))))
