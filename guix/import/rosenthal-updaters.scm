(define-module (guix import rosenthal-updaters)
  #:use-module (ice-9 regex)
  #:use-module (rnrs bytevectors)
  #:use-module (srfi srfi-71)
  #:use-module (web client)

  #:use-module (guix packages)
  #:use-module (guix upstream)
  #:export (%cloudflare-warp-updater))

(define* (cloudflare-warp-import pkg #:key (version #f))
  (let* ((source-uri (assq-ref (package-properties pkg) 'release-monitoring-url))
         (response content (http-get source-uri))
         (content (utf8->string content))
         (name (package-upstream-name pkg))
         (newest-version
          (or version
              (match:substring
               (string-match "\nVersion: (.*)\nLicense" content)
               1)))
         (url
          (if version
              (string-append "https://pkg.cloudflareclient.com/"
                             "pool/bookworm/main/c/cloudflare-warp/"
                             "cloudflare-warp_" version "_amd64.deb")
              (string-append "https://pkg.cloudflareclient.com/"
                             (match:substring
                              (string-match "\nFilename: (.*)\nSize" content)
                              1)))))
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
