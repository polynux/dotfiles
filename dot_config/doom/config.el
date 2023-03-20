;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; 'Global'

(setq user-full-name "Guillaume Dorce"
      user-mail-address "polynu.dev@gmail.com")
(setq org-directory "~/org/")
(display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(setq doom-theme 'catppuccin)
(setq doom-font (font-spec :family "CaskaydiaCove Nerd Font" :size 14 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "CaskaydiaCove Nerd Font" :size 13))

;; 'Copilot'
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (("C-TAB" . 'copilot-accept-completion-by-word)
         ("C-<tab>" . 'copilot-accept-completion-by-word)
         :map copilot-completion-map
         ("<tab>" . 'copilot-accept-completion)
         ("TAB" . 'copilot-accept-completion)))

;; 'Neotree'
;; open neotree with M-e
(map! :leader
      :desc "Open neotree" "e" #'neotree-toggle)
(setq neo-smart-open t)
;; open file in new tab
(setq neo-create-file-auto-open t)


;; 'Centaurtabs'
(use-package! centaur-tabs
  :demand
  :config
  (centaur-tabs-mode t)
  (centaur-tabs-headline-match)
  (centaur-tabs-change-fonts "CaskaydiaCove Nerd Font" 120)
  (centaur-tabs-group-by-projectile-project)
  (centaur-tabs-group-buffer-groups))
(setq centaur-tabs-set-bar 'under)


;; 'Tree-sitter'
(use-package! tree-sitter
  :ensure t
  :config
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))
(use-package! tree-sitter-langs
  :ensure t
  :after tree-sitter)


;; 'Lanquages'
(use-package! typescript-mode
  :after tree-sitter
  :config
  (define-derived-mode typescriptreact-mode typescript-mode "TypeScript TSX")
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescriptreact-mode))
  (add-to-list 'tree-sitter-major-mode-language-alist '(typescriptreact-mode . tsx)))
(use-package! eglot :ensure t)


;;;;;; 'Keybindings' ;;;;;;

;; save with C-s
(global-set-key (kbd "C-s") 'save-buffer)

;; go to dashboard with M-d
(map! :leader
      :desc "Open dashboard" "d" #'+doom-dashboard/open)
;; left buffer with C-h
(global-set-key (kbd "C-h") 'evil-window-left)
;; right buffer with C-l
(global-set-key (kbd "C-l") 'evil-window-right)
;; left tab with S-h
(define-key evil-normal-state-map (kbd "H") 'centaur-tabs-backward)
;; right tab with S-l
(define-key evil-normal-state-map (kbd "L") 'centaur-tabs-forward)

;; indent with tab in visual mode
(map! :v "<tab>" #'indent-rigidly-right-to-tab-stop)
;; indent to the left with shift-tab in visual mode
(map! :v "<backtab>" #'indent-rigidly-left-to-tab-stop)
