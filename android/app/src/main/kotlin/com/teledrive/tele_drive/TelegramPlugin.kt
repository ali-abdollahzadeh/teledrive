package dev.aliabdollahzadeh.teledrive

import android.content.Context
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Flutter MethodChannel calls to TeleManager.
 *
 * Method channel:
 *   dev.aliabdollahzadeh.teledrive/telegram
 *
 * Event channel:
 *   dev.aliabdollahzadeh.teledrive/telegram_events
 *
 * Methods Flutter can call:
 *   initialize()                              → void
 *   sendPhoneNumber(phone: String)            → void
 *   checkCode(code: String)                   → void
 *   checkPassword(password: String)           → void
 *   logout()                                  → void
 *   getMe()                                   → Map
 *   getDriveFiles(chatId: Number, limit: Int) → List
 *   downloadFile(fileId: Int, ...)            → Map
 *   getMyChats(limit: Int)                    → List
 *   uploadFile(chatId: Number, filePath: String) → Map
 *   createFolder(title: String)               → Map
 *   optimizeStorage()                         → void
 *   deleteMessages(chatId: String, messageIds: List, revoke: Boolean) → void
 *
 * Auth events are pushed back via EventChannel:
 *   { "type": "authState", "state": "<tdlib state name>" }
 *   { "type": "error", "message": "..." }
 *   { "type": "fileUpdate", "file": {...} }
 */
class TelegramPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "dev.aliabdollahzadeh.teledrive/telegram"
        const val EVENT_CHANNEL = "dev.aliabdollahzadeh.teledrive/telegram_events"
    }

    private val manager = TeleManager(context)
    private var eventSink: EventChannel.EventSink? = null

    init {
        manager.onAuthState = { state ->
            eventSink?.success(
                mapOf(
                    "type" to "authState",
                    "state" to state
                )
            )
        }

        manager.onError = { message ->
            eventSink?.success(
                mapOf(
                    "type" to "error",
                    "message" to message
                )
            )
        }

        manager.onFileUpdate = { fileInfo ->
            eventSink?.success(
                mapOf(
                    "type" to "fileUpdate",
                    "file" to fileInfo
                )
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "initialize" -> {
                val apiId = BuildConfig.TELEGRAM_API_ID
                val apiHash = BuildConfig.TELEGRAM_API_HASH

                if (apiId <= 0 || apiHash.isBlank()) {
                    result.error(
                        "MISSING_API_CREDENTIALS",
                        "Telegram API credentials are missing. Check android/secrets.properties and build.gradle.kts.",
                        null
                    )
                    return
                }

                manager.initialize(apiId, apiHash)
                result.success(null)
            }

            "sendPhoneNumber" -> {
                try {
                    val phone = call.argument<String>("phone")?.trim() ?: ""

                    if (phone.isBlank()) {
                        result.error(
                            "INVALID_PHONE",
                            "Phone number is empty.",
                            null
                        )
                        return
                    }

                    manager.sendPhoneNumber(phone)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.message ?: "Error sending phone number", null)
                }
            }

            "checkCode" -> {
                try {
                    val code = call.argument<String>("code")?.trim() ?: ""

                    if (code.isBlank()) {
                        result.error(
                            "INVALID_CODE",
                            "Login code is empty.",
                            null
                        )
                        return
                    }

                    manager.checkCode(code)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.message ?: "Error checking code", null)
                }
            }

            "checkPassword" -> {
                try {
                    val password = call.argument<String>("password") ?: ""

                    if (password.isBlank()) {
                        result.error(
                            "INVALID_PASSWORD",
                            "Password is empty.",
                            null
                        )
                        return
                    }

                    manager.checkPassword(password)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.message ?: "Error checking password", null)
                }
            }
            "logout" -> {
                try {
                    manager.logout()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.message ?: "Error logging out", null)
                }
            }
            "getMe" -> {
                manager.getMe(
                    { user ->
                        result.success(user)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "getDriveFiles" -> {
                val chatId = call.argument<Number>("chatId")?.toLong() ?: 0L
                val limit = call.argument<Int>("limit") ?: 100

                if (chatId == 0L) {
                    result.error(
                        "INVALID_CHAT_ID",
                        "chatId is 0 or null.",
                        null
                    )
                    return
                }

                if (limit <= 0) {
                    result.error(
                        "INVALID_LIMIT",
                        "limit must be greater than 0.",
                        null
                    )
                    return
                }

                manager.getChatHistory(
                    chatId,
                    limit,
                    { files ->
                        result.success(files)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "downloadFile" -> {
                val fileId = call.argument<Int>("fileId") ?: 0
                val priority = call.argument<Int>("priority") ?: 1
                val synchronous = call.argument<Boolean>("synchronous") ?: false

                if (fileId <= 0) {
                    result.error(
                        "INVALID_FILE_ID",
                        "fileId is 0 or invalid.",
                        null
                    )
                    return
                }

                manager.downloadFile(
                    fileId,
                    priority,
                    synchronous,
                    { file ->
                        result.success(file)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "getMyChats" -> {
                val limit = call.argument<Int>("limit") ?: 50

                if (limit <= 0) {
                    result.error(
                        "INVALID_LIMIT",
                        "limit must be greater than 0.",
                        null
                    )
                    return
                }

                manager.getMyChats(
                    limit,
                    { chats ->
                        result.success(chats)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "uploadFile" -> {
                val chatId = call.argument<Number>("chatId")?.toLong() ?: 0L
                val filePath = call.argument<String>("filePath")?.trim() ?: ""

                if (chatId == 0L) {
                    result.error(
                        "INVALID_CHAT_ID",
                        "chatId is 0 or null.",
                        null
                    )
                    return
                }

                if (filePath.isBlank()) {
                    result.error(
                        "INVALID_FILE_PATH",
                        "filePath is empty.",
                        null
                    )
                    return
                }

                manager.uploadFile(
                    chatId,
                    filePath,
                    { file ->
                        result.success(file)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "createFolder" -> {
                val title = call.argument<String>("title")?.trim() ?: ""

                if (title.isBlank()) {
                    result.error(
                        "INVALID_TITLE",
                        "Folder title is empty.",
                        null
                    )
                    return
                }

                manager.createPrivateChannel(
                    title,
                    { chat ->
                        result.success(chat)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "optimizeStorage" -> {
                manager.optimizeStorage(
                    {
                        result.success(null)
                    },
                    { error ->
                        result.error("TDLIB_ERROR", error, null)
                    }
                )
            }
            "deleteMessages" -> {
                try {
                    val chatId = when (val value = call.argument<Any>("chatId")) {
                        is String -> value.toLongOrNull() ?: 0L
                        is Number -> value.toLong()
                        else -> 0L
                    }

                    if (chatId == 0L) {
                        result.error(
                            "INVALID_CHAT_ID",
                            "chatId is 0 or null.",
                            null
                        )
                        return
                    }

                    val rawMessageIds = call.argument<List<*>>("messageIds") ?: emptyList<Any>()

                    val messageIds = rawMessageIds.mapNotNull {
                        when (it) {
                            is String -> it.toLongOrNull()
                            is Number -> it.toLong()
                            else -> null
                        }
                    }.toLongArray()
                    if (messageIds.isEmpty()) {
                        result.error(
                            "EMPTY_ARRAY",
                            "messageIds is empty or could not be parsed.",
                            null
                        )
                        return
                    }
                    val revoke = call.argument<Boolean>("revoke") ?: true

                    manager.deleteMessages(
                        chatId,
                        messageIds,
                        revoke,
                        {
                            result.success(null)
                        },
                        { error ->
                            result.error("TDLIB_ERROR", error, null)
                        }
                    )

                } catch (e: Exception) {
                    result.error(
                        "EXCEPTION",
                        e.message ?: "Unknown error while deleting messages.",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }


    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}