#!/bin/bash
# ==============================================================================
# Script Name: build_khaled_feed.sh
# Description: Generates Enigma2 Feed and Automatically Changes Section to Khaled Plugins
# Author: Khaled
# ==============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ---- إعدادات الجيت هاب الخاصة بك ----
GITHUB_USER="KhaledAli65"
REPO_NAME="plugins"  # اسم المستودع الخاص بك
BRANCH="main"
# ---------------------------------------------------------

echo -e "${CYAN}=======================================================${NC}"
echo -e "${GREEN}   بدء عملية بناء وتحديث الفيد الخاص بـ Khaled World   ${NC}"
echo -e "${CYAN}=======================================================${NC}"

WORK_DIR=$(cd "$(dirname "$0")" && pwd)
IPK_DIR="${WORK_DIR}/ipk_packages"
TAR_DIR="${WORK_DIR}/tar_packages"

mkdir -p "${IPK_DIR}"
mkdir -p "${TAR_DIR}"

mv "${WORK_DIR}"/*.ipk "${IPK_DIR}/" 2>/dev/null
mv "${WORK_DIR}"/*.tar.gz "${TAR_DIR}/" 2>/dev/null

if ! command -v opkg-make-index &> /dev/null; then
    opkg update && opkg install opkg-utils
fi

rm -f "${WORK_DIR}/Packages" "${WORK_DIR}/Packages.gz" "${WORK_DIR}/Release" "${WORK_DIR}/khaled.conf"
rm -f "${IPK_DIR}/Packages" "${IPK_DIR}/Packages.gz" "${IPK_DIR}/Release"

# ------------------------------------------------------------------------------
# الجزء الأول: توليد وتعديل الفهرس تلقائياً ليظهر باسمك
# ------------------------------------------------------------------------------
echo -e "${CYAN}[*] جاري توليد دليل الحزم وتغيير التصنيف إلى (Khaled Plugins)...${NC}"

if [ "$(ls -A "${IPK_DIR}"/*.ipk 2>/dev/null)" ]; then
    cd "${IPK_DIR}"
    
    # 1. توليد ملف الفهرس الخام
    opkg-make-index . > Packages.tmp
    
    # 2. السر هنا: السكربت يقوم باستبدال أي Section افتراضي إلى اسمك تلقائياً دون فتح البلجنات
    sed -i 's/^Section:.*/Section: Khaled Plugins/g' Packages.tmp
    
    # حفظ الملف النهائي
    mv Packages.tmp Packages
    
    # 3. ضغط الفهرس المعدل ليرسله للرسيفر جاهزاً
    gzip -c Packages > Packages.gz
    
    # إنشاء ملف Release
    cat <<EOF > Release
Architectures: all
Date: $(date -R)
Label: Khaled Plugins Feed
Description: Custom extensions by Khaled
EOF
    
    cp Packages Packages.gz Release "${WORK_DIR}/"
    echo -e "${GREEN}[✓] تم توليد وتعديل الفهرس ليظهر باسمك بنجاح!${NC}"
else
    echo -e "${YELLOW}[!] تنبيه: لا توجد ملفات .ipk داخل مجلد ipk_packages.${NC}"
fi

# ------------------------------------------------------------------------------
# الجزء الثاني: توليد ملف الـ opkg للمستخدمين
# ------------------------------------------------------------------------------
echo "src/gz khaled_repo https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}/ipk_packages" > "${WORK_DIR}/khaled.conf"

# ------------------------------------------------------------------------------
# الجزء الثالث: ملفات TAR.GZ
# ------------------------------------------------------------------------------
cd "${WORK_DIR}"
if [ "$(ls -A "${TAR_DIR}"/*.tar.gz 2>/dev/null)" ]; then
    echo "# قائمة ملفات tar.gz المتاحة للتنزيل المباشر" > "${WORK_DIR}/tar_list.txt"
    echo "# التحديث الأخير: $(date)" >> "${WORK_DIR}/tar_list.txt"
    for file in "${TAR_DIR}"/*.tar.gz; do
        filename=$(basename "$file")
        echo "${filename}" >> "${WORK_DIR}/tar_list.txt"
    done
fi

echo -e "${CYAN}=======================================================${NC}"
echo -e "${GREEN}   انتهت العملية! تم تعديل التصنيف تلقائياً دون فتح البلجنات ${NC}"
echo -e "${CYAN}=======================================================${NC}"

