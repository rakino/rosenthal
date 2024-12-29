;; SPDX-FileCopyrightText: 2023-2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages binaries)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (gnu build icecat-extension)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages nss))

(define license
  (@@ (guix licenses) license))

(define-public atuin-bin
  (package
    (name "atuin-bin")
    (version "18.4.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/atuinsh/atuin/releases/download/v"
                    version "/atuin-x86_64-unknown-linux-gnu.tar.gz"))
              (sha256
               (base32
                "09rbk68mlfvjqzpydq9i83c05vpvn03s2343mswimc5svlclwslh"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan #~'(("atuin" "bin/"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'patch-elf
                 (lambda _
                   (let ((ld.so (string-append #$(this-package-input "glibc")
                                               #$(glibc-dynamic-linker)))
                         (runpath (string-join
                                   (list
                                    (string-append
                                     (ungexp
                                      (this-package-input "gcc") "lib") "/lib")
                                    (string-append
                                     #$(this-package-input "glibc") "/lib"))
                                   ":")))
                     (define (patch-elf file)
                       (format #t "Patching ~a ..." file)
                       (unless (string-contains file ".so")
                         (invoke "patchelf" "--set-interpreter" ld.so file))
                       (invoke "patchelf" "--set-rpath" runpath file)
                       (display " done\n"))
                     (for-each (lambda (file)
                                 (patch-elf file))
                               (find-files
                                (string-append #$output "/bin")))))))))
    (supported-systems '("x86_64-linux"))
    (native-inputs (list patchelf-0.16))
    (inputs (list `(,gcc "lib") glibc))
    (home-page "https://atuin.sh/")
    (synopsis "Sync, search and backup shell history")
    (description
     "Atuin replaces existing shell history with a SQLite database, and records
additional context for commands.  Additionally, it provides optional and fully
encrypted synchronisation of history between machines, via an Atuin server.")
    (license license:gpl3)
    (properties '((upstream-name . "atuin")))))

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
    (version "1.19.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/MetaCubeX/mihomo/releases/download/v"
                    version "/mihomo-linux-amd64-v" version ".gz"))
              (sha256
               (base32
                "0y3hwwzgiy81zjil3kgc1llz9s8hlbyy35ykr59za3fyc53l269q"))))
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
    (license license:gpl3)
    (properties '((upstream-name . "mihomo")))))

(define-public clash-meta-bin
  (deprecated-package "clash-meta-bin" mihomo-bin))

(define-public cloudflare-warp-bin
  (package
    (name "cloudflare-warp-bin")
    (version "2024.12.554.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://pkg.cloudflareclient.com"
                                  "/pool/bookworm/main/c/cloudflare-warp/"
                                  "cloudflare-warp_" version "_amd64.deb"))
              (sha256
               (base32
                "00qan4yaq0hcqw8gfv7jgb1vm2milzlfgzh7frp9f9567115fjwc"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("bin" "bin" #:include ("warp-cli" "warp-svc")))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'unpack-deb
                 (lambda* (#:key source #:allow-other-keys)
                   (invoke "ar" "-x" source)
                   (invoke "tar" "-xf" "data.tar.gz")))
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
                                   #$(this-package-input "glibc") "/lib")
                                  (string-append
                                   #$(this-package-input "nspr") "/lib")
                                  (string-append
                                   #$(this-package-input "nss") "/lib/nss"))
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
    (native-inputs (list patchelf-0.16))
    (inputs (list dbus `(,gcc "lib") glibc nspr nss))
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
              "This is a nonfree license.  Check the URI for details."))
    (properties
     '((upstream-name . "cloudflare-warp")
       (release-monitoring-url
        . "https://pkg.cloudflareclient.com/dists/bookworm/main/binary-amd64/Packages")))))

(define-public hugo-bin
  (package
    (name "hugo-bin")
    (version "0.140.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/gohugoio/hugo" "/releases/download/v"
                    version "/hugo_extended_" version "_linux-amd64.tar.gz"))
              (sha256
               (base32
                "0bzpw3bylgwzgsf570ywvlp9v7z3wh73gb4yw8kjip9s2klnxvvy"))))
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
    (native-inputs (list patchelf-0.16))
    (inputs (list `(,gcc "lib") glibc))
    (home-page "https://gohugo.io/")
    (synopsis "Static site generator")
    (description
     "Hugo is a static site generator written in Go, optimized for speed and
designed for flexibility.")
    (license license:asl2.0)
    (properties '((upstream-name . "hugo")))))

(define miniflux-injector
  (package
    (name "miniflux-injector")
    (version "2.3.3")
    (properties '((addon-id . "{528ec801-2e29-4cb9-ae71-5a90503138d1}")))
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append
             "https://github.com/Sevichecc/miniflux-injector/releases/download"
             "/v" version "/miniflux_injector-" version ".zip"))
       (sha256
        (base32
         "199z441ak6dwy7skgbwc9aa4gfd2r4i22hxfm27s5k3rv7barbvs"))
       (modules '((guix build utils)))
       (snippet
        #~(substitute* "manifest.json"
            (("homepage_url.*" line)
             (string-append line "\
  \"browser_specific_settings\": {
    \"gecko\": {
      \"id\": \"" #$(assq-ref properties 'addon-id) "\"
    }
  },
"))))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." #$(assq-ref (package-properties this-package) 'addon-id)))))
    (home-page "https://github.com/Sevichecc/miniflux-injector")
    (synopsis "Injects Miniflux search results into search page")
    (description
     "This package provides a browser extension to inject Miniflux search
results into search page.  Search terms are sent to your Miniflux instance and
results are added in a sidebar next to search engine results.")
    (license license:expat)))

(define-public miniflux-injector/icecat
  (make-icecat-extension miniflux-injector))

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

(define sidebery
  (package
    (name "sidebery")
    (version "5.2.0.9")
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append
             "https://github.com/mbnuqw/sidebery/releases/download/v"
             (string-drop-right version 2) "/sidebery-" version ".xpi"))
       (sha256
        (base32
         "0wb8rmq25sjnlig3pi1ix2kb8x91pilhh9ag4mk2yqsv9r4gcpw8"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." #$(assq-ref (package-properties this-package) 'addon-id)))))
    (home-page "https://github.com/mbnuqw/sidebery")
    (synopsis "Manage tabs and bookmarks in sidebar")
    (description
     "This package provides a browser extension for managing tabs and bookmarks
in sidebar.")
    (license license:expat)
    (properties '((addon-id . "{3c078156-979c-498b-8990-85f7987dd929}")))))

(define-public sidebery/icecat
  (make-icecat-extension sidebery))

(define-public sing-box-bin
  (package
    (name "sing-box-bin")
    (version "1.10.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/SagerNet/sing-box/releases/download/v"
                    version "/sing-box-" version "-linux-amd64.tar.gz"))
              (sha256
               (base32
                "0cadcqisnfzzf9154bj29ik1sh829rhgqqsjjxa31mgzfzn5ghcy"))))
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
    (version "1.76.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://pkgs.tailscale.com"
                                  "/stable/tailscale_" version "_amd64.tgz"))
              (sha256
               (base32
                "1xv1zx171k2vh6dv8hn115r8il2ckhd273x2r88y9fgpg1xkgwh8"))))
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
    (version "2.12.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/muety/wakapi/releases/download/"
                    version "/wakapi_linux_amd64.zip"))
              (sha256
               (base32
                "0kfid6ii9y1sp2w1na55mybyjya1c2k0jgj9h4zf64kg7isv626w"))))
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
    (version "1.102.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/wakatime/wakatime-cli"
                                  "/releases/download/v" version
                                  "/wakatime-cli-linux-amd64.zip"))
              (sha256
               (base32
                "0pdjvz3lk318ply7gz6bsvprav5b2nj5qd8rblvzc948snlmps1z"))))
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
