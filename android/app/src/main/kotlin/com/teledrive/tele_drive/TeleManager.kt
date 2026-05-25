package dev.aliabdollahzadeh.teledrive

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.drinkless.tdlib.Client
import org.drinkless.tdlib.TdApi
import android.net.Uri
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Wraps the TDLib Java API (org.drinkless.tdlib) to manage Telegram authentication.
 *
 * Auth state machine:
 *   authorizationStateWaitTdlibParameters → sends API params automatically
 *   authorizationStateWaitPhoneNumber     → ready for phone number
 *   authorizationStateWaitCode            → code sent to user's Telegram app ✅
 *   authorizationStateWaitPassword        → 2FA password needed
 *   authorizationStateReady               → fully authenticated ✅
 */
class TeleManager(private val context: Context) {

    companion object {
        private const val TAG = "TeleManager"
    }

    private var client: Client? = null
    private var apiId: Int = 0
    private var apiHash: String = ""
    private var isInitialized: Boolean = false
    private val isClosing = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    // Callbacks fired on main thread → TelegramPlugin → Flutter
    var onAuthState: ((String) -> Unit)? = null
    var onError: ((String) -> Unit)? = null

    // ---------- Public API ----------

    @Synchronized
    fun initialize(apiId: Int, apiHash: String) {
        // Guard: if already initialized with same credentials and client is alive, skip
        if (isInitialized && this.apiId == apiId && this.apiHash == apiHash && client != null && !isClosing.get()) {
            Log.d(TAG, "TDLib already initialized, skipping re-init")
            return
        }

        // If a close is already in progress, wait for it to finish before proceeding
        if (isClosing.get()) {
            Log.d(TAG, "TDLib is currently closing, waiting before re-init")
            var waited = 0
            while (isClosing.get() && waited < 3000) {
                Thread.sleep(100)
                waited += 100
            }
        }

        // If there's an existing client, close it first to release the td.binlog file lock
        if (client != null) {
            Log.d(TAG, "Closing existing TDLib client before re-init")
            isClosing.set(true)
            val closeLatch = CountDownLatch(1)
            closeLatchRef = closeLatch
            try {
                client?.send(TdApi.Close()) {}
            } catch (e: Exception) {
                Log.w(TAG, "Error sending Close to old client: ${e.message}")
                isClosing.set(false)
                closeLatchRef = null
            }
            client = null
            isInitialized = false
            // Wait up to 3 seconds for TDLib to confirm it is fully closed
            val released = closeLatch.await(3, TimeUnit.SECONDS)
            Log.d(TAG, "TDLib close latch released=$released")
            isClosing.set(false)
            closeLatchRef = null
        }

        this.apiId = apiId
        this.apiHash = apiHash

        // Suppress verbose TDLib logging (1 = errors only)
        Client.execute(TdApi.SetLogVerbosityLevel(1))

        client = Client.create(::handleUpdate, null, null)
        isInitialized = true
    }

    // Latch used to wait for TDLib AuthorizationStateClosed during re-init
    private var closeLatchRef: CountDownLatch? = null

    fun sendPhoneNumber(phone: String) {
        client?.send(TdApi.SetAuthenticationPhoneNumber(phone, null), ::handleResult)
    }

    fun checkCode(code: String) {
        client?.send(TdApi.CheckAuthenticationCode(code), ::handleResult)
    }

    fun checkPassword(password: String) {
        client?.send(TdApi.CheckAuthenticationPassword(password), ::handleResult)
    }

    fun logout() {
        client?.send(TdApi.LogOut(), ::handleResult)
        client?.send(TdApi.Close(), ::handleResult)
        client = null
    }

    fun destroy() {
        client?.send(TdApi.Close(), ::handleResult)
        client = null
    }

    // ---------- Data API ----------
fun getMe(onResult: (Map<String, Any?>) -> Unit, onErr: (String) -> Unit) {
    client?.send(TdApi.GetMe()) { obj ->
        if (obj is TdApi.User) {
            val profilePhoto = obj.profilePhoto
            val smallPhotoFile = profilePhoto?.small

            val photoPath = smallPhotoFile?.local?.path
            val photoFileId = smallPhotoFile?.id

            val map = mapOf(
                "id" to obj.id,
                "firstName" to obj.firstName,
                "lastName" to obj.lastName,
                "phoneNumber" to obj.phoneNumber,
                "photoPath" to photoPath,
                "photoFileId" to photoFileId,
                "photoDownloaded" to (smallPhotoFile?.local?.isDownloadingCompleted ?: false)
            )

            mainHandler.post { onResult(map) }
        } else if (obj is TdApi.Error) {
            mainHandler.post { onErr(obj.message) }
        } else {
            mainHandler.post { onErr("Unexpected response from getMe") }
        }
    }
}

    /**
     * Load chat list, then return only channels/supergroups where the user
     * is Creator or Admin with canPostMessages rights.
     */
    fun getMyChats(limit: Int, onResult: (List<Map<String, Any>>) -> Unit, onErr: (String) -> Unit) {
        client?.send(TdApi.LoadChats(TdApi.ChatListMain(), limit)) { loadObj ->
            if (loadObj is TdApi.Error && loadObj.code != 404) {
                mainHandler.post { onErr(loadObj.message) }
                return@send
            }
            client?.send(TdApi.GetChats(TdApi.ChatListMain(), limit)) { chatsObj ->
                if (chatsObj is TdApi.Chats) {
                    val chatIds = chatsObj.chatIds
                    val results = java.util.Collections.synchronizedList(mutableListOf<Map<String, Any>>())
                    val remaining = java.util.concurrent.atomic.AtomicInteger(chatIds.size)

                    if (chatIds.isEmpty()) {
                        mainHandler.post { onResult(results) }
                        return@send
                    }

                    for (chatId in chatIds) {
                        client?.send(TdApi.GetChat(chatId)) { chatObj ->
                            if (chatObj is TdApi.Chat) {
                                val chatType = chatObj.type
                                if (chatType is TdApi.ChatTypeSupergroup) {
                                    // Check admin rights via GetSupergroup
                                    client?.send(TdApi.GetSupergroup(chatType.supergroupId)) { sgObj ->
                                        if (sgObj is TdApi.Supergroup) {
                                            val status = sgObj.status
                                            val canPost = when (status) {
                                                is TdApi.ChatMemberStatusCreator -> true
                                                is TdApi.ChatMemberStatusAdministrator -> status.rights.canPostMessages
                                                else -> false
                                            }
                                            if (canPost) {
                                                results.add(mapOf(
                                                    "id" to chatObj.id,
                                                    "title" to chatObj.title,
                                                    "isChannel" to chatType.isChannel,
                                                    "type" to if (chatType.isChannel) "channel" else "supergroup"
                                                ))
                                            }
                                        }
                                        if (remaining.decrementAndGet() <= 0) {
                                            mainHandler.post { onResult(results) }
                                        }
                                    }
                                } else {
                                    // Not a supergroup/channel — skip
                                    if (remaining.decrementAndGet() <= 0) {
                                        mainHandler.post { onResult(results) }
                                    }
                                }
                            } else {
                                if (remaining.decrementAndGet() <= 0) {
                                    mainHandler.post { onResult(results) }
                                }
                            }
                        }
                    }
                } else if (chatsObj is TdApi.Error) {
                    mainHandler.post { onErr(chatsObj.message) }
                }
            }
        }
    }

    /**
     * Fetch messages with file attachments from a given chat.
     * Paginates from newest to oldest to collect up to `limit` file messages.
     */
    fun getChatHistory(chatId: Long, limit: Int, onResult: (List<Map<String, Any>>) -> Unit, onErr: (String) -> Unit) {
        val allFiles = mutableListOf<Map<String, Any>>()
        fetchHistoryBatch(chatId, 0L, limit, allFiles, onResult, onErr)
    }

    private fun fetchHistoryBatch(
        chatId: Long,
        fromMessageId: Long,
        remaining: Int,
        collected: MutableList<Map<String, Any>>,
        onResult: (List<Map<String, Any>>) -> Unit,
        onErr: (String) -> Unit
    ) {
        val batchSize = minOf(remaining, 50)
        client?.send(TdApi.GetChatHistory(chatId, fromMessageId, 0, batchSize, false)) { obj ->
            if (obj is TdApi.Messages) {
                if (obj.messages.isEmpty()) {
                    mainHandler.post { onResult(collected) }
                    return@send
                }

                val files = obj.messages.mapNotNull { msg -> extractFileInfo(msg) }
                collected.addAll(files)

                val left = remaining - obj.messages.size
                if (left <= 0 || obj.messages.size < batchSize) {
                    mainHandler.post { onResult(collected) }
                } else {
                    val lastMsgId = obj.messages.last().id
                    fetchHistoryBatch(chatId, lastMsgId, left, collected, onResult, onErr)
                }
            } else if (obj is TdApi.Error) {
                mainHandler.post { onErr(obj.message) }
            }
        }
    }

    /**
     * Clear TDLib file cache.
     */
    fun optimizeStorage(onResult: () -> Unit, onErr: (String) -> Unit) {
        val req = TdApi.OptimizeStorage()
        client?.send(req) { obj ->
            if (obj is TdApi.Ok) {
                mainHandler.post { onResult() }
            } else if (obj is TdApi.Error) {
                mainHandler.post { onErr(obj.message) }
            } else {
                mainHandler.post { onResult() } // some versions return StorageStatistics
            }
        }
    }

    /**
     * Download a file.
     */
    fun downloadFile(fileId: Int, priority: Int, synchronous: Boolean, onResult: (Map<String, Any>) -> Unit, onErr: (String) -> Unit) {
        client?.send(TdApi.DownloadFile(fileId, priority, 0, 0, synchronous)) { obj ->
            if (obj is TdApi.File) {
                mainHandler.post { onResult(mapFile(obj)) }
            } else if (obj is TdApi.Error) {
                mainHandler.post { onErr(obj.message) }
            }
        }
    }

    private fun resolveContentUriToFile(contentUriString: String): String {
        try {
            val uri = Uri.parse(contentUriString)
            val contentResolver = context.contentResolver

            // Try to get original filename
            var fileName = "shared_file_${System.currentTimeMillis()}"
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1 && cursor.moveToFirst()) {
                    val displayName = cursor.getString(nameIndex)
                    if (!displayName.isNullOrBlank()) {
                        fileName = displayName
                    }
                }
            }

            // Create cache file in context.cacheDir/shared_files
            val cacheDir = File(context.cacheDir, "shared_files")
            if (!cacheDir.exists()) {
                cacheDir.mkdirs()
            }
            val targetFile = File(cacheDir, fileName)

            contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }

            return targetFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Error resolving content URI: $contentUriString", e)
            return contentUriString // Fallback to original
        }
    }

    /**
     * Upload a file to a chat using SendMessage + InputMessageDocument.
     */
    fun uploadFile(
        chatId: Long,
        filePath: String,
        onResult: (Map<String, Any>) -> Unit,
        onErr: (String) -> Unit
    ) {
        var resolvedPath = filePath
        if (resolvedPath.startsWith("file://")) {
            resolvedPath = resolvedPath.substring(7)
        }
        if (resolvedPath.startsWith("content://")) {
            resolvedPath = resolveContentUriToFile(resolvedPath)
        }

        // Native defensive check: if resolved file size is > 2.0 GB, return a clear error
        val localFile = File(resolvedPath)
        if (localFile.exists() && localFile.length() > 2L * 1024L * 1024L * 1024L) {
            mainHandler.post { onErr("File size exceeds the 2.0 GB Telegram limit.") }
            return
        }

        val inputFile = TdApi.InputFileLocal(resolvedPath)
        val content = TdApi.InputMessageDocument(inputFile, null, false, null)
        val sendMsg = TdApi.SendMessage().apply {
            this.chatId = chatId
            this.inputMessageContent = content
        }

        client?.send(sendMsg) { obj ->
            if (obj is TdApi.Message) {
                val fileInfo = extractFileInfo(obj)
                if (fileInfo != null) {
                    mainHandler.post { onResult(fileInfo) }
                } else {
                    mainHandler.post { onResult(mapOf("messageId" to obj.id.toString(), "chatId" to obj.chatId.toString())) }
                }
            } else if (obj is TdApi.Error) {
                mainHandler.post { onErr(obj.message) }
            }
        }
    }

    /**
     * Delete multiple messages from a chat.
     */
    fun deleteMessages(chatId: Long, messageIds: LongArray, revoke: Boolean, onResult: () -> Unit, onErr: (String) -> Unit) {
        Log.d(TAG, "deleteMessages called: chatId=$chatId messageIds=${messageIds.toList()} revoke=$revoke")
        if (messageIds.isEmpty()) {
            Log.w(TAG, "deleteMessages: messageIds is empty, skipping")
            mainHandler.post { onErr("messageIds is empty") }
            return
        }
        val request = TdApi.DeleteMessages(chatId, messageIds, revoke)
        client?.send(request) { obj ->
            Log.d(TAG, "deleteMessages result: ${obj.javaClass.simpleName}")
            if (obj is TdApi.Ok) {
                mainHandler.post { onResult() }
            } else if (obj is TdApi.Error) {
                Log.e(TAG, "deleteMessages TDLib error: code=${obj.code} message=${obj.message}")
                mainHandler.post { onErr("${obj.code}: ${obj.message}") }
            } else {
                mainHandler.post { onResult() }
            }
        } ?: run {
            Log.e(TAG, "deleteMessages: client is null")
            mainHandler.post { onErr("TDLib client is null") }
        }
    }

    /**
     * Create a private channel (no members, just the creator).
     * Returns the new chat info (id, title).
     */
    fun createPrivateChannel(
        title: String,
        onResult: (Map<String, Any>) -> Unit,
        onErr: (String) -> Unit
    ) {
        val req = TdApi.CreateNewSupergroupChat(
            title,     // title
            false,     // isForum
            true,      // isChannel — this makes it a channel, not a group
            "TeleDrive folder", // description
            null,      // location
            0,         // messageAutoDeleteTime
            false      // forImport
        )

        client?.send(req) { obj ->
            if (obj is TdApi.Chat) {
                mainHandler.post {
                    onResult(mapOf(
                        "id" to obj.id,
                        "title" to obj.title
                    ))
                }
            } else if (obj is TdApi.Error) {
                mainHandler.post { onErr(obj.message) }
            }
        }
    }

    private fun extractFileInfo(msg: TdApi.Message): Map<String, Any>? {
        val content = msg.content
        var file: TdApi.File? = null
        var fileName = ""
        var type = "other"

        when (content) {
            is TdApi.MessageDocument -> {
                file = content.document.document
                fileName = content.document.fileName
                type = "document"
                if (fileName.endsWith(".pdf", true)) type = "pdf"
                if (fileName.endsWith(".zip", true) || fileName.endsWith(".rar", true)) type = "archive"
            }
            is TdApi.MessagePhoto -> {
                file = content.photo.sizes.lastOrNull()?.photo
                fileName = "photo_${msg.id}.jpg"
                type = "image"
            }
            is TdApi.MessageVideo -> {
                file = content.video.video
                fileName = content.video.fileName
                type = "video"
            }
            is TdApi.MessageAudio -> {
                file = content.audio.audio
                fileName = content.audio.fileName
                type = "audio"
            }
        }

        if (file == null) return null

        return mapOf(
            "messageId" to msg.id.toString(),
            "chatId" to msg.chatId.toString(),
            "date" to msg.date,
            "fileId" to file.id,
            "fileName" to fileName,
            "type" to type,
            "size" to file.size,
            "localPath" to file.local.path,
            "isDownloadingActive" to file.local.isDownloadingActive,
            "isDownloadingCompleted" to file.local.isDownloadingCompleted,
            "downloadedPrefixSize" to file.local.downloadedPrefixSize
        )
    }

    private fun mapFile(file: TdApi.File): Map<String, Any> {
        return mapOf(
            "fileId" to file.id,
            "size" to file.size,
            "localPath" to file.local.path,
            "isDownloadingActive" to file.local.isDownloadingActive,
            "isDownloadingCompleted" to file.local.isDownloadingCompleted,
            "downloadedPrefixSize" to file.local.downloadedPrefixSize
        )
    }


    // ---------- Update / result handlers ----------

    private fun handleUpdate(obj: TdApi.Object) {
        when (obj) {
            is TdApi.UpdateAuthorizationState -> handleAuthState(obj.authorizationState)
            is TdApi.UpdateFile -> handleFileUpdate(obj.file)
            else -> Unit
        }
    }
    
    // Callbacks for file downloads
    var onFileUpdate: ((Map<String, Any>) -> Unit)? = null

    private fun handleFileUpdate(file: TdApi.File) {
        mainHandler.post {
            onFileUpdate?.invoke(mapFile(file))
        }
    }

    private fun handleAuthState(state: TdApi.AuthorizationState) {
        Log.d(TAG, "Auth state: ${state.javaClass.simpleName}")
        when (state) {
            is TdApi.AuthorizationStateWaitTdlibParameters -> sendTdlibParameters()
            is TdApi.AuthorizationStateWaitPhoneNumber     -> notifyState("authorizationStateWaitPhoneNumber")
            is TdApi.AuthorizationStateWaitCode            -> notifyState("authorizationStateWaitCode")
            is TdApi.AuthorizationStateWaitPassword        -> notifyState("authorizationStateWaitPassword")
            is TdApi.AuthorizationStateWaitRegistration    -> {
                Log.d(TAG, "Auth state: WaitRegistration")
                mainHandler.post { onError?.invoke("REGISTRATION_REQUIRED: An active Telegram account is required to proceed.") }
            }
            is TdApi.AuthorizationStateReady               -> notifyState("authorizationStateReady")
            is TdApi.AuthorizationStateLoggingOut          -> notifyState("authorizationStateLoggingOut")
            is TdApi.AuthorizationStateClosed              -> {
                // Release the close latch so initialize() can proceed with creating a new client
                closeLatchRef?.countDown()
                notifyState("authorizationStateClosed")
            }
            else -> Log.d(TAG, "Unhandled auth state: ${state.javaClass.simpleName}")
        }
    }

    private fun handleResult(obj: TdApi.Object) {
        if (obj is TdApi.Error) {
            val msg = "${obj.message} (code: ${obj.code})"
            Log.e(TAG, "TDLib error: $msg")
            mainHandler.post { onError?.invoke(msg) }
        }
    }

    private fun notifyState(state: String) {
        mainHandler.post { onAuthState?.invoke(state) }
    }

    // ---------- TDLib parameters ----------

    private fun sendTdlibParameters() {
        val dbPath = context.filesDir.absolutePath + "/tdlib"

        // SetTdlibParameters is a flat class with public fields (TDLib 1.8.x+)
        val params = TdApi.SetTdlibParameters().apply {
            apiId                = this@TeleManager.apiId
            apiHash              = this@TeleManager.apiHash
            databaseDirectory    = dbPath
            filesDirectory       = "$dbPath/files"
            databaseEncryptionKey = ByteArray(0)
            useTestDc            = false
            useFileDatabase      = true
            useChatInfoDatabase  = true
            useMessageDatabase   = true
            useSecretChats       = false
            systemLanguageCode   = "en"
            deviceModel          = Build.MODEL
            systemVersion        = Build.VERSION.RELEASE
            applicationVersion   = "1.0"
        }

        client?.send(params, ::handleResult)
    }
}
