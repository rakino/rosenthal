;; SPDX-FileCopyrightText: 2024, 2025 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (guix import rosenthal-updaters)
  #:use-module (srfi srfi-71)
  #:use-module (web client)

  #:use-module (guix packages)
  #:use-module (guix records)
  #:use-module (guix upstream)
  #:export (%cloudflare-warp-updater))

(define* (cloudflare-warp-import pkg #:key (version #f))
  (let* ((source-uri (assq-ref (package-properties pkg) 'release-monitoring-url))
         (response port (http-get source-uri #:streaming? #t))
         (content (recutils->alist port))
         (_ (close port))
         (name (package-upstream-name pkg))
         (newest-version
          (or version
              (assoc-ref content "Version")))
         (url
          (if version
              (string-append "https://pkg.cloudflareclient.com/"
                             "pool/bookworm/main/c/cloudflare-warp/"
                             "cloudflare-warp_" version "_amd64.deb")
              (string-append "https://pkg.cloudflareclient.com/"
                             (assoc-ref content "Filename")))))
    (upstream-source
     (package name)
     (version newest-version)
     (urls (list url)))))

(define %cloudflare-warp-updater
  (upstream-updater
   (name 'cloudflare-warp)
   (description "Updater for Cloudflare WARP client")
   (pred (lambda (package)
           (string=? "cloudflare-warp" (package-upstream-name package))))
   (import cloudflare-warp-import)))
