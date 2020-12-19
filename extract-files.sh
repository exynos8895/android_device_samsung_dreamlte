#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=dreamlte
VENDOR=samsung

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

# Fix proprietary blobs
BLOB_ROOT="$ANDROID_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary

function patch_firmware() {
    hexdump -ve '1/1 "%.2X"' $1 | \
    sed "s/40000054DEC0AD/02000014000000/g" | \
    xxd -r -p > $1.patched

    mv $1.patched $1
}

# remove RKP crap
patch_firmware $BLOB_ROOT/vendor/firmware/fimc_is_lib.bin
patch_firmware $BLOB_ROOT/vendor/firmware/fimc_is_rta_2l2_3h1.bin
patch_firmware $BLOB_ROOT/vendor/firmware/fimc_is_rta_2l2_imx320.bin
patch_firmware $BLOB_ROOT/vendor/firmware/fimc_is_rta_imx333_3h1.bin
patch_firmware $BLOB_ROOT/vendor/firmware/fimc_is_rta_imx333_imx320.bin

"${MY_DIR}/setup-makefiles.sh"
