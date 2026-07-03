# إدارة الشغل - Flutter APK Release

نسخة 2.0 من تطبيق **إدارة الشغل**.

## ما الجديد في هذه النسخة

- تطبيق منطق شيت العربية داخل التطبيق.
- الإدارة تتحسب تلقائيًا.
- كمسيون مصطفى أو السائق الخاص يتخصم من وعاء التوزيع ثم يضاف كاملًا إلى نصيبك النهائي.
- حساب نصيبك، شريك 1، شريك 2، المديونية، صافي الموقف، والإدارة.
- استيراد Excel بصيغة XLSX.
- تصدير Excel بصيغة XLSX مع صفحة سجل يومي وملخص شهري.
- تصدير PDF ومشاركة التقارير.
- بصمة داخل التطبيق: `Created by M.R.Yassin`.
- زر ربط Google Drive موجود كمرحلة تجهيز، والتفعيل الكامل يحتاج إعداد Google Cloud وDrive API.
- GitHub Actions جاهز لبناء APK Release.

## بيانات الدخول الافتراضية

```text
username: admin
password: admin123
```

## طريقة رفع الملفات على GitHub

ارفع محتويات هذا المجلد في جذر الريبو بحيث يظهر عندك:

```text
.github
assets
lib
tools
pubspec.yaml
README_AR.md
analysis_options.yaml
```

لا ترفع ملف ZIP نفسه.

## بناء APK Release

من GitHub:

1. افتح تبويب Actions.
2. شغل Workflow باسم `Build Flutter Release APK`.
3. بعد نجاح البناء، حمّل Artifact باسم `EdaretElShoghl-Release-APK`.
4. ستجد داخله الملف:

```text
app-release.apk
```

## حلول مدمجة بناءً على التجربة السابقة

الـ Workflow يحتوي بالفعل على حلول المشاكل التي واجهناها:

- تحديث `intl` إلى `^0.20.2`.
- استخدام `CardThemeData` بدل `CardTheme`.
- تثبيت Android SDK 36.
- فرض `compileSdk 36` على التطبيق وكل Flutter plugins مثل `file_picker`.
- تثبيت Package ID الصحيح:

```text
com.edaretelshoghl.edaret_el_shoghl
```

## Google Drive

يوجد داخل الإعدادات زر:

```text
ربط Google Drive
```

لكن التفعيل الكامل يحتاج:

- Google Cloud Project.
- تفعيل Google Drive API.
- إنشاء OAuth Client Android.
- إضافة Package Name.
- إضافة SHA-1 الخاص بتوقيع التطبيق.

مهم: لا يتم طلب أو تخزين كلمة مرور Gmail داخل التطبيق.
