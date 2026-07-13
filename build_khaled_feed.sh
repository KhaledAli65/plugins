#!/bin/bash
# ==============================================================================
# Script Name: build_khaled_feed.sh
# Description: Generates Enigma2 Feed index and opkg configuration file automatically
# Author: Khaled
# ==============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ---- إعدادات الجيت هاب الخاصة بك (تعدل مرة واحدة هنا) ----
GITHUB_USER="KhaledAli65"
REPO_NAME="plugins"  # ضع هنا اسم مستودعك على GitHub بدقة
BRANCH="main"
# ---------------------------------------------------------

echo -e "${CYAN}=======================================================${NC}"
echo -e "${GREEN}   بدء عملية بناء وتحديث الفيد الخاص بـ Khaled World ${NC}"
echo -e "${CYAN}=======================================================${NC}"

WORK_DIR=$(cd "$(dirname "$0")" && pwd)
echo -e "${CYAN}[*] مسار العمل الحالي: ${WORK_DIR}${NC}"

IPK_DIR="${WORK_DIR}/ipk_packages"
TAR_DIR="${WORK_DIR}/tar_packages"

mkdir -p "${IPK_DIR}"
mkdir -p "${TAR_DIR}"

mv "${WORK_DIR}"/*.ipk "${IPK_DIR}/" 2>/dev/null
mv "${WORK_DIR}"/*.tar.gz "${TAR_DIR}/" 2>/dev/null

if ! command -v opkg-make-index &> /dev/null; then
    echo -e "${YELLOW}[!] جاري تثبيت أدوات الفيد...${NC}"
    opkg update && opkg install opkg-utils
fi

echo -e "${CYAN}[*] تنظيف مخلفات الفهرسة السابقة...${NC}"
rm -f "${WORK_DIR}/Packages" "${WORK_DIR}/Packages.gz" "${WORK_DIR}/Release" "${WORK_DIR}/khaled.conf"
rm -f "${IPK_DIR}/Packages" "${IPK_DIR}/Packages.gz" "${IPK_DIR}/Release"

# ------------------------------------------------------------------------------
# الجزء الأول: ملفات IPK وتوليد الفهرس
# ------------------------------------------------------------------------------
echo -e "${CYAN}[*] جاري فحص ملفات IPK وتوليد دليل الحزم (Packages)...${NC}"

if [ "$(ls -A "${IPK_DIR}"/*.ipk 2>/dev/null)" ]; then
    cd "${IPK_DIR}"
    opkg-make-index . > Packages
    gzip -c Packages > Packages.gz
    cat <<EOF > Release
Architectures: all
Date: $(date -R)
Label: Khaled Plugins Feed
Description: Custom extensions by Khaled
EOF
    cp Packages Packages.gz Release "${WORK_DIR}/"
    echo -e "${GREEN}[✓] تم توليد فهرس الـ IPK بنجاح!${NC}"
else
    echo -e "${YELLOW}[!] تنبيه: لا توجد ملفات .ipk داخل مجلد ipk_packages.${NC}"
fi

# ------------------------------------------------------------------------------
# الجزء الجديد: توليد ملف الـ opkg (.conf) تلقائياً للمستخدم
# ------------------------------------------------------------------------------
echo -e "${CYAN}[*] جاري إنشاء ملف إعدادات opkg (khaled.conf) تلقائياً...${NC}"

# كتابة الرابط المباشر بناءً على إعدادات الـ GitHub المذكورة في الأعلى
echo "src/gz khaled_repo https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}/ipk_packages" > "${WORK_DIR}/khaled.conf"

echo -e "${GREEN}[✓] تم إنشاء ملف khaled.conf بنجاح في المجلد الرئيسي!${NC}"

# ------------------------------------------------------------------------------
# الجزء الثالث: ملفات TAR.GZ
# ------------------------------------------------------------------------------
echo -e "${CYAN}[*] جاري فحص وأرشفة ملفات TAR.GZ...${NC}"
cd "${WORK_DIR}"

if [ "$(ls -A "${TAR_DIR}"/*.tar.gz 2>/dev/null)" ]; then
    echo "# قائمة ملفات tar.gz المتاحة للتنزيل المباشر" > "${WORK_DIR}/tar_list.txt"
    echo "# التحديث الأخير: $(date)" >> "${WORK_DIR}/tar_list.txt"
    
    for file in "${TAR_DIR}"/*.tar.gz; do
        filename=$(basename "$file")
        echo "${filename}" >> "${WORK_DIR}/tar_list.txt"
    done
    echo -e "${GREEN}[✓] تم تحديث قائمة ملفات tar.gz بنجاح!${NC}"
else
    echo -e "${YELLOW}[!] تنبيه: لا توجد ملفات .tar.gz داخل مجلد tar_packages.${NC}"
fi

echo -e "${CYAN}=======================================================${NC}"
echo -e "${GREEN}   انتهت العملية! كل الملفات بما فيها khaled.conf جاهزة للرفع ${NC}"
echo -e "${CYAN}=======================================================${NC}"

