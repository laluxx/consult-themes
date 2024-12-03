;;; consult-themes.el --- Theme management system -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Laluxx

;; Author: Laluxx
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1") (consult "0.34"))
;; Keywords: faces, themes
;; URL: https://github.com/laluxx/consult-themes

;;; Commentary:

;; This package provides an enhanced theme switching experience using consult.
;; It categorizes themes into dark, light, and other categories, and provides
;; interactive functions to preview and switch between them.

;; TODO A way to discard defaults
;; TODO Add another category for starred themes
;; we could even let the creator know that someone starred ?
;; maybe star the github ?
;; TODO Save the background color and the last theme used
;; in `.emacs.d' on exit also modify the `early-init.el' on exit

;;; Code:

(require 'consult)
(require 'custom)
(require 'seq)

(defgroup consult-themes nil
  "Theme management with consult integration."
  :group 'faces
  :prefix "consult-themes-")

(defcustom consult-dark-themes
  '(doom-badger doom-pine doom-laserwave doom-one doom-1337 doom-nord
    doom-dark+ doom-henna doom-opera doom-rouge doom-xcode doom-snazzy
    doom-Iosvkem doom-dracula doom-gruvbox doom-horizon doom-lantern
    doom-molokai doom-peacock doom-vibrant doom-zenburn doom-ayu-dark
    doom-manegarm doom-material doom-miramare doom-old-hope doom-ephemeral
    doom-moonlight doom-palenight doom-sourcerer doom-spacegrey
    doom-ayu-mirage doom-plain-dark doom-acario-dark doom-city-lights
    doom-fairy-floss doom-monokai-pro doom-nord-aurora doom-tokyo-night
    doom-wilmersdorf doom-bluloco-dark doom-feather-dark doom-oceanic-next
    doom-oksolar-dark doom-material-dark doom-solarized-dark
    doom-tomorrow-night doom-challenger-deep doom-monokai-classic
    doom-monokai-machine doom-monokai-octagon doom-outrun-electric
    doom-monokai-spectrum doom-shades-of-purple doom-monokai-ristretto
    doom-solarized-dark-high-contrast ef-duo-dark ef-bio ef-dark ef-rosa
    ef-night ef-autumn ef-cherie ef-winter ef-elea-dark ef-symbiosis
    ef-trio-dark ef-maris-dark ef-melissa-dark ef-tritanopia-dark
    ef-deuteranopia-dark kaolin-bubblegum kaolin-dark kaolin-eclipse
    kaolin-ocean kaolin-shiva kaolin-aurora kaolin-galaxy kaolin-temple
    kaolin-blossom kaolin-mono-dark kaolin-valley-dark modus-vivendi
    ewal-doom-one ewal-doom-vibrant timu-caribbean spacemacs-dark)
  "List of dark color themes."
  :type '(repeat symbol)
  :group 'consult-themes)

(defcustom consult-light-themes
  '(doom-plain doom-ayu-light doom-earl-grey doom-flatwhite doom-one-light
    doom-nord-light doom-opera-light doom-acario-light doom-homage-white
    doom-tomorrow-day doom-bluloco-light doom-feather-light
    doom-gruvbox-light doom-oksolar-light doom-solarized-light ef-day
    ef-frost ef-light ef-cyprus ef-kassio ef-spring ef-summer ef-arbutus
    ef-duo-light ef-elea-light ef-trio-light ef-maris-light
    ef-melissa-light ef-tritanopia-light ef-deuteranopia-light
    kaolin-light kaolin-breeze kaolin-mono-light kaolin-valley-light
    adwaita modus-operandi spacemacs-light)
  "List of light color themes."
  :type '(repeat symbol)
  :group 'consult-themes)

(defcustom consult-ugly-theme
  '(doom-nova doom-meltbus doom-ir-black doom-homage-black manoj-dark
    light-blue misterioso tango-dark tsdh-light wheatgrass whiteboard
    deeper-blue leuven-dark)
  "List of other themes."
  :type '(repeat symbol)
  :group 'consult-themes)

(defun consult-themes--theme-loadable-p (theme)
  "Check if THEME is loadable."
  (or (custom-theme-p theme)
      (locate-file (concat (symbol-name theme) "-theme.el")
                   (custom-theme--load-path))))

(defun consult-themes--filter-loadable-themes (themes)
  "Filter THEMES to only include loadable ones."
  (seq-filter #'consult-themes--theme-loadable-p themes))

(defun consult-themes--load-theme-safely (theme)
  "Load THEME safely, unloading all other themes first."
  (mapc #'disable-theme custom-enabled-themes)
  (condition-case err
      (load-theme theme t)
    (error (message "Error loading theme %s: %s" theme (error-message-string err))
           nil)))

(defun consult-themes--select (themes prompt)
  "Select and load a theme from THEMES with preview using PROMPT."
  (let* ((original-theme (car custom-enabled-themes))
         (saved-theme original-theme)
         (loadable-themes (consult-themes--filter-loadable-themes themes)))
    (if (null loadable-themes)
        (message "No loadable themes found in the list.")
      (consult--read
       (mapcar #'symbol-name loadable-themes)
       :prompt prompt
       :require-match t
       :category 'theme
       :history 'consult--theme-history
       :lookup (lambda (selected &rest _)
                 (setq selected (and selected (intern-soft selected)))
                 (or (and selected (car (memq selected loadable-themes)))
                     saved-theme))
       :state (lambda (action theme)
                (pcase action
                  ('return (unless (equal theme saved-theme)
                            (consult-themes--load-theme-safely theme)))
                  ((and 'preview (guard theme))
                   (unless (equal theme (car custom-enabled-themes))
                     (consult-themes--load-theme-safely theme)))))
       :default (symbol-name (or saved-theme 'default)))
      ;; Restore original theme if no theme was selected or if selected theme couldn't be loaded
      (unless (or (equal (car custom-enabled-themes) original-theme)
                  (member (car custom-enabled-themes) loadable-themes))
        (mapc #'disable-theme custom-enabled-themes)
        (when original-theme
          (load-theme original-theme t))))))

;;;###autoload
(defun consult-dark-themes ()
  "Select and load a theme from the list of dark themes with preview."
  (interactive)
  (consult-themes--select consult-dark-themes
                                 "Select dark theme: "))

;;;###autoload
(defun consult-light-themes ()
  "Select and load a theme from the list of light themes with preview."
  (interactive)
  (consult-themes--select consult-light-themes
                                 "Select light theme: "))

;;;###autoload
(defun consult-ugly-themes ()
  "Select and load a theme from the list of other themes with preview."
  (interactive)
  (consult-themes--select consult-ugly-theme
                                 "Select other theme: "))

(provide 'consult-themes)

;;; consult-themes.el ends here
