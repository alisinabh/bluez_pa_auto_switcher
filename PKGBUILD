pkgname=bluez_pa_auto_switcher-git
pkgver=20210204
pkgrel=1
pkgdesc="Bluez auto profile switcher for pulseaudio bluetooth headsets"
arch=('any')
license=('MIT')
groups=()
depends=('ruby>=2.0.0')
makedepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=(git://github.com/alisinabh/bluez_pa_auto_switcher.git)
noextract=()
md5sums=('SKIP') #generate with 'makepkg -g'

_gitroot="git://github.com/alisinabh/bluez_pa_auto_switcher.git"
_gitname="bluez_pa_auto_switcher"

build() {
  msg "Connecting to GIT server...."

  if [[ -d $_gitname ]] ; then
    cd $_gitname && git pull origin
    msg "The local files are updated."
  else
    git clone "$_gitroot" "$_gitname"
  fi

  msg "GIT checkout done or server timeout"
  msg "Starting make..."



}

package() {
  msg "Package called!"
}
