# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

EGIT_REPO_URI="https://gitlab.com/void0/pinky-bar.git"

inherit git-r3

DESCRIPTION="Gather some system information and show it in this statusbar program"
HOMEPAGE="https://gitlab.com/void0/pinky-bar"

LICENSE="GPL-2"
SLOT="0"
IUSE="x11 alsa +net libnl +pci dvd sensors ncurses colours weather mpd drivetemp drivetemp-light smartemp perl python2"

DEPEND="
	sys-devel/m4
	sys-apps/gawk
	sys-devel/autoconf
	>=sys-devel/automake-1.14.1
"
RDEPEND="
	alsa? ( media-libs/alsa-lib )
	x11? ( x11-libs/libX11 )
	net? ( sys-apps/iproute2 )
	libnl? ( >=dev-libs/libnl-3.2.27 dev-util/pkgconfig )
	pci? ( sys-apps/pciutils )
	dvd? ( dev-libs/libcdio )
	sensors? ( sys-apps/lm_sensors )
	ncurses? ( sys-libs/ncurses )
	weather? ( net-misc/curl app-arch/gzip )
	mpd? ( media-sound/mpd media-libs/libmpdclient )
	drivetemp? ( net-misc/curl app-admin/hddtemp )
	drivetemp-light? ( app-admin/hddtemp )
	smartemp? ( sys-apps/smartmontools )
	python2? ( dev-lang/python:2.7= )
"
REQUIRED_USE="
	x11? ( !ncurses )
	ncurses? ( !x11 )
	drivetemp? ( !smartemp )
	drivetemp-light? ( !smartemp )
	smartemp? ( !drivetemp !drivetemp-light )
"

pkg_setup() {
	if use weather
	then
		einfo 'Currently, the weather USE flag will default to London,uk'
		einfo 'To specify other country and town youll have to supply them as variable.'
		einfo 'Here is how: # TWN="London,uk" USE="weather" emerge -a ...'
	fi
}

src_prepare() {
	default

	einfo 'Generating Makefiles'
	chmod +x bootstrap
	./bootstrap 'gentoo'
}

src_configure() {
	export PKG_CONFIG_PATH=/usr/bin/pkg-config

	econf \
		$(use_with x11) \
		$(use_with alsa) \
		$(use_with net) \
		$(use_with libnl) \
		$(use_with pci) \
		$(use_with dvd) \
		$(use_with sensors) \
		$(use_with ncurses) \
		$(use_with colours) \
		$(use_with weather) \
		$(use_with mpd) \
		$(use_with drivetemp) \
		$(use_with drivetemp-light) \
		$(use_with smartemp) \
		$(use_with perl) \
		$(use_with python2) \
		perl_script='/usr/share/pinkysc/pinky.pl' \
		python_script='/usr/share/pinkysc/pinky.py' \
		api_town="${TWN:-London,uk}" \
		api_key='28459ae16e4b3a7e5628ff21f4907b6f' \
		icons='/usr/share/icons/xbm_icons'
}

src_compile() {
	emake 'all'
}

src_install() {
	if use colours && ! use x11 && ! use ncurses
	then
		insinto /usr/share/icons/xbm_icons
		doins "${S}"/extra/xbm_icons/*
	fi

	if use perl || use python2
	then
		insinto /usr/share/pinkysc
		doins "${S}"/extra/scripts/pinky.{py,pl}
	fi

	emake DESTDIR="${D}" install
}

pkg_postinst() {
	use ncurses && \
		einfo 'You can combine the output from this program with pinky-curses'

	use perl && \
		einfo 'The perl script resides in /usr/share/pinkysc/pinky.pl'

	use python2 && \
		einfo 'The python2 script resides in /usr/share/pinkysc/pinky.py'

	einfo 'Please read the program man page'
}
