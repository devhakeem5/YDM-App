# YDM - Universal File & Video Downloader

A powerful and modern mobile application built with Flutter, designed to download files from the internet and extract videos from various social media platforms in all available formats and qualities.

---

## 🌍 Language / اللغة
[English](#english-version) | [العربية](#النسخة-العربية)

---

<a name="english-version"></a>
# English Version

## 🚀 Overview
**YDM** is a comprehensive file downloader and media extractor. It provides a seamless experience for finding, saving, and managing files from the web, with specialized support for downloading videos from social media platforms in any possible format.

## ✨ Key Features
- **YouTube Integration**: Complete support for YouTube video and audio extraction.
- **Facebook Downloader**: Easy video extraction from Facebook.
- **Built-in Web Browser**: Browse and detect downloadable media directly within the app.
- **Background Downloads**: Reliable download manager that works even when the app is closed.
- **Quality Selection**: Choose between various video resolutions (720p, 1080p, etc.) or audio-only (MP3).
- **Download Management**: Pause, resume, and retry downloads with ease.
- **Theme Support**: Modern UI with Light and Dark mode support.
- **Multilingual**: Supports English and Arabic out of the box.

## 🛠 Technical Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **YouTube Extraction**: [YoutubeExplode](https://pub.dev/packages/youtube_explode_dart)
- **Local Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **Deep Linking**: [Receive Sharing Intent](https://pub.dev/packages/receive_sharing_intent)

## 📁 Project Structure
```text
lib/
├── core/          # Themes, translations, and global constants
├── data/          # Models, services, and API providers
├── modules/       # UI screens (Splash, Home, Browser, Downloads, Settings)
├── routes/        # App routing configuration
└── widgets/       # Reusable UI components (if any)
```

## ⚙️ Getting Started
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

---

<a name="النسخة-العربية"></a>
# النسخة العربية

## 🚀 نظرة عامة
**YDM** هو تطبيق متطور لتنزيل الملفات من الإنترنت، يدعم تنزيل الفيديوهات من منصات التواصل الاجتماعي بجميع الصيغ والجودات الممكنة. يوفر تجربة سلسة للعثور على المحتوى وحفظه وإدارته بسهولة.

## ✨ المميزات الأساسية
- **تكامل مع يوتيوب**: دعم كامل لاستخراج الفيديو والصوت من يوتيوب.
- **تنزيل من فيسبوك**: استخراج سهل للفيديوهات من فيسبوك.
- **متصفح مدمج**: تصفح واكتشف الوسائط القابلة للتنزيل مباشرة داخل التطبيق.
- **التنزيل في الخلفية**: مدير تنزيلات موثوق يعمل حتى عند إغلاق التطبيق.
- **اختيار الجودة**: اختر بين مختلف دقات الفيديو (720p, 1080p, إلخ) أو الصوت فقط (MP3).
- **إدارة التنزيلات**: إيقاف، استئناف، وإعادة محاولة التنزيلات بكل سهولة.
- **دعم المظهر**: واجهة مستخدم حديثة تدعم الوضع الفاتح والداكن.
- **متعدد اللغات**: يدعم اللغتين العربية والإنجليزية.

## 🛠 التقنيات المستخدمة
- **الإطار البرمجي**: [Flutter](https://flutter.dev/)
- **إدارة الحالة**: [GetX](https://pub.dev/packages/get)
- **الشبكات**: [Dio](https://pub.dev/packages/dio)
- **استخراج بيانات يوتيوب**: [YoutubeExplode](https://pub.dev/packages/youtube_explode_dart)
- **التخزين المحلي**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **الإشعارات**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **مشاركة الروابط**: [Receive Sharing Intent](https://pub.dev/packages/receive_sharing_intent)

## 📁 هيكلية المشروع
```text
lib/
├── core/          # السمات، الترجمات، والثوابت العامة
├── data/          # النماذج، الخدمات، ومزودي البيانات
├── modules/       # شاشات الواجهة (البداية، الرئيسية، المتصفح، التنزيلات، الإعدادات)
├── routes/        # إعدادات المسارات والتنقل
└── widgets/       # العناصر الواجهة القابلة لإعادة الاستخدام
```

## ⚙️ البدء بالمشروع
1. **نسخ المشروع**:
   ```bash
   git clone <repository-url>
   ```
2. **تحميل المكتبات**:
   ```bash
   flutter pub get
   ```
3. **تشغيل التطبيق**:
   ```bash
   flutter run
   ```
