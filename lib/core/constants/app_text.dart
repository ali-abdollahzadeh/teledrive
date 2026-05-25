/// Centralized UI text constants for TeleDrive.
///
/// Use these constants for all user-visible strings: button labels, page
/// titles, form labels, validation messages, error messages, empty-state
/// messages, and dialog texts.
///
/// Internal/technical values (route names, API paths, database keys, debug
/// messages) live separately in [AppConstants].
class AppText {
  AppText._();

  // ---------------------------------------------------------------------------
  // Welcome screen
  // ---------------------------------------------------------------------------
  static const getStarted = 'Get Started';
  static const dataStaysOnDevice =
      'Your data never leaves your Telegram account.';

  static const welcomeHeadline = 'TeleDrive';
  static const welcomeSubtitlePart1 = 'Your ';
  static const welcomeSubtitlePart2 = 'Telegram';
  static const welcomeSubtitlePart3 = ', your ';
  static const welcomeSubtitlePart4 = 'cloud';
  static const welcomeSubtitlePart5 = '.';

  static const featurePrivacyTitle = 'Absolute Privacy';
  static const featurePrivacySubtitle = 'Zero trackers. Locked safely in your Telegram.';
  
  static const featureSpaceTitle = 'Infinite Space';
  static const featureSpaceSubtitle = 'Never hit a limit, completely free of caps.';
  
  static const featureFastTitle = 'Blazing Fast';
  static const featureFastSubtitle = 'Optimized transfers to save you time.';
  
  static const featureFoldersTitle = 'Smart Folders';
  static const featureFoldersSubtitle = 'Easily sort and structure your digital life.';
  
  static const welcomeFooter = '100% private. Stored entirely on your Telegram.';

  // Feature pills
  static const pillPrivate = 'Private';
  static const pillUpload = 'Upload';
  static const pillOrganize = 'Organize';
  static const pillPreview = 'Preview';

  // Theme toggle tooltips
  static const tooltipDarkMode = 'Dark mode';
  static const tooltipLightMode = 'Light mode';
  static const tooltipSystemTheme = 'System theme';

  // ---------------------------------------------------------------------------
  // Auth — API credentials screen
  // ---------------------------------------------------------------------------
  static const connectAccount = 'Connect Account';

  // login page
  static const signInWithTelegram = 'Sign In With Telegram';
  static const enterYourPhone =
      'Enter the phone number \n linked to your Telegram account.';

  // Form labels & hints
  static const phoneNumber = 'Phone Number';
  static const phoneNumberHint = '+1 234 567 8900';
  static const enterPhoneNumber = 'Enter your phone number';

  static const phoneLoginDescription =
      'We use your phone number only to log in to your Telegram account.';

  // Validation messages
  static const phoneNumberRequired =
      'Phone number connected to Telegram is required';
  static const phoneNumberInvalid =
      'Enter a valid phone number connected to Telegram';

  // Info card
  static const telegramSessionStoredOnDevice =
      'Your telegram session is stored only on your device. It never leaves your phone.';

  // Button
  static const continueButton = 'Continue';

  // ---------------------------------------------------------------------------
  // Auth — Code verification screen
  // ---------------------------------------------------------------------------
  static const verifyCode = 'Verify Code';
  static const enterVerificationCode = 'Enter verification code';
  static const codeSentTo =
      'Check Telegram for the code sent to '; // append phone number
  static const verificationCode = 'Verification Code';
  static const verificationCodeHint = '12345';
  static const pleaseEnterFullCode = 'Please enter the full verification code';
  static const didntReceiveCode = "Didn’t get the code in Telegram?";
  static const resendIn = 'Resend in '; // append countdown string, e.g. "60s"
  static const resend = 'Resend';
  static const verify = 'Verify';

  // ---------------------------------------------------------------------------
  // Auth — Password / 2-step verification screen
  // ---------------------------------------------------------------------------
  static const twoStepVerification = 'Two-Step Verification';
  static const twoStepEnabled = '2-Step verification enabled';
  static const enterTwoStepPassword =
      'Enter your Telegram two-step verification password to continue.';
  static const password = 'Password';
  static const passwordHint = '••••••••';
  static const verifyPassword = 'Verify Password';

  // ---------------------------------------------------------------------------
  // Drive — home screen
  // ---------------------------------------------------------------------------
  static const appTitle = 'TeleDrive';
  static const upload = 'Upload';
  static const uploadingFiles = 'Uploading'; // append " N file(s)..."
  static const uploadingFilesSuffix = 'file(s)...';

  // Tooltip labels (app bar)
  static const tooltipSearch = 'Search';
  static const tooltipToggleView = 'Toggle view';
  static const tooltipCreateFolder = 'Create folder';
  static const createFolderTelegramNote =
      'A private Telegram channel will be created in your account to store these files.';
  static const tooltipSettings = 'Settings';
  static const tooltipDeleteSelected = 'Delete selected';

  // Create-folder dialog
  static const createFolder = 'Create Folder';
  static const folderNameHint = 'Folder name';
  static const cancel = 'Cancel';
  static const create = 'Create';

  // Upload destination sheet
  // "Upload N file(s) to..." is built dynamically in the screen.

  // Empty state
  static const noFilesYet = 'No files yet';
  static const uploadFirstFile = 'Upload your first file to get started';

  // Loading
  static const loadingFiles = 'Loading files...';

  // Selected count suffix (built dynamically: "$n selected")
  static const selected = 'selected';

  // Deletion snack-bar
  static const undo = 'UNDO';
  static const willBeDeleted =
      'will be deleted'; // for single file: '"name" will be deleted'
  static const filesWillBeDeleted =
      'files will be deleted'; // for multiple files

  // Filter chip labels
  static const filterAll = 'All';
  static const filterImages = 'Images';
  static const filterVideos = 'Videos';
  static const filterAudio = 'Audio';
  static const filterPdf = 'PDF';
  static const filterDocs = 'Docs';
  static const filterArchives = 'Archives';
  static const filterOther = 'Other';

  // Sort menu items
  static const sortNewest = 'Newest first';
  static const sortOldest = 'Oldest first';
  static const sortNameAZ = 'Name A\u2013Z';
  static const sortNameZA = 'Name Z\u2013A';
  static const sortLargest = 'Largest first';
  static const sortSmallest = 'Smallest first';

  // File count in folder list
  static const fileCountSuffix = 'files'; // e.g. "3 files"

  // ---------------------------------------------------------------------------
  // Drive — file details screen
  // ---------------------------------------------------------------------------
  static const fileDetails = 'File Details';
  static const fileNotFound = 'File not found';
  static const infoLabelSize = 'Size';
  static const infoLabelUploaded = 'Uploaded';
  static const infoLabelType = 'Type';
  static const infoLabelMessageId = 'Message ID';
  static const startingDownload = 'Starting download...';
  static const downloadingPercent = 'Downloading'; // append " N%"
  static const open = 'Open';
  static const download = 'Download';
  static const share = 'Share';
  static const downloading = 'Downloading...';
  static const delete = 'Delete';
  static const downloadFailed = 'Download failed: '; // append error
  static const fileDownloadedTo = 'File downloaded to: '; // append path
  static const noPreviewAvailable =
      'File downloaded. In-app preview is not available for this file type.';

  // ---------------------------------------------------------------------------
  // Drive — folder screen
  // ---------------------------------------------------------------------------
  static const folderIsEmpty = 'Folder is empty';
  static const uploadFilesToFolder = 'Upload files to '; // append folder name
  static const downloadedSnack = 'downloaded'; // e.g. "file.jpg downloaded"
  static const shareFailed = 'Share failed: '; // append error

  // ---------------------------------------------------------------------------
  // Search screen
  // ---------------------------------------------------------------------------
  static const searchHint = 'Search files...';
  static const searchYourFiles = 'Search your files';
  static const searchSubtitle =
      'Type to search across all your Telegram Drive files';
  static const noResultsFound = 'No results found';
  static const noResultsSubtitle = 'Try a different search term or filter';

  // ---------------------------------------------------------------------------
  // Settings screen
  // ---------------------------------------------------------------------------
  static const settingsTitleTheme = 'Theme';
  static const settingsSubtitleTheme = 'Choose your theme';
  static const themeSystem = 'System';
  static const themeDark = 'Dark';
  static const themeLight = 'Light';

  static const settingsTitlePrivacy = 'Privacy & Security';
  static const settingsSubtitlePrivacy = 'Session, Devices, Local Data';

  static const settingsTitleDataStorage = 'Data and Storage';
  static const settingsSubtitleDataStorage = 'Clear TDLib cache';
  static const cacheCleared = 'Cache cleared successfully';

  static const settingsTitleDownloadLocation = 'Download Location';

  static const settingsTitlePrivacyPolicy = 'Privacy Policy';
  static const settingsSubtitlePrivacyPolicy =
      'Rules for using TeleDrive responsibly';

  static const settingsTitleTermsOfUse = 'Terms of Use';
  static const settingsSubtitleTermsOfUse =
      'Legal terms for using TeleDrive services';

  static const settingsTitleLicenses = 'Open Source Licenses';
  static const settingsSubtitleLicenses = 'Flutter and package licenses';

  static const settingsTitleLogOut = 'Log Out';
  static const settingsSubtitleLogOut = 'Remove session from this device';

  static const telegramUser = 'Telegram User';
  static const errorLoadingProfile = 'Error loading profile';

  // Logout dialog
  static const logOutDialogTitle = 'Log Out';
  static const logOutDialogContent =
      'Are you sure you want to log out? Your session will be removed from this device.';
  static const logOutConfirm = 'Log Out';

  // Clear session dialog
  static const clearSessionDialogTitle = 'Clear Local Session';
  static const clearSessionDialogContent =
      'This will remove your local session data. You will need to log in again.';
  static const clearSessionConfirm = 'Clear';

// ---------------------------------------------------------------------------
// Privacy Policy screen
// ---------------------------------------------------------------------------
  static const privacyPolicyTitle = 'Privacy Policy';

  static const privacyCommitmentHeading = 'Our Commitment to Privacy';
  static const privacyCommitmentBody =
      'TeleDrive is built to respect your privacy. The app is designed to help you access and manage files from your own Telegram account without using our own servers.';

  static const privacySection1Title = 'No Personal Data Sold or Shared';
  static const privacySection1Body =
      'We do not sell your personal data, share it with advertisers, or use it for tracking. TeleDrive does not include ads or advertising trackers.';

  static const privacySection2Title = 'Telegram Account Access';
  static const privacySection2Body =
      'TeleDrive connects to your Telegram account only to provide app features such as file browsing, previewing, uploading, downloading, and opening your files. Authentication and Telegram data access are handled through Telegram/TDLib. You are responsible for using your Telegram account in accordance with Telegram’s Terms of Service.';

  static const privacySection3Title = 'Local Storage';
  static const privacySection3Body =
      'Some app data, such as session information, cached files, and downloaded files, may be stored locally on your device so the app can work correctly. You can remove this data by clearing the app data or uninstalling the app.';

  static const privacySection4Title = 'No TeleDrive Servers';
  static const privacySection4Body =
      'TeleDrive does not operate its own servers to store your Telegram files, messages, phone number, or account data. Your files remain on your device and within the Telegram account storage spaces you choose to use, such as Saved Messages or private channels.';

  static const privacySection5Title = 'Free and Open Source';
  static const privacySection5Body =
      'TeleDrive is a free and open-source project. There are no hidden fees, no ads, and no advertising trackers.';

  static const privacySection6Title = 'Independent Project';
  static const privacySection6Body =
      'TeleDrive is an independent project and is not affiliated with, endorsed by, or sponsored by Telegram.';

  static const privacyLastUpdated = 'Last updated: May 2026';

  // ---------------------------------------------------------------------------
  // Terms of Use screen
  // ---------------------------------------------------------------------------
  static const termsOfUseTitle = 'Terms of Use';

  static const termsIntroHeading = 'Using TeleDrive Responsibly';
  static const termsIntroBody =
      'By using TeleDrive, you agree to use the app responsibly and in accordance with Telegram’s Terms of Service and any applicable laws. TeleDrive is an independent tool that helps you manage files in your own Telegram account.';

  static const termsSection1Title = 'Independent Project';
  static const termsSection1Body =
      'TeleDrive is not affiliated with, endorsed by, or sponsored by Telegram. Telegram names, services, and infrastructure belong to Telegram and are governed by Telegram’s own rules and policies.';

  static const termsSection2Title = 'Your Telegram Account';
  static const termsSection2Body =
      'You are responsible for your own Telegram account and for all activity performed through it. TeleDrive only acts as a client interface to help you access and manage files using your account.';

  static const termsSection3Title = 'Acceptable Use';
  static const termsSection3Body =
      'You must not use TeleDrive to upload, store, share, or manage illegal, harmful, abusive, copyrighted, or otherwise unauthorized content. You must also avoid spam, automated abuse, mass account activity, or any behavior that may violate Telegram’s Terms of Service.';

  static const termsSection4Title = 'Telegram Limits and Availability';
  static const termsSection4Body =
      'TeleDrive depends on Telegram/TDLib and Telegram’s services. Features may stop working, become limited, or behave differently if Telegram changes its API, applies account limits, restricts activity, or changes its policies.';

  static const termsSection5Title = 'Private Channels and Folders';
  static const termsSection5Body =
      'Some TeleDrive folders may be created as private Telegram channels or use spaces such as Saved Messages. You should create and use these folders reasonably and avoid excessive automated creation, uploading, or other activity that may look abusive to Telegram.';

  static const termsSection6Title = 'No Guarantee of Service';
  static const termsSection6Body =
      'TeleDrive is provided as is, without warranties or guarantees. We do not guarantee that files, previews, downloads, uploads, sessions, or Telegram access will always work without errors or interruptions.';

  static const termsSection7Title = 'No Responsibility for User Content';
  static const termsSection7Body =
      'You are fully responsible for the files and content you access, upload, download, store, or manage through TeleDrive. TeleDrive does not review or control your personal Telegram content.';

  static const termsSection8Title = 'Open Source Project';
  static const termsSection8Body =
      'TeleDrive is a free and open-source project. You may review the source code to understand how the app works. Future versions may change features, limitations, or supported platforms.';

  static const termsLastUpdated = 'Last updated: May 2026';

  // ---------------------------------------------------------------------------
  // Preview screens (shared)
  // ---------------------------------------------------------------------------
  static const downloadFirst = 'Download first, then share.';
  static const audioDownloaded = 'Audio downloaded.';
  static const imageDownloaded = 'Image downloaded.';
  static const pdfDownloaded = 'PDF downloaded.';
  static const videoDownloaded = 'Video downloaded.';

  // Audio player
  static const audioPlayer = 'Audio Player';
  static const audioFile = 'Audio File';
  static const downloadingLabel = 'Downloading...';

  // Image preview
  static const imagePreview = 'Image Preview';
  static const imageNotFound = 'Image not found';
  static const downloadImageFirst =
      'Download this image first, then tap Open in App.';

  // PDF preview
  static const pdfViewer = 'PDF Viewer';
  static const pdfNotFound = 'PDF file not found';
  static const downloadPdfFirst =
      'Download this PDF first, then tap Open in App.';

  // Video preview
  static const videoPreview = 'Video Preview';
  static const downloadToPlayVideo = 'Download the file to play video';
  static const downloadToPlay = 'Download to Play';

  // ---------------------------------------------------------------------------
  // Common widgets
  // ---------------------------------------------------------------------------
  static const somethingWentWrong = 'Something went wrong';
  static const tryAgain = 'Try Again';

  // Upload progress card
  static const uploadingN = 'Uploading'; // append " N file(s)..."

  // ---------------------------------------------------------------------------
  // Auth & Platform Failures
  // ---------------------------------------------------------------------------
  static const registrationRequired = 'REGISTRATION_REQUIRED';
  static const registrationRequiredMessage =
      'An active Telegram account is required to proceed. Please create a Telegram account first.';
  static const phoneNumberInvalidKey = 'PHONE_NUMBER_INVALID';
  static const phoneNumberInvalidMessage = 'Invalid phone number format.';
  static const phoneCodeInvalid = 'PHONE_CODE_INVALID';
  static const phoneCodeInvalidMessage = 'The verification code is incorrect.';
  static const phoneCodeExpired = 'PHONE_CODE_EXPIRED';
  static const phoneCodeExpiredMessage = 'The code has expired. Please try again.';
  static const passwordHashInvalid = 'PASSWORD_HASH_INVALID';
  static const passwordHashInvalidMessage = 'Wrong password. Please try again.';
  static const connectionTimedOut = 'Connection timed out. Check your internet.';

  // ---------------------------------------------------------------------------
  // Upload Limitations (Size & Count Constraints)
  // ---------------------------------------------------------------------------
  static const tooManySharedFilesTitle = 'Too Many Shared Files';
  static const tooManySharedFilesContent =
      'You can only import up to 10 shared files at a time to prevent overwhelming the client.';
  static const tooManyFilesSelectedTitle = 'Too Many Files Selected';
  static const tooManyFilesSelectedContent =
      'You can only select and upload up to 10 files at a time to prevent overwhelming the client.';
  static const fileSizeExceededTitle = 'File Size Exceeded';
  static const fileExceedsTelegramLimit = 'File size exceeds the 2.0 GB Telegram limit.';
  static const ok = 'OK';

  static String sharedFileSizeExceededSingle(String filename) =>
      'The shared file "$filename" exceeds the 2.0 GB Telegram size limit. Import blocked.';

  static String sharedFileSizeExceededMultiple(String filenames) =>
      'The following shared files exceed the 2.0 GB Telegram size limit and have been blocked: $filenames.';

  static String fileSizeExceededSingle(String filename) =>
      'The file "$filename" exceeds the 2.0 GB Telegram size limit. Upload blocked.';

  static String fileSizeExceededMultiple(String filenames) =>
      'The following files exceed the 2.0 GB Telegram size limit and have been blocked: $filenames.';
}

