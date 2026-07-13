#!/bin/bash
# ==============================================================================
# Script Name: build_khaled_feed.sh
# Description: Unpacks IPKs, injects custom Section, repacks, and builds Feed
# Author: Khaled
# ==============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ---- إعدادات الجيت هاب والاسم الخاص بك ----
GITHUB_USER="KhaledAli65"
REPO_NAME="plugins"
BRANCH="main"
CUSTOM_SECTION="Khaled Plugins"
# ---------------------------------------------------------

echo -e "${CYAN}=======================================================${NC}"
echo -e "${GREEN}   بدء عملية التفكيك، حقن التصنيف، وإعادة بناء الفيد   ${NC}"
echo -e "${CYAN}=======================================================${NC}"

WORK_DIR=$(cd "$(dirname "$0")" && pwd)
IPK_DIR="${WORK_DIR}/ipk_packages"
TAR_DIR="${WORK_DIR}/tar_packages"
TMP_UNPACK="${WORK_DIR}/tmp_unpack"

mkdir -p "${IPK_DIR}"
mkdir -p "${TAR_DIR}"

# نقل الملفات الجديدة للمجلد الرئيسي إن وجدت
mv "${WORK_DIR}"/*.ipk "${IPK_DIR}/" 2>/dev/null
mv "${WORK_DIR}"/*.tar.gz "${TAR_DIR}/" 2>/dev/null

if [ ! "$(ls -A "${IPK_DIR}"/*.ipk 2>/dev/null)" ]; then
    echo -e "${RED}[X] لا توجد ملفات .ipk في مجلد ipk_packages للعمل عليها!${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# عملية التفكيك والحقن التلقائي داخل كل ملف IPK
# ------------------------------------------------------------------------------
echo -e "${CYAN}[*] جاري فحص الحزم وتعديل الـ control الداخلي تلقائياً...${NC}"

cd "${IPK_DIR}"
for ipk in *.ipk; do
    # تخطي الحزم المعدلة مسبقاً إذا أردت، أو تعديل الكل
    echo -e "${YELLOW} -> معالجة وتعديل حزمة: ${ipk}...${NC}"
    
    # إنشاء مجلد مؤقت للتفكيك
    rm -rf "${TMP_UNPACK}" && mkdir -p "${TMP_UNPACK}"
    
    # تفكيك ملف الـ ipk الأساسي
    ar x "${ipk}" --output="${TMP_UNPACK}" 2>/dev/null || tar -xf "${ipk}" -C "${TMP_UNPACK}" 2>/dev/null
    
    if [ -f "${TMP_UNPACK}/control.tar.gz" ]; then
        mkdir -p "${TMP_UNPACK}/control_files"
        tar -xf "${TMP_UNPACK}/control.tar.gz" -C "${TMP_UNPACK}/control_files"
        
        # التعديل السحري: استبدال الـ Section داخل ملف control الفعلي للبلجن
        if [ -f "${TMP_UNPACK}/control_files/control" ]; then
            sed -i "s/^Section:.*/Section: ${CUSTOM_SECTION}/g" "${TMP_UNPACK}/control_files/control"
            
            # إعادة ضغط ملف control.tar.gz الجديد
            cd "${TMP_UNPACK}/control_files"
            tar -czf "${TMP_UNPACK}/control.tar.gz" ./*
            cd "${IPK_DIR}"
            
            # إعادة تجميع الـ IPK النهائي المعدل بالكامل
            cd "${TMP_UNPACK}"
            ar r "${IPK_DIR}/${ipk}" ./debian-binary ./control.tar.gz ./data.tar.gz 2>/dev/null || tar -czf "${IPK_DIR}/${ipk}" ./debian-binary ./control.tar.gz ./data.tar.gz
            cd "${IPK_DIR}"
            echo -e "${GREEN}   [✓] تم تعديل قلب حزمة ${ipk} بنجاح!${NC}"
        fi
    fi
done

rm -rf "${TMP_UNPACK}"

# ------------------------------------------------------------------------------
# بناء الفيد الرسمي بناءً على الحزم المعدلة حديثاً
# ------------------------------------------------------------------------------
echo -e "${CYAN}[*] جاري توليد دليل الحزم النهائي (Packages)...${NC}"
if ! command -v opkg-make-index &> /dev/null; then
    opkg update && opkg install opkg-utils
fi

rm -f "${WORK_DIR}/Packages" "${WORK_DIR}/Packages.gz" "${WORK_DIR}/Release" "${WORK_DIR}/khaled.conf"
rm -f F_Packages F_Packages.gz F_Release

opkg-make-index . > Packages
sed -i "s/^Section:.*/Section: ${CUSTOM_SECTION}/g" Packages
gzip -c Packages > Packages.gz

cat <<EOF > Release
Architectures: all
Date: $(date -R)
Label: Khaled Plugins Feed
Description: Custom extensions by Khaled
EOF

cp Packages Packages.gz Release "${WORK_DIR}/"

# ------------------------------------------------------------------------------
# توليد ملف opkg وأرشفة ملفات tar.gz
# ------------------------------------------------------------------------------
echo "src/gz khaled_repo https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}/ipk_packages" > "${WORK_DIR}/khaled.conf"

cd "${WORK_DIR}"
if [ "$(ls -A "${TAR_DIR}"/*.tar.gz 2>/dev/null)" ]; then
    echo "# قائمة ملفات tar.gz المتاحة" > "${WORK_DIR}/tar_list.txt"
    for file in "${TAR_DIR}"/*.tar.gz; do
        filename=$(basename "$file")
        echo "${filename}" >> "${WORK_DIR}/tar_list.txt"
    done
fi

echo -e "${CYAN}=======================================================${NC}"
echo -e "${GREEN}   جاهز تماماً! تم حقن اسمك داخل ملفات الـ ipk بنجاح باهر! ${NC}"
echo -e "${CYAN}=======================================================${NC}"

