;; SPDX-FileCopyrightText: 2023 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages binaries)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages glib))

(define license
  (@@ (guix licenses) license))

(define-public clash-bin
  (package
    (name "clash-bin")
    (version "1.18.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Dreamacro/clash/releases/download/v"
                    version "/clash-linux-amd64-v3-v" version ".gz"))
              (sha256
               (base32
                "0gchpc4pvy24dvhb5nk08g97rswjqr1ic6i405f1ba5snfv8i5z8"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'((#$(format #f "clash-linux-amd64-v3-v~a" version) "bin/clash"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'fix-permission
                 (lambda _
                   (chmod (string-append #$output "/bin/clash") #o555))))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/Dreamacro/clash")
    (synopsis "Rule-based tunnel in Go")
    (description
     "Clash is a cross-platform rule-based proxy utility that runs on the
network and application layer, supporting various proxy and anti-censorship
protocols out-of-the-box.")
    (license license:gpl3)))

(define-public mihomo-bin
  (package
    (name "mihomo-bin")
    (version "1.18.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/MetaCubeX/mihomo/releases/download/v"
                    version "/mihomo-linux-amd64-v" version ".gz"))
              (sha256
               (base32
                "1b2ljl14k4vbpq4dgms1hk0iys161afyr1j2hl2hga70ay6n7j7i"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'((#$(string-append
                   "mihomo-linux-amd64-v" (package-version this-package))
                "bin/mihomo"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'fix-permission
                 (lambda _
                   (chmod (string-append #$output "/bin/mihomo") #o555))))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://wiki.metacubex.one/")
    (synopsis "Rule-based tunnel in Go")
    (description
     "This package provides @command{mihomo}, another @code{clash} kernel.")
    (license license:gpl3)))

(define-public clash-meta-bin
  (deprecated-package "clash-meta-bin" mihomo-bin))

(define-public cloudflare-warp-bin
  (package
    (name "cloudflare-warp-bin")
    (version "2023.10.120")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://pkg.cloudflareclient.com"
                                  "/pool/bookworm/main/c/cloudflare-warp/"
                                  "cloudflare-warp_" version "-1_amd64.deb"))
              (sha256
               (base32
                "138c0yqp2d2cw89jsbfcii0r1fz0ll8wyf7kqs4pi5hb0mffwz05"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("bin" "bin" #:include ("warp-cli" "warp-svc")))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'unpack-deb
                 (lambda _
                   (let ((deb-pack (format #f "cloudflare-warp_~a-1_amd64.deb"
                                           #$(package-version this-package))))
                     (invoke "ar" "-x" deb-pack)
                     (invoke "tar" "-xf" "data.tar.gz"))))
               (add-after 'install 'patch-elf
                 (lambda _
                   (let ((ld.so (string-append #$(this-package-input "glibc")
                                               #$(glibc-dynamic-linker)))
                         (rpath (string-join
                                 (list
                                  (string-append
                                   (ungexp
                                    (this-package-input "gcc") "lib") "/lib")
                                  (string-append
                                   #$(this-package-input "dbus") "/lib")
                                  (string-append
                                   #$(this-package-input "glibc") "/lib"))
                                 ":")))
                     (define (patch-elf file)
                       (format #t "Patching ~a ..." file)
                       (unless (string-contains file ".so")
                         (invoke "patchelf" "--set-interpreter" ld.so file))
                       (invoke "patchelf" "--set-rpath" rpath file)
                       (display " done\n"))
                     (for-each (lambda (file)
                                 (patch-elf file))
                               (find-files
                                (string-append #$output "/bin")))))))))
    (supported-systems '("x86_64-linux"))
    (native-inputs (list patchelf))
    (inputs (list dbus `(,gcc "lib") glibc))
    (home-page "https://1.1.1.1/")
    (synopsis "Cloudflare WARP client")
    (description
     "The Cloudflare WARP client allows individuals to have a faster, more
secure, and more private experience online.  The WARP client sits between your
device and the Internet, and has several connection modes to better suit
different needs.")
    (license
     (license "Nonfree"
              "https://www.cloudflare.com/application/terms/"
              "This is a nonfree license.  Check the URI for details."))))

(define-public hugo-bin
  (package
    (name "hugo-bin")
    (version "0.125.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/gohugoio/hugo" "/releases/download/v"
                    version "/hugo_extended_" version "_linux-amd64.tar.gz"))
              (sha256
               (base32
                "1xrlmsr06q3c54a6546w9z57f3rgxihvaml94214bf6n8sj2hfq9"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan #~'(("hugo" "bin/"))
           #:phases
           #~(modify-phases %standard-phases
               (delete 'strip)
               (add-after 'install 'patch-elf
                 (lambda _
                   (let ((hugo (string-append #$output "/bin/hugo")))
                     (invoke "patchelf" "--set-interpreter"
                             (string-append #$(this-package-input "glibc")
                                            #$(glibc-dynamic-linker))
                             hugo)
                     (invoke "patchelf" "--set-rpath"
                             (string-append (ungexp (this-package-input "gcc")
                                                    "lib")
                                            "/lib")
                             hugo)))))))
    (supported-systems '("x86_64-linux"))
    (native-inputs (list patchelf))
    (inputs (list `(,gcc "lib") glibc))
    (home-page "https://gohugo.io/")
    (synopsis "Static site generator")
    (description
     "Hugo is a static site generator written in Go, optimized for speed and
designed for flexibility.")
    (license license:asl2.0)))

(define-public shadow-tls-bin
  (package
    (name "shadow-tls-bin")
    (version "0.2.25")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/ihciah/shadow-tls/releases/download/v"
                    version "/shadow-tls-x86_64-unknown-linux-musl"))
              (sha256
               (base32
                "0chmqzfmyw5w8ybshkwigc3r25svq7fyw371d0dj2ibzsprgawx1"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("shadow-tls-x86_64-unknown-linux-musl" "bin/shadow-tls"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'fix-permission
                 (lambda _
                   (chmod (string-append #$output "/bin/shadow-tls") #o555))))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://www.ihcblog.com/a-better-tls-obfs-proxy/")
    (synopsis "Proxy to expose real tls handshake to the firewall")
    (description
     "Shadow TLS is a proxy to expose real tls handshake to the @acronym{MITM,
monster-in-the-middle}.")
    (license license:expat)))

(define-public sing-box-bin
  (package
    (name "sing-box-bin")
    (version "1.8.9")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/SagerNet/sing-box/releases/download/v"
                    version "/sing-box-" version "-linux-amd64.tar.gz"))
              (sha256
               (base32
                "1cj4ygwv53qmin7hpz1nqqa694fj6d0g3qwq5srsb8wvg6sl47j8"))))
    (build-system copy-build-system)
    (arguments (list #:install-plan #~'(("sing-box" "bin/"))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://sing-box.sagernet.org/")
    (synopsis "Universal proxy platform")
    (description
     "This package provides @command{sing-box}, a universal proxy platform.")
    (license license:gpl3+)))

(define-public tailscale-bin
  (package
    (name "tailscale-bin")
    (version "1.66.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://pkgs.tailscale.com"
                                  "/stable/tailscale_" version "_amd64.tgz"))
              (sha256
               (base32
                "16rjmgq1gsa25pbkdwv3fdz8hd7xp14rpd8ilwc7ndswnpyg6grd"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("." "bin/" #:include ("tailscale" "tailscaled")))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://tailscale.com/")
    (synopsis "Private WireGuard® networks made easy")
    (description
     "This package provides @command{tailscale}, which brings an easy and secure
way to use WireGuard and 2FA.")
    (license license:bsd-3)))

(define-public wakapi-bin
  (package
    (name "wakapi-bin")
    (version "2.10.4")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/muety/wakapi/releases/download/"
                    version "/wakapi_linux_amd64.zip"))
              (sha256
               (base32
                "0pcwy6yvbck5yl1pn0xh6hnipy2bzx7fhiijlajb9gizz1g7ax9k"))))
    (build-system copy-build-system)
    (arguments (list #:install-plan #~'(("wakapi" "bin/wakapi"))))
    (supported-systems '("x86_64-linux"))
    (native-inputs (list unzip))
    (home-page "https://wakapi.dev/")
    (synopsis "WakaTime-compatible backend")
    (description
     "This package provides @code{wakapi}, a WakaTime-compatible backend for
coding statistics.")
    (license license:expat)))

(define-public wakatime-cli-bin
  (package
    (name "wakatime-cli-bin")
    (version "1.90.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/wakatime/wakatime-cli"
                                  "/releases/download/v" version
                                  "/wakatime-cli-linux-amd64.zip"))
              (sha256
               (base32
                "0pcb0kw7761hbq92hnbldzhn2v4ad42vn3gavksiw0mz5v334wp5"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("wakatime-cli-linux-amd64" "bin/wakatime-cli"))))
    (supported-systems '("x86_64-linux"))
    (native-inputs (list unzip))
    (home-page "https://wakatime.com/plugins")
    (synopsis "Command line interface to WakaTime")
    (description
     "This package provides @command{wakatime-cli}, the command line interface
to WakaTime, which is used by all WakaTime text editor plugins.")
    (license license:bsd-3)))
