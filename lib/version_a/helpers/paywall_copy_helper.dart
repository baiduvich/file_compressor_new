
enum FileTypeOption { pdf, images, videos, documents, all }
enum UseCaseOption { work, school, personal }
enum PriorityOption { highQuality, smallestSize, fastSimple }

class PaywallCopy {
  final String headline;
  final String subheadline;
  final List<String> bullets;
  final String cta;
  final String socialProof;
  final List<String> bonusFeatures;

  PaywallCopy({
    required this.headline,
    required this.subheadline,
    required this.bullets,
    required this.cta,
    required this.socialProof,
    required this.bonusFeatures,
  });
}

class PaywallCopyHelper {
  static PaywallCopy getCopy(FileTypeOption type, UseCaseOption useCase, PriorityOption priority) {
    // Determine bonus features first based on use case + priority
    final List<String> bonus = _getBonusFeatures(useCase, priority);

    // PDF
    if (type == FileTypeOption.pdf) {
      if (useCase == UseCaseOption.work) {
        if (priority == PriorityOption.highQuality) {
          return PaywallCopy(
            headline: "Professional Documents, Perfect Quality",
            subheadline: "Compress presentations and contracts without losing a single detail",
            bullets: ["✨ Crystal-clear text and graphics", "📊 Perfect for client presentations", "🔒 Maintain professional standards", "📧 Email-ready, quality-preserved"],
            cta: "Impress Clients with Perfect PDFs",
            socialProof: "Trusted by 50K+ business professionals",
            bonusFeatures: bonus,
          );
        } else if (priority == PriorityOption.smallestSize) {
          return PaywallCopy(
            headline: "Maximum Compression for Business",
            subheadline: "Reduce file sizes by up to 90% - email and share instantly",
            bullets: ["🚀 Send files 10x faster", "💾 Attach to any email without limits", "📱 Save storage on all devices", "⚡ Instant uploads to cloud services"],
            cta: "Never Hit 'File Too Large' Again",
            socialProof: "100M+ files compressed by professionals",
            bonusFeatures: bonus,
          );
        } else { // fastSimple
          return PaywallCopy(
            headline: "Compress PDFs in Seconds",
            subheadline: "One tap compression - get back to work immediately",
            bullets: ["⚡ Instant compression (under 3 seconds)", "🎯 Smart presets - zero configuration", "📁 Batch process entire folders", "🔄 Auto-compress on import"],
            cta: "Save Hours Every Week",
            socialProof: "Rated 4.8★ for speed and simplicity",
            bonusFeatures: bonus,
          );
        }
      } else if (useCase == UseCaseOption.school) {
        if (priority == PriorityOption.highQuality) {
          return PaywallCopy(
            headline: "Submit Perfect Assignments",
            subheadline: "Keep your work pristine while meeting file size requirements",
            bullets: ["📚 Perfect for research papers", "🎓 Maintain diagram clarity", "✅ Meet professor requirements", "📖 Preserve formatting perfectly"],
            cta: "Get Better Grades with Quality Files",
            socialProof: "Used by students at 500+ universities",
            bonusFeatures: bonus,
          );
        } else if (priority == PriorityOption.smallestSize) {
          return PaywallCopy(
            headline: "Fit Any Assignment Limit",
            subheadline: "Reduce essays and reports by 85% - upload anywhere",
            bullets: ["📤 Beat any portal size limit", "💾 Save precious student storage", "📱 Upload faster on campus WiFi", "🎒 Fit more in cloud backups"],
            cta: "Never Miss a Deadline Again",
            socialProof: "2M+ students trust us daily",
            bonusFeatures: bonus,
          );
        } else {
             return PaywallCopy(
            headline: "Compress & Submit in Seconds",
            subheadline: "Quick compression right before the deadline",
            bullets: ["⏱️ Last-minute compression ready", "🎯 One-tap before submission", "📚 Works offline in library", "🔄 Compress multiple assignments at once"],
            cta: "Beat Every Deadline Stress-Free",
            socialProof: "The #1 student compression app",
            bonusFeatures: bonus,
          );
        }
      } else { // personal
        if (priority == PriorityOption.highQuality) {
           return PaywallCopy(
            headline: "Keep Your Memories Crystal Clear",
            subheadline: "Compress documents without losing what matters",
            bullets: ["🏠 Perfect for important documents", "📸 Preserve photo quality in PDFs", "💝 Family documents stay pristine", "🔐 Keep receipts and records clear"],
            cta: "Protect Your Important Documents",
            socialProof: "10M+ personal files protected",
            bonusFeatures: bonus,
          );
        } else if (priority == PriorityOption.smallestSize) {
           return PaywallCopy(
            headline: "Free Up Massive Storage Space",
            subheadline: "Compress personal documents by 90% - keep everything",
            bullets: ["💾 Store 10x more documents", "📱 Never delete important files", "☁️ Reduce cloud storage costs", "🎯 Keep decades of documents"],
            cta: "Never Run Out of Space Again",
            socialProof: "Users saved 50TB+ of storage",
            bonusFeatures: bonus,
          );
        } else {
           return PaywallCopy(
            headline: "Effortless Document Management",
            subheadline: "Compress files without thinking about it",
            bullets: ["🎯 Auto-compress on save", "📁 One tap for any document", "🔄 Set it and forget it", "💫 Works in background"],
            cta: "Simplify Your Digital Life",
            socialProof: "Rated easiest compression app",
            bonusFeatures: bonus,
          );
        }
      }
    } 
    // Images
    else if (type == FileTypeOption.images) {
       if (useCase == UseCaseOption.work) {
         if (priority == PriorityOption.highQuality) {
           return PaywallCopy(
             headline: "Pixel-Perfect Image Compression",
             subheadline: "Reduce file sizes while keeping professional quality",
             bullets: ["🎨 Perfect for portfolios and presentations", "📸 No visible quality loss", "🖼️ Maintain color accuracy", "💼 Client-ready every time"],
             cta: "Deliver Professional Images Faster",
             socialProof: "Used by 20K+ photographers & designers",
             bonusFeatures: bonus,
           );
         } else if (priority == PriorityOption.smallestSize) {
           return PaywallCopy(
             headline: "Shrink Images by 95%",
             subheadline: "Upload portfolios and galleries in seconds",
             bullets: ["🚀 Lightning-fast uploads", "💾 Store 20x more images", "📧 Attach hundreds to emails", "☁️ Save on cloud storage"],
             cta: "Upload Your Portfolio Instantly",
             socialProof: "500M+ images compressed",
             bonusFeatures: bonus,
           );
         } else {
           return PaywallCopy(
             headline: "Batch Compress in One Tap",
             subheadline: "Process hundreds of images instantly",
             bullets: ["⚡ Compress 100+ images at once", "🎯 Smart presets for your work", "📁 Drag, drop, done", "🔄 Background processing"],
             cta: "Save Hours on Every Project",
             socialProof: "Trusted by creative professionals",
             bonusFeatures: bonus,
           );
         }
       } else if (useCase == UseCaseOption.school) {
          if (priority == PriorityOption.highQuality) {
            return PaywallCopy(
              headline: "Submit Picture-Perfect Projects",
              subheadline: "Compress photos for assignments without quality loss",
              bullets: ["📚 Perfect for research and reports", "📊 Clear diagrams and screenshots", "🎓 Impress your professors", "✅ Meet all requirements"],
              cta: "Make Your Projects Stand Out",
              socialProof: "Top-rated by students",
              bonusFeatures: bonus,
            );
          } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
              headline: "Fit More Photos in Every Assignment",
              subheadline: "Compress images by 90% - include everything you need",
              bullets: ["📤 Upload more photos per project", "💾 Beat any portal size limit", "📱 Works on slow campus WiFi", "🎒 Save phone storage"],
              cta: "Include Every Important Image",
              socialProof: "Used in 1000+ schools",
              bonusFeatures: bonus,
            );
          } else {
             return PaywallCopy(
              headline: "Compress & Submit in Seconds",
              subheadline: "Quick image compression for busy students",
              bullets: ["⏱️ Process photos before class", "📚 One tap for entire albums", "🎯 No complicated settings", "📱 Works offline"],
              cta: "Never Stress About File Sizes",
              socialProof: "Students' #1 choice",
              bonusFeatures: bonus,
            );
          }
       } else { // personal
          if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Preserve Your Precious Memories",
               subheadline: "Compress photos without losing a single moment",
               bullets: ["📸 Keep vacation photos stunning", "👨‍👩‍👧‍👦 Family memories stay perfect", "💝 Share memories in full quality", "🎉 Event photos look amazing"],
               cta: "Protect Your Memories Forever",
               socialProof: "1B+ precious moments preserved",
               bonusFeatures: bonus,
             );
          } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Store 10x More Photos",
               subheadline: "Keep every memory without deleting anything",
               bullets: ["💾 Never delete photos again", "📱 Free up massive phone storage", "☁️ Reduce cloud storage costs", "🎯 Keep decades of memories"],
               cta: "Keep Every Precious Moment",
               socialProof: "Users freed 100TB+ of storage",
               bonusFeatures: bonus,
             );
          } else {
             return PaywallCopy(
               headline: "Effortless Photo Management",
               subheadline: "Compress photos automatically as you take them",
               bullets: ["📸 Auto-compress new photos", "🎯 One tap for entire albums", "🔄 Set it and forget it", "💫 Works in background"],
               cta: "Simplify Your Photo Library",
               socialProof: "The easiest photo app",
               bonusFeatures: bonus,
             );
          }
       }
    }
    // Videos
    else if (type == FileTypeOption.videos) {
       if (useCase == UseCaseOption.work) {
          if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Cinema-Quality Compression",
               subheadline: "Reduce video sizes while keeping stunning visuals",
               bullets: ["🎬 Perfect for client presentations", "📹 Maintain 4K quality options", "💼 Professional-grade results", "🎨 Preserve color grading"],
               cta: "Deliver Pro Videos Faster",
               socialProof: "Trusted by video professionals",
               bonusFeatures: bonus,
             );
          } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Shrink Videos by 90%",
               subheadline: "Share hours of footage without limits",
               bullets: ["🚀 Email videos of any length", "💾 Store entire projects easily", "☁️ Upload to clients instantly", "📧 No more file transfer tools"],
               cta: "Share Videos Without Limits",
               socialProof: "100M+ GB saved by pros",
               bonusFeatures: bonus,
             );
          } else {
             return PaywallCopy(
               headline: "Compress Videos in Seconds",
               subheadline: "Fast processing for busy professionals",
               bullets: ["⚡ Process while you work", "🎯 Smart presets ready", "📁 Batch process projects", "🔄 Background compression"],
               cta: "Save Hours Every Week",
               socialProof: "Fastest video compression",
               bonusFeatures: bonus,
             );
          }
       } else if (useCase == UseCaseOption.school) {
          if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Submit Perfect Video Projects",
               subheadline: "Compress presentations while keeping clarity",
               bullets: ["📚 Perfect for video essays", "🎓 Clear audio and visuals", "✅ Meet professor standards", "🎬 Impress with quality"],
               cta: "Ace Your Video Assignments",
               socialProof: "Used in film schools worldwide",
               bonusFeatures: bonus,
             );
          } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Fit Any Video Submission Limit",
               subheadline: "Reduce videos by 85% - upload anywhere",
               bullets: ["📤 Beat any portal limit", "💾 Save phone storage", "📱 Upload on campus WiFi", "🎒 Submit from anywhere"],
               cta: "Never Miss a Video Deadline",
               socialProof: "Students' go-to video tool",
               bonusFeatures: bonus,
             );
          } else {
             return PaywallCopy(
               headline: "Quick Video Compression",
               subheadline: "Process videos before the deadline",
               bullets: ["⏱️ Compress in minutes", "🎯 One tap for projects", "📚 No tech skills needed", "🔄 Process multiple videos"],
               cta: "Submit Videos Stress-Free",
               socialProof: "#1 for student videos",
               bonusFeatures: bonus,
             );
          }
       } else { // personal
          if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Keep Your Memories in HD",
               subheadline: "Compress family videos without losing quality",
               bullets: ["📹 Vacation videos stay stunning", "👨‍👩‍👧‍👦 Family moments preserved", "🎉 Events look amazing", "💝 Share memories in quality"],
               cta: "Preserve Every Special Moment",
               socialProof: "Billions of memories saved",
               bonusFeatures: bonus,
             );
          } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Store All Your Videos",
               subheadline: "Keep decades of memories without deleting",
               bullets: ["💾 Never delete videos again", "📱 Free up massive storage", "☁️ Reduce backup costs", "🎯 Keep everything forever"],
               cta: "Keep Every Precious Video",
               socialProof: "Users saved petabytes",
               bonusFeatures: bonus,
             );
          } else {
             return PaywallCopy(
               headline: "Effortless Video Storage",
               subheadline: "Compress videos automatically",
               bullets: ["📹 Auto-compress recordings", "🎯 One tap compression", "🔄 Background processing", "💫 Set it and forget it"],
               cta: "Simplify Your Video Library",
               socialProof: "Easiest video compression",
               bonusFeatures: bonus,
             );
          }
       }
    }
    // Documents
    else if (type == FileTypeOption.documents) {
        if (useCase == UseCaseOption.work) {
           if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Professional Document Compression",
               subheadline: "Reduce file sizes while keeping formatting perfect",
               bullets: ["📊 Preserve spreadsheet clarity", "📝 Maintain document formatting", "💼 Client-ready files", "🔒 Professional standards"],
               cta: "Share Perfect Documents",
               socialProof: "Trusted by Fortune 500 teams",
               bonusFeatures: bonus,
             );
           } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Shrink Documents by 80%",
               subheadline: "Email large files instantly",
               bullets: ["🚀 Attach huge spreadsheets", "💾 Store years of records", "📧 No file size limits", "☁️ Reduce storage costs"],
               cta: "Email Any File Size",
               socialProof: "Billions of docs compressed",
               bonusFeatures: bonus,
             );
           } else {
             return PaywallCopy(
               headline: "Instant Document Compression",
               subheadline: "One tap for any file type",
               bullets: ["⚡ Process in seconds", "🎯 Works with all formats", "📁 Batch compress folders", "🔄 Auto-compress on save"],
               cta: "Work Smarter, Not Harder",
               socialProof: "Saves teams 100+ hours/month",
               bonusFeatures: bonus,
             );
           }
        } else if (useCase == UseCaseOption.school) {
           if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Submit Perfect Assignments",
               subheadline: "Compress essays and reports without losing formatting",
               bullets: ["📚 Perfect for papers", "📊 Clear charts and tables", "✅ Formatting preserved", "🎓 Professor-approved"],
               cta: "Get Top Grades",
               socialProof: "A+ students choose us",
               bonusFeatures: bonus,
             );
           } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Fit Any Assignment Portal",
               subheadline: "Reduce documents by 80% - submit anywhere",
               bullets: ["📤 Beat all size limits", "💾 Save student storage", "📱 Upload faster", "🎒 Submit from anywhere"],
               cta: "Never Worry About Size Limits",
               socialProof: "Million+ students trust us",
               bonusFeatures: bonus,
             );
           } else {
             return PaywallCopy(
               headline: "Quick Compression for Students",
               subheadline: "Compress and submit in seconds",
               bullets: ["⏱️ Last-minute ready", "🎯 One-tap compression", "📚 All file types supported", "🔄 Batch process homework"],
               cta: "Beat Every Deadline",
               socialProof: "Students' #1 tool",
               bonusFeatures: bonus,
             );
           }
        } else { // personal
           if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Preserve Important Documents",
               subheadline: "Compress files without losing details",
               bullets: ["🏠 Perfect for records", "📋 Receipts stay clear", "💝 Important files preserved", "🔐 Maintain quality"],
               cta: "Protect Your Documents",
               socialProof: "Trusted for important files",
               bonusFeatures: bonus,
             );
           } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Store All Your Documents",
               subheadline: "Never delete important files again",
               bullets: ["💾 Keep decades of records", "📱 Free up storage", "☁️ Reduce backup costs", "🎯 Store everything"],
               cta: "Keep Every Important File",
               socialProof: "Users saved terabytes",
               bonusFeatures: bonus,
             );
           } else {
             return PaywallCopy(
               headline: "Effortless File Management",
               subheadline: "Automatic compression for peace of mind",
               bullets: ["🎯 Auto-compress documents", "📁 One tap for folders", "🔄 Background processing", "💫 Zero effort"],
               cta: "Simplify Your Digital Life",
               socialProof: "The easiest compression tool",
               bonusFeatures: bonus,
             );
           }
        }
    }
    // All Files
    else {
        if (useCase == UseCaseOption.work) {
           if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Universal Compression, Zero Compromise",
               subheadline: "Compress any file type while maintaining quality",
               bullets: ["🎯 PDF, images, videos, documents", "✨ Professional quality guaranteed", "💼 Perfect for any project", "🔒 Consistent results"],
               cta: "Compress Everything Professionally",
               socialProof: "Complete solution for businesses",
               bonusFeatures: bonus,
             );
           } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Maximum Compression for Everything",
               subheadline: "Reduce any file by up to 90%",
               bullets: ["🚀 Share anything instantly", "💾 Store 10x more files", "📧 Email without limits", "☁️ Slash storage costs"],
               cta: "Never Hit File Limits Again",
               socialProof: "Billions of files compressed",
               bonusFeatures: bonus,
             );
           } else {
             return PaywallCopy(
               headline: "Universal Compression in Seconds",
               subheadline: "One solution for all your files",
               bullets: ["⚡ Any file, instant results", "🎯 Smart compression presets", "📁 Batch process everything", "🔄 Automated workflows"],
               cta: "Simplify Your Entire Workflow",
               socialProof: "Saves teams 200+ hours/month",
               bonusFeatures: bonus,
             );
           }
        } else if (useCase == UseCaseOption.school) {
           if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Compress Any Assignment Perfectly",
               subheadline: "From essays to videos - quality preserved",
               bullets: ["📚 All assignment types supported", "✅ Professor-approved results", "🎓 Perfect submissions every time", "🔒 Quality you can trust"],
               cta: "Ace Every Assignment Type",
               socialProof: "Complete student solution",
               bonusFeatures: bonus,
             );
           } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Beat Any Portal Size Limit",
               subheadline: "Compress everything - submit anywhere",
               bullets: ["📤 Any file, any portal", "💾 Save precious storage", "📱 Upload on campus WiFi", "🎒 Complete freedom"],
               cta: "Submit Anything, Anywhere",
               socialProof: "Used by 2M+ students",
               bonusFeatures: bonus,
             );
           } else {
             return PaywallCopy(
               headline: "Your Complete Student Solution",
               subheadline: "Compress any assignment in seconds",
               bullets: ["⏱️ Fast for any file type", "🎯 One app for everything", "📚 Dead simple to use", "🔄 Bulk processing ready"],
               cta: "One App for All Assignments",
               socialProof: "Top student app 2024",
               bonusFeatures: bonus,
             );
           }
        } else { // personal
           if (priority == PriorityOption.highQuality) {
             return PaywallCopy(
               headline: "Preserve Everything You Love",
               subheadline: "Compress any file without losing what matters",
               bullets: ["💝 Photos, videos, documents", "🏠 Memories stay perfect", "📸 Quality you deserve", "🔐 Important files protected"],
               cta: "Protect All Your Memories",
               socialProof: "Trusted by 10M+ families",
               bonusFeatures: bonus,
             );
           } else if (priority == PriorityOption.smallestSize) {
             return PaywallCopy(
               headline: "Store Everything Forever",
               subheadline: "Never delete anything again",
               bullets: ["💾 Keep all your memories", "📱 Free up massive storage", "☁️ Reduce backup costs", "🎯 Complete peace of mind"],
               cta: "Keep Everything You Love",
               socialProof: "Petabytes of memories saved",
               bonusFeatures: bonus,
             );
           } else {
             return PaywallCopy(
               headline: "The Only Compression App You Need",
               subheadline: "Automatic compression for everything",
               bullets: ["🎯 Any file, one tap", "🔄 Set it and forget it", "💫 Works in background", "📁 Dead simple to use"],
               cta: "Simplify Everything",
               socialProof: "Rated #1 easiest app",
               bonusFeatures: bonus,
             );
           }
        }
    }
  }

  static List<String> _getBonusFeatures(UseCaseOption useCase, PriorityOption priority) {
    Set<String> features = {};

    // Use Case Specific
    switch (useCase) {
      case UseCaseOption.work:
        features.addAll(["🔐 Advanced encryption", "👥 Team collaboration tools", "📊 Usage analytics", "☁️ Priority cloud sync"]);
        break;
      case UseCaseOption.school:
        features.addAll(["🎒 Unlimited storage", "📚 Organize by class/subject", "🔄 Automatic backups", "📱 Offline mode"]);
        break;
      case UseCaseOption.personal:
        features.addAll(["💝 Family sharing (5 members)", "🎨 Custom watermarks", "🔒 Password protection", "📤 Direct social sharing"]);
        break;
    }

    // Priority Specific
    switch (priority) {
      case PriorityOption.highQuality:
        features.addAll(["🎛️ Advanced quality controls", "👁️ Before/after preview", "📏 Custom compression settings", "✨ Lossless options"]);
        break;
      case PriorityOption.smallestSize:
        features.addAll(["🚀 Ultra compression mode", "💾 Storage analytics", "📊 Space saved tracker", "🎯 Aggressive optimization"]);
        break;
      case PriorityOption.fastSimple:
        features.addAll(["⚡ Priority processing queue", "🎯 1-tap shortcuts", "🔄 Scheduled compression", "📁 Smart folders"]);
        break;
    }
    
    return features.toList();
  }
}
