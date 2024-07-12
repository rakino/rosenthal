;; SPDX-FileCopyrightText: 2023 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages bootloaders)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bootloaders)
  #:use-module (gnu packages python))

;; Patches obtained from:
;; <https://leo3418.github.io/collections/gentoo-config-luks2-grub-systemd/packages.html>

(define grub-luks2-argon2-support-patch
  (origin
    (method url-fetch)
    (uri (string-append "https://leo3418.github.io/"
                        "res/collections/gentoo-config-luks2-grub-systemd/"
                        "grub-2.12-luks2-argon2-v4.patch"))
    (sha256
     (base32
      "02y15k6rd5vj2shfijyhq2nr2775vpa55ijfy6bb8irpnh8i2272"))))

(define-public grub-efi-luks2
  (let ((base grub-efi))
    (package
      (inherit base)
      (name "grub-efi-luks2")
      (source
       (let ((base (package-source base)))
         (origin
           (inherit base)
           (patches
            (append (origin-patches base)
                    (list grub-luks2-argon2-support-patch))))))
      (arguments
       (substitute-keyword-arguments (package-arguments base)
         ((#:configure-flags flags ''())
          #~(append #$flags '("--disable-werror")))
         ((#:phases phases '%standard-phases)
          #~(modify-phases #$phases
              (add-after 'unpack 'delete-configure-script
                (lambda _
                  (delete-file "configure")))))))
      (native-inputs
       (modify-inputs (package-native-inputs base)
         (append autoconf automake python-minimal-wrapper))))))
