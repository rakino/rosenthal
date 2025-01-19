;; SPDX-FileCopyrightText: 2024 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal services web)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages version-control)
  #:use-module (rosenthal packages web)
  #:use-module (gnu services)
  #:use-module (gnu services admin)
  #:use-module (gnu services configuration)
  #:use-module (gnu services databases)
  #:use-module (gnu services docker)
  #:use-module (gnu services shepherd)
  #:use-module (gnu system shadow)
  #:use-module (rosenthal utils home-services-utils)
  #:export (forgejo-configuration
            forgejo-service-type

            jellyfin-configuration
            jellyfin-service-type

            misskey-configuration
            misskey-service-type

            vaultwarden-configuration
            vaultwarden-service-type))

;;
;; Forgejo
;;


(define (file-object? val)
  (or (string? val)
      (file-like? val)))

(define list-of-file-likes?
  (list-of file-like?))

(define-configuration forgejo-configuration
  (forgejo
   (file-like forgejo)
   "Package to provide @file{/bin/forgejo}.")
  (git-packages
   (list-of-file-likes (list git git-lfs))
   "@code{git} and extension packages to install.")
  (config-file
   (file-object "/var/lib/forgejo/app.ini")
   "Filesystem path or file-like object of Forgejo configuration,
@file{app.ini}.")
  (no-serialization))

(define %forgejo-accounts
  (list (user-group (name "forgejo") (system? #t))
        (user-account
         (name "forgejo")
         (group "forgejo")
         (system? #t)
         (comment "Forgejo user")
         (home-directory "/var/lib/forgejo")
         (shell (file-append shadow "/sbin/nologin")))))

(define %forgejo-postgresql-role
  (list (postgresql-role
         (name "forgejo")
         (create-database? #t))))

(define forgejo-activation
  #~(begin
      (use-modules (guix build utils))
      (let ((dir "/var/lib/forgejo")
            (user (getpwnam "forgejo")))
        (mkdir-p dir)
        (chown dir (passwd:uid user) (passwd:gid user))
        (chmod dir #o750))))

(define forgejo-shepherd-service
  (match-record-lambda <forgejo-configuration>
      (forgejo config-file)
    (list (shepherd-service
           (documentation "Run Forgejo.")
           (provision '(forgejo))
           (requirement '(loopback postgresql))
           (start
            #~(make-forkexec-constructor
               (list #$(file-append forgejo "/bin/forgejo")
                     "--config" #$config-file)
               #:user "forgejo"
               #:group "forgejo"
               #:log-file "/var/log/forgejo.log"
               #:environment-variables
               '("GIT_EXEC_PATH=/run/current-system/profile/libexec/git-core"
                 "GIT_SSL_CAINFO=/run/current-system/profile/etc/ssl/certs/ca-certificates.crt"
                 "HOME=/var/lib/forgejo"
                 "PATH=/run/current-system/profile/bin"
                 "SSL_CERT_DIR=/run/current-system/profile/etc/ssl/certs"
                 "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt")
               #:resource-limits '((nofile 524288 524288))))
           (stop
            #~(make-kill-destructor))
           (actions
            (list (shepherd-configuration-action config-file)))))))

(define forgejo-service-type
  (service-type
   (name 'forgejo)
   (extensions
    (list (service-extension account-service-type
                             (const %forgejo-accounts))
          (service-extension postgresql-role-service-type
                             (const %forgejo-postgresql-role))
          (service-extension profile-service-type
                             forgejo-configuration-git-packages)
          (service-extension activation-service-type
                             (const forgejo-activation))
          (service-extension shepherd-root-service-type
                             forgejo-shepherd-service)))
   (default-value (forgejo-configuration))
   (description "Run Forgejo.")))


;;
;; Jellyfin
;;


(define-maybe string)

(define-configuration jellyfin-configuration
  (cache-directory
   (string "/var/cache/jellyfin")
   "Path to cache directory.")
  (config-directory
   (string "/var/lib/jellyfin")
   "Path to configuration directory.")
  (proxy-url
   maybe-string
   "Proxy URL.")
  (log-file
   (string "/var/log/jellyfin.log")
   "Path to log file.")
  (auto-start?
   (boolean #t)
   "Whether to start automatically.")
  (extra-options
   (list '())
   "List of extra options.")
  (no-serialization))

(define %jellyfin-accounts
  (list (user-account
         (name "jellyfin")
         (group "docker")
         (system? #t)
         (home-directory "/var/empty")
         (shell (file-append shadow "/sbin/nologin")))))

(define jellyfin-activation
  (match-record-lambda <jellyfin-configuration>
      (cache-directory config-directory)
    #~(let ((user (getpwnam "jellyfin")))
        (for-each
         (lambda (directory)
           (unless (file-exists? directory)
             (mkdir-p directory)
             (chown directory (passwd:uid user) (passwd:gid user))))
         '#$(list cache-directory config-directory)))))

(define jellyfin-oci-containers
  (match-record-lambda <jellyfin-configuration>
      (cache-directory config-directory
                       proxy-url log-file auto-start? extra-options)
    (list (oci-container-configuration
           (user "jellyfin")
           (group "docker")
           (environment
            (if (maybe-value-set? proxy-url)
                `(("http_proxy" . ,proxy-url)
                  ("https_proxy" . ,proxy-url))
                '()))
           (image "jellyfin/jellyfin:latest")
           (provision "jellyfin")
           (log-file log-file)
           (auto-start? auto-start?)
           (respawn? #t)
           (network "host")
           (volumes
            `((,cache-directory . "/cache")
              (,config-directory . "/config")))
           (extra-arguments extra-options)))))

(define jellyfin-service-type
  (service-type
   (name 'jellyfin)
   (extensions
    (list (service-extension account-service-type
                             (const %jellyfin-accounts))
          (service-extension activation-service-type
                             jellyfin-activation)
          (service-extension log-rotation-service-type
                             (compose list jellyfin-configuration-log-file))
          (service-extension oci-container-service-type
                             jellyfin-oci-containers)))
   (default-value (jellyfin-configuration))
   (description "Run Jellyfin, a media system.")))


;;
;; Misskey
;;


(define-configuration misskey-configuration
  (image
   (string "misskey/misskey:latest")
   "Misskey docker image to use.")
  (config
   (yaml-config '())
   "Alist of Misskey configuration, to be serialized to YAML format.")
  (data-directory
   (string "/var/lib/misskey")
   "Directory to store @file{files} in.")
  (log-file
   (string "/var/log/misskey.log")
   "Log file to use.")
  (no-serialization))

(define %misskey-accounts
  (list (user-account
         (name "misskey")
         (group "docker")
         (system? #t)
         (home-directory "/var/empty")
         (shell (file-append shadow "/sbin/nologin")))))

(define %misskey-postgresql-role
  (list (postgresql-role
         (name "misskey")
         (create-database? #t))))

(define misskey-activation
  (match-record-lambda <misskey-configuration>
      (data-directory)
    #~(begin
        (use-modules (guix build utils))
        (let ((user (getpwnam "misskey")))
          (unless (file-exists? #$data-directory)
            (mkdir-p #$data-directory)
            (chown #$data-directory (passwd:uid user) (passwd:gid user)))))))

(define misskey-oci-containers
  (match-record-lambda <misskey-configuration>
      (image config data-directory log-file )
    (let ((config-file
           (mixed-text-file
            "misskey.yaml"
            #~(string-append #$@(serialize-yaml-config config) "\n"))))
      (list (oci-container-configuration
             (user "misskey")
             (group "docker")
             (image image)
             (provision "misskey")
             (requirement '(postgresql redis))
             (log-file log-file)
             (respawn? #t)
             (network "host")
             (volumes
              `((,(string-append data-directory "/files") . "/misskey/files")
                (,config-file . "/misskey/.config/default.yml"))))))))

(define misskey-service-type
  (service-type
   (name 'misskey)
   (extensions
    (list (service-extension account-service-type
                             (const %misskey-accounts))
          (service-extension postgresql-role-service-type
                             (const %misskey-postgresql-role))
          (service-extension log-rotation-service-type
                             (compose list misskey-configuration-log-file))
          (service-extension activation-service-type
                             misskey-activation)
          (service-extension oci-container-service-type
                             misskey-oci-containers)))
   (default-value (misskey-configuration))
   (description "Run Misskey, an interplanetary microblogging platform.")))


;;
;; Vaultwarden
;;


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
           (group "docker")
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
          (service-extension log-rotation-service-type
                             (compose list vaultwarden-configuration-log-file))
          (service-extension oci-container-service-type
                             vaultwarden-oci-containers)))
   (default-value (vaultwarden-configuration))
   (description "Run Vaultwarden, a Bitwarden compatible server.")))
