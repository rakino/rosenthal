;; SPDX-FileCopyrightText: 2022-2023 Hilton Chain <hako@ultrarare.space>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (rosenthal packages wm)
  #:use-module (srfi srfi-26)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system qt)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages image)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages man)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages web)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:export (wayland-for-hyprland))

(define libinput-minimal-for-hyprland
  (package
    (inherit libinput-minimal)
    (name "libinput-minimal")
    (version "1.26.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://gitlab.freedesktop.org/libinput/libinput.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "010bqvic471prhja1j5xqni9dhqc36ikqpxi8ih0fs13wph70p4s"))))))

(define udis86-for-hyprland
  (let ((revision "186")
        (commit "5336633af70f3917760a6d441ff02d93477b0c86"))
    (package
      (name "udis86")
      (version (git-version "1.7.2" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/canihavesomecoffee/udis86")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "0y5z1169wff578jylpafsww4px4y6gickhcs885a9c660d8xs9qy"))))
      (build-system gnu-build-system)
      (native-inputs (list autoconf automake libtool python-minimal-wrapper))
      (home-page "https://github.com/canihavesomecoffee/udis86")
      (synopsis "Disassembler Library for x86 and x86-64")
      (description
       "Udis86 is a disassembler for the x86 and x86-64 class of instruction
set architectures.  It consists of a C library called @code{libudis86} and a
command line tool called @code{udcli} that incorporates the library.")
      (license license:bsd-2))))

(define wayland-for-hyprland
  (package
    (inherit wayland)
    (name "wayland")
    (version "1.23.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://gitlab.freedesktop.org/" name
                                  "/" name  "/-/releases/" version "/downloads/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1vg5h6d94hglh7724q6wx9dpg4y0afvxksankp1hwbcy76lb4kw6"))))))

(define-public aquamarine
  (package
    (name "aquamarine")
    (version "0.4.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/aquamarine")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0x1zz1ywchs0awkjkvdgskgqnp6pz5lqwmgr8g0zc0i7inhyg1p3"))))
    (build-system cmake-build-system)
    (arguments
     (list #:cmake cmake-3.30
           ;; TODO
           #:tests? #f))
    (native-inputs
     (list gcc-13 hyprwayland-scanner pkg-config))
    (inputs
     (list eudev
           hwdata
           hyprutils
           libdisplay-info
           libglvnd
           libinput-minimal-for-hyprland
           libseat
           mesa
           pixman
           wayland
           wayland-protocols-next))
    (home-page "https://hyprland.org/")
    (synopsis "Linux rendering backend library")
    (description
     "Aquamarine is a C++-only Linux rendering backend library.  It provides
basic abstractions for an application to render on a Wayland session (in a
window) or a native DRM session.  It is agnostic of the rendering
API (Vulkan / OpenGL).")
    (license license:bsd-3)))

(define-public grimblast
  (let ((version "0.1")
        (revision "1")
        (commit "9d67858b437d4a1299be496d371b66fc0d3e01f6"))
    (package
      (name "grimblast")
      (version (git-version version revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/hyprwm/contrib")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1v0v5j7ingx80b5zpyz8ilfhz0kh9dcssnx6iwwl45zzgp915cpv"))))
      (build-system gnu-build-system)
      (arguments
       (list #:tests? #f                ;No tests.
             #:make-flags
             #~(list (string-append "PREFIX=" #$output))
             #:phases
             #~(modify-phases %standard-phases
                 (delete 'configure)
                 (add-after 'unpack 'chdir
                   (lambda _
                     (chdir "grimblast")))
                 (add-after 'chdir 'fix-paths
                   (lambda* (#:key inputs #:allow-other-keys)
                     (substitute* "grimblast"
                       (((string-append "\\<(" (string-join
                                                '("date"
                                                  "grim"
                                                  "slurp"
                                                  "hyprctl"
                                                  "hyprpicker"
                                                  "wl-copy"
                                                  "jq"
                                                  "notify-send")
                                                "|")
                                        ")\\>")
                         cmd)
                        (search-input-file
                         inputs (string-append "bin/" cmd)))))))))
      (native-inputs (list scdoc))
      (inputs
       (list coreutils-minimal
             grim
             jq
             libnotify
             slurp
             hyprland
             hyprpicker
             wl-clipboard))
      (home-page "https://github.com/hyprwm/contrib")
      (synopsis "Hyprland version of Grimshot")
      (description "A Hyprland version of Grimshot.")
      (license license:expat))))

(define-public hyprcursor
  (package
    (name "hyprcursor")
    (version "0.1.9")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprcursor")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0z3ar580n630145nq80qw0p8v0kai6knvhi6nr9z0y1jrb07b0ql"))))
    (build-system cmake-build-system)
    (arguments (list #:tests? #f))      ;TODO: No themes currently packaged.
    (native-inputs (list gcc-13 pkg-config))
    (inputs (list cairo hyprlang (librsvg-for-system) libzip tomlplusplus))
    (home-page "https://hyprland.org/")
    (synopsis "Hyprland cursor format, library and utilities")
    (description
     "This package provides Hyprland cursor format, library and utilities.")
    (license license:bsd-3)))

(define-public hyprland
  (package
    (name "hyprland")
    (version "0.44.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/hyprwm/Hyprland"
                                  "/releases/download/v" version
                                  "/source-v" version ".tar.gz"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  ;; Remove bundled sources and hyprpm utility.
                  (substitute* "CMakeLists.txt"
                    (("^add_subdirectory\\(hyprpm\\).*") ""))
                  (for-each delete-file-recursively
                            '("hyprpm"
                              "subprojects"))))
              (sha256
               (base32
                "0qzwdlj0bwj267285l3gjklhafn3bln90z985yws4j5cbp7bj0d9"))))
    (build-system cmake-build-system)
    (arguments
     (list #:cmake cmake-3.30
           #:tests? #f                  ;No tests.
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-path
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* "src/xwayland/Server.cpp"
                     (("Xwayland( \\{\\})" _ suffix)
                      (string-append
                       (search-input-file inputs "bin/Xwayland")
                       suffix)))
                   (substitute* (find-files "src" "\\.cpp$")
                     (("/usr/local(/bin/Hyprland)" _ path)
                      (string-append #$output path))
                     (("/usr") #$output)
                     (("\\<(addr2line|cat|lspci|nm)\\>" cmd)
                      (search-input-file
                       inputs (string-append "bin/" cmd)))))))))
    (native-inputs (list gcc-14 hyprwayland-scanner ld-wrapper pkg-config))
    (inputs
     (list aquamarine
           binutils
           cairo
           hyprcursor
           hyprland-protocols
           hyprlang
           hyprutils
           libinput-minimal-for-hyprland
           libxcursor
           libxkbcommon
           mesa
           pango
           pciutils
           udis86-for-hyprland
           wayland-for-hyprland
           wayland-protocols-next
           xcb-util-errors
           xcb-util-wm
           xorg-server-xwayland))
    (home-page "https://hyprland.org/")
    (synopsis "Dynamic tiling Wayland compositor")
    (description
     "Hyprland is a dynamic tiling Wayland compositor that doesn't sacrifice on
its looks.")
    (license license:bsd-3)))

(define-public hyprland-protocols
  (package
    (name "hyprland-protocols")
    (version "0.4.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprland-protocols")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0x86w7z3415qvixfhk9a8v5fnbnxdydzx366qz0mpmfg5h86qyha"))))
    (build-system meson-build-system)
    (home-page "https://hyprland.org")
    (synopsis "Wayland protocol extensions for Hyprland")
    (description
     "This package provides Wayland protocol extensions for Hyprland and it
exists in an effort to bridge the gap between Hyprland and KDE/Gnome's
functionality.  Since @code{wlr-protocols} is closed for new submissions, and
@code{wayland-protocols} is very slow with changes, this package will hold
protocols used by Hyprland to bridge the aforementioned gap.")
    (license license:bsd-3)))

(define-public hyprlang
  (package
    (name "hyprlang")
    (version "0.5.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprlang")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0yvfrz3hdyxzhngzhr0bgc5279ra5fv01hbfi6pdj84pz0lpaw02"))))
    (build-system cmake-build-system)
    (native-inputs (list gcc-13 pkg-config))
    (inputs (list hyprutils))
    (home-page "https://hyprland.org/hyprlang/")
    (synopsis "Official implementation library for hypr config language")
    (description
     "This package provides the official implementation for hypr configuration
language used in @code{hyprland}.")
    (license license:gpl3+)))

(define-public hyprpicker
  (package
    (name "hyprpicker")
    (version "0.4.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprpicker")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "11r06c62dqj81r27qhf36f3smnjyk3vz8naa655m8khv4qqvmvc2"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f                  ;No tests.
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-path
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* "src/clipboard/Clipboard.cpp"
                     (("wl-copy" cmd)
                      (search-input-file
                       inputs (string-append "bin/" cmd)))))))))
    (native-inputs (list gcc-13 hyprwayland-scanner pkg-config))
    (inputs
     (list cairo
           hyprutils
           libjpeg-turbo
           libxkbcommon
           pango
           wayland
           wayland-protocols-next
           wl-clipboard))
    (home-page "https://hyprland.org/")
    (synopsis "@code{wlroots}-compatible Wayland color picker")
    (description
     "This package provides a @code{wlroots}-compatible Wayland color picker.")
    (license license:bsd-3)))

(define-public hyprutils
  (package
    (name "hyprutils")
    (version "0.2.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprutils")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "01dh24rf62gb6xm32f7mfv6wx0dxprr1q9y73hvv7xanrjyia2zn"))))
    (build-system cmake-build-system)
    (native-inputs (list gcc-13 pkg-config))
    (inputs (list pixman))
    (home-page "https://hyprland.org/")
    (synopsis "C++ library for utilities used across Hyprland ecosystem")
    (description
     "This package provides a C++ library for utilities used across Hyprland
ecosystem.")
    (license license:bsd-3)))

(define-public hyprwayland-scanner
  (package
    (name "hyprwayland-scanner")
    (version "0.4.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/hyprwayland-scanner")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0r7ay4zjkfyr0xd73wz99qhnqjq7nma98gm51wm9lmai4igw90qw"))))
    (build-system cmake-build-system)
    (arguments (list #:tests? #f))      ;No tests.
    (inputs (list pugixml))
    (native-inputs (list gcc-13 pkg-config))
    (home-page "https://github.com/hyprwm/hyprwayland-scanner")
    (synopsis "Hyprland implementation of wayland-scanner, in and for C++")
    (description
     "This package provides a Hyprland implementation of wayland-scanner, in and
for C++.")
    (license license:bsd-3)))

(define-public xdg-desktop-portal-hyprland
  (package
    (name "xdg-desktop-portal-hyprland")
    (version "1.3.6")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyprwm/xdg-desktop-portal-hyprland")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "17ba9jkccyp8gv79ds70khgm5wm6x8zs5m9nkilq4n2j7fsa8cfl"))))
    (build-system qt-build-system)
    (arguments
     (list #:tests? #f                  ;No tests
           #:qtbase qtbase
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-path
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* (find-files "." "\\.cp?*$")
                     (("/bin/sh") "sh")
                     (("\\<(sh|grim|hyprctl|slurp)\\>" _ cmd)
                      (search-input-file inputs (string-append "bin/" cmd))))
                   (substitute* "src/shared/ScreencopyShared.cpp"
                     (("\\<(hyprland-share-picker)\\>" _ cmd)
                      (string-append #$output "/bin/" cmd))))))))
    (native-inputs
     (list gcc-13 hyprwayland-scanner pkg-config))
    (inputs
     (list bash-minimal
           grim
           hyprland
           hyprland-protocols
           hyprlang
           hyprutils
           mesa
           pipewire
           qtwayland
           sdbus-c++
           slurp
           wayland
           wayland-protocols))
    (home-page "https://github.com/hyprwm/xdg-desktop-portal-hyprland")
    (synopsis "XDG Desktop Portal backend for Hyprland")
    (description
     "This package provides @code{xdg-desktop-portal-hyprland}, which extends
@code{xdg-desktop-portal-wlr} for Hyprland with support for
@code{xdg-desktop-portal} screenshot and casting interfaces, while adding a few
extra portals specific to Hyprland, mostly for window sharing.")
    (license license:bsd-3)))
