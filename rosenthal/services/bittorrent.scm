;; SPDX-FileCopyrightText: 2022, 2023 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal services bittorrent)
  #:use-module (ice-9 format)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages bittorrent)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu services shepherd)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu system shadow)
  #:export (qbittorrent-configuration
            qbittorrent-service-type
            home-qbittorrent-service-type))

;;
;; qBittorrent
;;


(define-configuration qbittorrent-configuration
  (qbittorrent
   (file-like qbittorrent-nox)
   "The qBittorrent package to use, we need @command{qbittorrent-nox}.")
  (webui-port
   (integer 8080)
   "Change the Web UI port.")
  (profile-directory
   (string "/var/lib/qbittorrent")
   "Directory to store configuration files in.")
  (extra-options
   (list-of-strings '())
   "List of extra options.")
  (no-serialization))

(define %qbittorrent-accounts
  (list (user-group (name "qbittorrent") (system? #t))
        (user-account
         (name "qbittorrent")
         (group "qbittorrent")
         (system? #t)
         (comment "qBittorrent user")
         (home-directory "/var/empty")
         (shell (file-append shadow "/sbin/nologin")))))

;; Set default password to adminadmin
(define %qbittorrent-default-config-file
  (plain-file
   "qBittorrent.conf"
   (format #f "~
[LegalNotice]
Accepted=true
[Preferences]
WebUI\\Password_PBKDF2=\"@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)\"~%")))

(define qbittorrent-activation
  (match-record-lambda <qbittorrent-configuration>
      (profile-directory)
    #~(begin
        (use-modules (srfi srfi-26)
                     (guix build utils))
        (let ((user (getpwnam "qbittorrent"))
              (config-file
               (string-append
                #$profile-directory "/qBittorrent/config/qBittorrent.conf")))
          (unless (file-exists? config-file)
            (mkdir-p (dirname config-file))
            (copy-file #$%qbittorrent-default-config-file config-file)
            (map (cut chown <> (passwd:uid user) (passwd:gid user))
                 (cons #$profile-directory
                       (find-files #$profile-directory #:directories? #t))))))))

(define qbittorrent-shepherd-service
  (match-record-lambda <qbittorrent-configuration>
      (qbittorrent webui-port profile-directory extra-options)
    (list (shepherd-service
           (documentation "Run qbittorrent.")
           (provision '(qbittorrent))
           (requirement '(networking))
           (start #~(make-forkexec-constructor
                     (list #$(file-append qbittorrent "/bin/qbittorrent-nox")
                           #$(string-append "--webui-port="
                                            (number->string webui-port))
                           #$(string-append "--profile=" profile-directory)
                           #$@extra-options)
                     #:user "qbittorrent"
                     #:group "qbittorrent"
                     #:resource-limits '((nofile 65536 65536))))
           (stop #~(make-kill-destructor #:grace-period 1800))
           (actions
            (list (shepherd-configuration-action
                   (string-append profile-directory
                                  "/qBittorrent/config/qBittorrent.conf"))))))))

(define qbittorrent-service-type
  (service-type
   (name 'qbittorrent)
   (extensions
    (list (service-extension shepherd-root-service-type
                             qbittorrent-shepherd-service)
          (service-extension activation-service-type
                             qbittorrent-activation)
          (service-extension account-service-type
                             (const %qbittorrent-accounts))))
   (default-value (qbittorrent-configuration))
   (description "Run qBittorrent daemon.")))

(define home-qbittorrent-activation
  #~(let ((config-file
           (string-append
            (or (getenv "XDG_CONFIG_HOME")
                (string-append user-homedir "/.config"))
            "/qBittorrent/qBittorrent.conf")))
      (unless (file-exists? config-file)
        (mkdir-p (dirname config-file))
        (copy-file #$%qbittorrent-default-config-file config-file))))

(define home-qbittorrent-shepherd-service
  (match-record-lambda <qbittorrent-configuration>
      (qbittorrent webui-port extra-options)
    (list (shepherd-service
           (documentation "Run qbittorrent.")
           (provision '(qbittorrent))
           (requirement '())
           (start
            #~(make-forkexec-constructor
               (list
                #$(file-append qbittorrent "/bin/qbittorrent-nox")
                #$(string-append "--webui-port=" (number->string webui-port))
                #$@extra-options)))
           (stop #~(make-kill-destructor #:grace-period 1800))
           (auto-start? #f)))))

(define home-qbittorrent-service-type
  (service-type
   (name 'qbittorrent)
   (extensions
    (list (service-extension home-activation-service-type
                             (const home-qbittorrent-activation))
          (service-extension home-shepherd-service-type
                             home-qbittorrent-shepherd-service)))
   (default-value (qbittorrent-configuration))
   (description "Run qBittorrent daemon.")))
