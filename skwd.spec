%global forgeurl https://github.com/liixini/skwd
%global commit %{?_commit}%{!?_commit:HEAD}
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:           skwd
Version:        0
Release:        1.%{shortcommit}%{?dist}
Summary:        A skewed take on desktop shells - Quickshell/QML desktop environment
License:        MIT
URL:            %{forgeurl}
Source0:        %{forgeurl}/archive/%{commit}/%{name}-%{shortcommit}.tar.gz

BuildArch:      noarch

Requires:       quickshell
Requires:       qt6-qtmultimedia
Requires:       qt6-qtconnectivity
Requires:       python3
Requires:       python3-requests
Requires:       python3-pillow
Requires:       jq
Requires:       ffmpeg-free
Requires:       parallel
Requires:       google-roboto-fonts
Requires:       google-roboto-mono-fonts
Requires:       fontawesome-fonts-all
Requires:       gdouros-symbola-fonts
Requires:       matugen
Requires:       playerctl
Requires:       cava
Requires:       libnotify
Requires:       awww
Requires:       mpvpaper
Requires:       ImageMagick

Recommends:     linux-wallpaperengine
Recommends:     ollama
Recommends:     grim
Recommends:     niri

%description
SKWD is a Quickshell/QML-based desktop shell supporting multiple Wayland
compositors including niri, hyprland, sway, and KDE Plasma (kwin).

%prep
%autosetup -n %{name}-%{commit}

%install
install -dm755 %{buildroot}%{_datadir}/skwd

install -Dm644 shell.qml %{buildroot}%{_datadir}/skwd/shell.qml
cp -r qml %{buildroot}%{_datadir}/skwd/qml
cp -r ext %{buildroot}%{_datadir}/skwd/ext
cp -r images %{buildroot}%{_datadir}/skwd/images
cp -r scripts %{buildroot}%{_datadir}/skwd/scripts

chmod +x %{buildroot}%{_datadir}/skwd/scripts/bash/*
chmod +x %{buildroot}%{_datadir}/skwd/scripts/python/*
rm -rf %{buildroot}%{_datadir}/skwd/scripts/.venv
rm -rf %{buildroot}%{_datadir}/skwd/scripts/python/__pycache__

install -dm755 %{buildroot}%{_datadir}/skwd/data
install -Dm644 data/config.json.example %{buildroot}%{_datadir}/skwd/data/config.json.example
install -Dm644 data/secrets.json.example %{buildroot}%{_datadir}/skwd/data/secrets.json.example
install -Dm644 data/apps.json.example %{buildroot}%{_datadir}/skwd/data/apps.json.example

install -Dm644 LICENSE %{buildroot}%{_datadir}/licenses/%{name}/LICENSE

install -dm755 %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/skwd << 'EOF'
#!/bin/sh
export SKWD_INSTALL=%{_datadir}/skwd
exec quickshell -p %{_datadir}/skwd "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/skwd

install -dm755 %{buildroot}%{_sysconfdir}/profile.d
cat > %{buildroot}%{_sysconfdir}/profile.d/skwd.sh << 'EOF'
export SKWD_INSTALL=%{_datadir}/skwd
EOF
chmod 644 %{buildroot}%{_sysconfdir}/profile.d/skwd.sh

%files
%license LICENSE
%{_bindir}/skwd
%{_datadir}/skwd/
%config %{_sysconfdir}/profile.d/skwd.sh

%post
echo ""
echo "Run the setup script to generate user config:"
echo "    /usr/share/skwd/scripts/bash/setup"
echo ""
echo "Then launch with: skwd"
echo ""

%changelog
* Sat Mar 15 2026 liixini - 0-1
- KDE Plasma (kwin) support
- Initial COPR package
