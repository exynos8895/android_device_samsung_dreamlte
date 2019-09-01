#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

VENDOR=samsung
DEVICE=dreamlte

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

LINEAGE_ROOT="${MY_DIR}"/../../..

HELPER="${LINEAGE_ROOT}/vendor/lineage/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

SECTION=
KANG=

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
setup_vendor "${DEVICE}" "${VENDOR}" "${LINEAGE_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

# Fix proprietary blobs
BLOB_ROOT="$LINEAGE_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary
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
