;; SPDX-FileCopyrightText: 2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal services mail)
  #:use-module (srfi srfi-26)
  #:use-module (guix records)
  #:use-module (gnu services)
  #:use-module (gnu services admin)
  #:use-module (gnu services configuration)
  #:use-module (gnu services docker)
  #:export (docker-mailserver-configuration
            docker-mailserver-service-type))

;;;
;;; Docker Mailserver
;;; https://docker-mailserver.github.io/docker-mailserver/latest/
;;;

(define-configuration docker-mailserver-configuration
  (data-directory
   (string "/var/lib/docker-mailserver")
   "Directory to store Docker Mailserver data.")
  (log-file
   (string "/var/log/docker-mailserver.log")
   "Path to log file.")
  (shepherd-requirement
   (list-of-symbols '())
   "List of Shepherd service dependencies.")
  (options
   (alist '())
   "Alist of Docker Mailserver configuration.  See also
@url{https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/}.")
  (extra-arguments
   (list '())
   "List of extra Docker arguments.")
  (no-serialization))

(define docker-mailserver-oci-containers
  (match-record-lambda <docker-mailserver-configuration>
      (data-directory log-file shepherd-requirement options extra-arguments)
    (let ((docker-mailserver-path
           (cut string-append data-directory <>)))
      (list (oci-container-configuration
             (environment options)
             (image "ghcr.io/docker-mailserver/docker-mailserver:latest")
             (provision "docker-mailserver")
             (requirement shepherd-requirement)
             (log-file log-file)
             (network "host")
             (volumes
              `((,(docker-mailserver-path "/data") . "/var/mail")
                (,(docker-mailserver-path "/state") . "/var/mail-state")
                (,(docker-mailserver-path "/logs") . "/var/log/mail")
                (,(docker-mailserver-path "/config") . "/tmp/docker-mailserver")
                ("/etc/localtime" . "/etc/localtime:ro")))
             (extra-arguments extra-arguments))))))

(define docker-mailserver-service-type
  (service-type
   (name 'docker-mailserver)
   (extensions
    (list (service-extension oci-container-service-type
                             docker-mailserver-oci-containers)
          (service-extension log-rotation-service-type
                             (compose list docker-mailserver-configuration-log-file))))
   (default-value (docker-mailserver-configuration))
   (description "Run Docker Mailserver.")))
