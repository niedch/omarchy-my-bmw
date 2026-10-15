{
  description = "My BMW widget for Omarchy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    omarchy = {
      url = "github:basecamp/omarchy/quattro";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    omarchy,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          quickshell
          upower
          wtype
          wl-clipboard
          cliphist
          libxkbcommon
          curl
          jq
          watchexec
          bluetui
          wiremix
          procps
          util-linux
          mise
          inotify-tools
          nodejs
          eslint
          prettier
          alejandra
          qt6.qtdeclarative
          # Python with dateutil for scripts
          (python3.withPackages (ps: [ps.python-dateutil]))
        ];

        shellHook = ''
          DEV_DIR="$PWD/.dev"
          STORE_STAMP="$DEV_DIR/.omarchy-store-path"

          # Sync upstream Omarchy store files if stamp is missing or store path changed
          if [ ! -f "$STORE_STAMP" ] || [ "$(cat "$STORE_STAMP")" != "${omarchy}" ]; then
            mkdir -p "$DEV_DIR"
            cp -rf "${omarchy}"/* "$DEV_DIR"/
            chmod -R u+w "$DEV_DIR"
            [ -d "$DEV_DIR/bin" ] && chmod -R +x "$DEV_DIR/bin"
            echo "${omarchy}" > "$STORE_STAMP"
          fi

          # Create directories
          mkdir -p "$DEV_DIR/Videos" "$DEV_DIR/Pictures"
          mkdir -p "$DEV_DIR/.local/state/omarchy/current"
          mkdir -p "$DEV_DIR/.local/state/omarchy/toggles"
          mkdir -p "$DEV_DIR/.local/state/omarchy/indicators"
          mkdir -p "$DEV_DIR/.config/omarchy/plugins"
          mkdir -p "$DEV_DIR/qml-imports/qs"

          # QML import bridges
          ln -sfn "$DEV_DIR/shell/Commons" "$DEV_DIR/qml-imports/qs/Commons"
          ln -sfn "$DEV_DIR/shell/Ui" "$DEV_DIR/qml-imports/qs/Ui"

          # Theme and wallpaper
          echo "kanagawa" > "$DEV_DIR/.local/state/omarchy/current/theme.name"
          ln -sfn "$DEV_DIR/themes/kanagawa" "$DEV_DIR/.local/state/omarchy/current/theme"
          ln -sfn "$DEV_DIR/themes/kanagawa/backgrounds/1-kanagawa.jpg" "$DEV_DIR/.local/state/omarchy/current/background"

          # Session marker
          SESSION_ID="''${OMARCHY_SESSION_ID:-''${HYPRLAND_INSTANCE_SIGNATURE:-omarchy-dev-session}}"
          echo "$SESSION_ID" > "$DEV_DIR/.local/state/omarchy/background-intro.session-id"

          # Plugin registration
          rm -rf "$DEV_DIR/.config/omarchy/plugins/omarchy-my-bmw"
          ln -sfn "$PWD" "$DEV_DIR/.config/omarchy/plugins/my-bmw"

          # Write the minimal bar layout
          cat << 'EOF' > "$DEV_DIR/.config/omarchy/shell.json"
          {
            "version": 1,
            "bar": {
              "position": "top",
              "layout": {
                "left": [
                  { "id": "omarchy.workspaces" }
                ],
                "center": [
                  { "id": "omarchy.clock" },
                  { "id": "my-bmw" }
                ],
                "right": [
                  { "id": "omarchy.audio" },
                  { "id": "omarchy.indicators" }
                ]
              }
            },
            "plugins": []
          }
          EOF

          # Exports
          export OMARCHY_PATH="$DEV_DIR"
          export PATH="$DEV_DIR/bin:$PATH"
          export QS_CONFIG_PATH="$DEV_DIR/shell"
          export QML_IMPORT_PATH="${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.quickshell}/lib/qt-6/qml:$PWD/.dev/qml-imports:$DEV_DIR/shell"
          export QML2_IMPORT_PATH="$QML_IMPORT_PATH"
          export QT_QUICK_BACKEND="''${QT_QUICK_BACKEND:-software}"

          # Banners and message
          echo -e "\033[1;32m=== omarchy-my-bmw Dev Shell ===\033[0m"
          mise tasks ls
        '';
      };
    });
  };
}
