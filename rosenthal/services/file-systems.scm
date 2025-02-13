;; SPDX-FileCopyrightText: 2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal services file-systems)
  #:use-module (guix gexp)
  #:use-module (gnu packages backup)
  #:use-module (rosenthal packages admin)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu services mcron)
  #:use-module (gnu system pam)
  #:export (btrbk-service-type
            btrbk-configuration

            dumb-runtime-dir-service-type))


;;
;; Btrbk
;;


(define-configuration btrbk-configuration
  (btrbk
   (file-like btrbk)
   "@code{btrbk} package to use.")
  (config-file
   (file-like (plain-file "empty" ""))
   "File-like object for btrbk configuration, see also @code{btrbk.conf(5)}.")
  (no-serialization))

(define (btrbk-etc-service config)
  `(("btrbk/btrbk.conf" ,(btrbk-configuration-config-file config))))

(define (btrbk-mcron-jobs config)
  (list #~(job next-hour-from
               #$(file-append (btrbk-configuration-btrbk config)
                              "/bin/btrbk run --quiet"))))

(define btrbk-service-type
  (service-type
   (name 'btrbk)
   (extensions
    (list (service-extension etc-service-type
                             btrbk-etc-service)
          (service-extension mcron-service-type
                             btrbk-mcron-jobs)))
   (default-value (btrbk-configuration))
   (description "Configure and run btrbk hourly.")))


;;;
;;; pam-dumb-runtime-dir
;;;


(define dumb-runtime-dir-activation
  #~(begin
      (use-modules (guix build utils))
      (mkdir-p "/run/user")
      (chmod "/run/user" #o0755)))

(define dumb-runtime-dir-pam-service
  (let ((optional-pam-entry
         (pam-entry
          (control "optional")
          (module
           (file-append
            pam-dumb-runtime-dir "/lib/security/pam_dumb_runtime_dir.so")))))
    (list (pam-extension
           (transformer
            (lambda (pam)
              (if (string=? (pam-service-name pam) "login")
                  (pam-service
                   (inherit pam)
                   (session
                    (cons optional-pam-entry
                          (pam-service-session pam))))
                  pam)))))))

(define dumb-runtime-dir-service-type
  (service-type
   (name 'dumb-runtime-dir)
   (extensions
    (list (service-extension activation-service-type
                             (const dumb-runtime-dir-activation))
          (service-extension pam-root-service-type
                             (const dumb-runtime-dir-pam-service))))
   (default-value #f)                   ;No default value required.
   (description "Create @code{XDG_RUNTIME_DIR} on login and never remove it.")))
