;; SPDX-FileCopyrightText: 2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal services web)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (gnu packages admin)
  #:use-module (gnu services)
  #:use-module (gnu services admin)
  #:use-module (gnu services configuration)
  #:use-module (gnu services databases)
  #:use-module (gnu services docker)
  #:use-module (gnu system shadow)
  #:export (vaultwarden-configuration
            vaultwarden-service-type))

;;
;; Vaultwarden
;;


(define-maybe string)

(define-configuration vaultwarden-configuration
  (admin-token
   maybe-string
   "Token for the admin interface, preferably an Argon2 PCH string.")
  (database-url
   (string "postgresql://user:password@host:port/database")
   "Database URL.")
  (port
   (integer 8000)
   "Port to listen on.")
  (data-directory
   (string "/var/lib/vaultwarden")
   "Main data folder.")
  (log-file
   (string "/var/log/vaultwarden.log")
   "Logging to this file.")
  (proxy-url
   maybe-string
   "Proxy URL to use.")
  (extra-options
   (alist '())
   "Extra options.")
  (no-serialization))

(define %vaultwarden-accounts
  (list (user-account
         (name "vaultwarden")
         (group "docker")
         (system? #t)
         (home-directory "/var/empty")
         (shell (file-append shadow "/sbin/nologin")))))

(define %vaultwarden-postgresql-role
  (list (postgresql-role
         (name "vaultwarden")
         (create-database? #t))))

(define vaultwarden-log-rotations
  (match-record-lambda <vaultwarden-configuration>
      (log-file)
    (list (log-rotation
           (files (list log-file))))))

(define vaultwarden-activation
  (match-record-lambda <vaultwarden-configuration>
      (data-directory log-file)
    #~(begin
        (use-modules (guix build utils))
        (let ((user (getpwnam "vaultwarden")))
          (unless (file-exists? #$data-directory)
            (mkdir-p #$data-directory)
            (chown #$data-directory (passwd:uid user) (passwd:gid user)))
          (unless (file-exists? #$log-file)
            (mkdir-p (dirname #$log-file))
            (call-with-output-file #$log-file
              (lambda (port)
                (write-char #\newline port)))
            (chown #$log-file (passwd:uid user) (passwd:gid user)))))))

(define vaultwarden-oci-containers
  (match-record-lambda <vaultwarden-configuration>
      (admin-token database-url port data-directory log-file proxy-url extra-options)
    (list (oci-container-configuration
           (user "vaultwarden")
           (host-environment
            `(,@(if (maybe-value-set? admin-token)
                    `(("ADMIN_TOKEN" . ,admin-token))
                    '())
              ("DATABASE_URL" . ,database-url)))
           (environment
            `(,@(if (maybe-value-set? proxy-url)
                    `(("HTTP_PROXY" . ,proxy-url))
                    '())
              ("LOG_FILE" . "vaultwarden.log")
              ("ROCKET_PORT" . ,(number->string port))
              ("USE_SYSLOG" . "True")
              ,@extra-options))
           (image "vaultwarden/server:latest-alpine")
           (provision "vaultwarden")
           (requirement '(postgresql))
           (respawn? #t)
           (network "host")
           (volumes
            `((,data-directory . "/data")
              (,log-file . "/vaultwarden.log")))
           (extra-arguments
            `(,@(if (maybe-value-set? admin-token)
                    '("--env" "ADMIN_TOKEN")
                    '())
              "--env" "DATABASE_URL"))))))

(define vaultwarden-service-type
  (service-type
   (name 'vaultwarden)
   (extensions
    (list (service-extension account-service-type
                             (const %vaultwarden-accounts))
          (service-extension postgresql-role-service-type
                             (const %vaultwarden-postgresql-role))
          (service-extension activation-service-type
                             vaultwarden-activation)
          (service-extension rottlog-service-type
                             vaultwarden-log-rotations)
          (service-extension oci-container-service-type
                             vaultwarden-oci-containers)))
   (default-value (vaultwarden-configuration))
   (description "Run Vaultwarden, a Bitwarden compatible server.")))
