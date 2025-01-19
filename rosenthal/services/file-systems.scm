;; SPDX-FileCopyrightText: 2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal services file-systems)
  #:use-module (guix gexp)
  #:use-module (gnu packages backup)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu services mcron)
  #:export (btrbk-service-type
            btrbk-configuration))


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
