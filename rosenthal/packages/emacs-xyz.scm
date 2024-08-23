;; SPDX-FileCopyrightText: 2022-2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages emacs-xyz)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages))

(define-public emacs-pcmpl-tailscale
  (let ((commit "acd6bce54af506b0450cf6aa1068f63d4e25c8ce")
        (revision "0"))
    (package
      (name "emacs-pcmpl-tailscale")
      (version (git-version "0.0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://git.thanosapollo.org/pcmpl-tailscale")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0lk808ahy8ckg2fr2pqk3p5if81nqrwsajrgqafv9hgn8w4l1x0p"))))
      (build-system emacs-build-system)
      (home-page "https://git.thanosapollo.org/pcmpl-tailscale")
      (synopsis "Enhanced shell completions for tailscale")
      (description
       "This package provides enhanced completions for the tailscale command
and it's subcommands.")
      (license license:gpl3+))))

;; https://issues.guix.gnu.org/59552
(define-public emacs-wakatime-mode
  ;; No release since May 5, 2015.
  (let ((commit "1c5b2254dd72f2ff504d6a6189a8c10be03a98d1")
        (revision "60"))
    (package
      (name "emacs-wakatime-mode")
      ;; 1.0.2 on commit 32a0154cd4bbd525d354997e6b12c6a9726d0b43, not tagged
      (version (git-version "1.0.2" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/wakatime/wakatime-mode")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "00qv6b756qiaqrmfg1w03psnsdj0iaz3sp50ib4kmdm2g9vgxl1s"))))
      (build-system emacs-build-system)
      (arguments
       (list #:phases
             #~(modify-phases %standard-phases
                 ;; XXX: WakaTime hasn't packaged in Guix yet.
                 (delete 'patch-el-files))))
      (home-page "https://wakatime.com/emacs")
      (synopsis "Automatic time tracking extension for Emacs using WakaTime")
      (description
       "WakaTime mode is an Emacs minor mode for automatic time tracking and
metrics generated from your programming activity.")
      (license license:gpl3+))))
