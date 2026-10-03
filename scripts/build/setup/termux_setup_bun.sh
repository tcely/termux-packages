# shellcheck shell=bash

termux_setup_bun() {
	local TERMUX_BUN_VERSION="${TERMUX_BUN_VERSION:-1.4.2}"
	readonly TERMUX_BUN_VERSION

	local release_url="https://github.com/oven-sh/bun/releases/download/bun-v${TERMUX_BUN_VERSION}"
	local zip_url="${release_url}/bun-linux-x64.zip"

	local TERMUX_BUN_SHA256='36368faef7527875d5ffa52e53cd48021741f2a83eb6208a8dd64068d422a913'
	if [[ '1.4.2' != "${TERMUX_BUN_VERSION}" ]]; then
		local artifact="${zip_url##*/}"
		local awk_program='/ [* ]'"${artifact%.zip}"'[.]zip$/ { print $1; exit; }'
		local manifest_url="${release_url}/SHASUMS256.txt.asc"
		printf -v TERMUX_BUN_SHA256 -- '%s' \
			"$(curl -sL -- "${manifest_url}" | awk "${awk_program}" || echo 'UNKNOWN_CHECKSUM')"
	fi
	readonly TERMUX_BUN_SHA256

	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "true" ]]; then
		if ! command -v bun; then
			printf -- '%s\n' \
				"Package 'bun' is not installed." \
				'You can install it with' \
				'' \
				'pkg install bun'
			exit 1
		fi
		return
	fi

	local TERMUX_BUN_DIR="${TERMUX_COMMON_CACHEDIR}/bun-${TERMUX_BUN_VERSION}"
	if [[ "${TERMUX_PACKAGES_OFFLINE-false}" == "true" ]]; then
		TERMUX_BUN_DIR="${TERMUX_SCRIPTDIR}/build-tools/bun-${TERMUX_BUN_VERSION}"
	fi

	if [[ ! -x "${TERMUX_BUN_DIR}/bun" ]]; then
		mkdir -p "${TERMUX_BUN_DIR}"
		local TERMUX_BUN_ZIP="${TERMUX_PKG_TMPDIR}/bun-v${TERMUX_BUN_VERSION}.zip"
		termux_download \
			"${zip_url}" \
			"${TERMUX_BUN_ZIP}" \
			"${TERMUX_BUN_SHA256}"

		unzip -oq "${TERMUX_BUN_ZIP}" -d "${TERMUX_PKG_TMPDIR}/bun-linux-x64-extracted"
		install "${TERMUX_PKG_TMPDIR}/bun-linux-x64-extracted/bun-linux-x64/bun" "${TERMUX_BUN_DIR}/bun"
		rm -rf "${TERMUX_PKG_TMPDIR}/bun-linux-x64-extracted" "${TERMUX_BUN_ZIP}"

		ln -sfT bun "${TERMUX_BUN_DIR}/bunx"
	fi

	export PATH="${TERMUX_BUN_DIR}:${PATH}"
}
