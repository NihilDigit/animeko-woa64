#include <jni.h>
#include <sqlite3.h>

#include <string>

static void throw_sqlite(JNIEnv* env, sqlite3* db, int code, const char* fallback) {
    std::string message = fallback ? fallback : "SQLite error";
    if (db) {
        const char* sqlite_message = sqlite3_errmsg(db);
        if (sqlite_message) {
            message = sqlite_message;
        }
    }

    jclass cls = env->FindClass("androidx/sqlite/SQLiteException");
    if (!cls) {
        env->ExceptionClear();
        cls = env->FindClass("java/lang/RuntimeException");
    }
    env->ThrowNew(cls, message.c_str());
}

static sqlite3* as_db(jlong ptr) {
    return reinterpret_cast<sqlite3*>(ptr);
}

static sqlite3_stmt* as_stmt(jlong ptr) {
    return reinterpret_cast<sqlite3_stmt*>(ptr);
}

static void check_stmt_result(JNIEnv* env, sqlite3_stmt* stmt, int rc, const char* fallback) {
    if (rc != SQLITE_OK) {
        throw_sqlite(env, stmt ? sqlite3_db_handle(stmt) : nullptr, rc, fallback);
    }
}

extern "C" JNIEXPORT jint JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteDriverKt_nativeThreadSafeMode(JNIEnv*, jclass) {
    return sqlite3_threadsafe();
}

extern "C" JNIEXPORT jlong JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteDriverKt_nativeOpen(JNIEnv* env, jclass, jstring fileName, jint flags) {
    const char* path = env->GetStringUTFChars(fileName, nullptr);
    sqlite3* db = nullptr;
    int rc = sqlite3_open_v2(path, &db, flags, nullptr);
    env->ReleaseStringUTFChars(fileName, path);
    if (rc != SQLITE_OK) {
        throw_sqlite(env, db, rc, "Unable to open database");
        if (db) {
            sqlite3_close_v2(db);
        }
        return 0;
    }
    return reinterpret_cast<jlong>(db);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteConnectionKt_nativeInTransaction(JNIEnv*, jclass, jlong connection) {
    return sqlite3_get_autocommit(as_db(connection)) ? JNI_FALSE : JNI_TRUE;
}

extern "C" JNIEXPORT jlong JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteConnectionKt_nativePrepare(JNIEnv* env, jclass, jlong connection, jstring sql) {
    sqlite3* db = as_db(connection);
    const char* sql_text = env->GetStringUTFChars(sql, nullptr);
    sqlite3_stmt* stmt = nullptr;
    int rc = sqlite3_prepare_v2(db, sql_text, -1, &stmt, nullptr);
    env->ReleaseStringUTFChars(sql, sql_text);
    if (rc != SQLITE_OK) {
        throw_sqlite(env, db, rc, "Unable to prepare statement");
        return 0;
    }
    return reinterpret_cast<jlong>(stmt);
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteConnectionKt_nativeLoadExtension(
    JNIEnv* env,
    jclass,
    jlong connection,
    jstring fileName,
    jstring entryPoint
) {
    sqlite3* db = as_db(connection);
    const char* file_name = env->GetStringUTFChars(fileName, nullptr);
    const char* entry_point = entryPoint ? env->GetStringUTFChars(entryPoint, nullptr) : nullptr;
    char* error = nullptr;
    sqlite3_enable_load_extension(db, 1);
    int rc = sqlite3_load_extension(db, file_name, entry_point, &error);
    if (entryPoint) {
        env->ReleaseStringUTFChars(entryPoint, entry_point);
    }
    env->ReleaseStringUTFChars(fileName, file_name);
    if (rc != SQLITE_OK) {
        std::string message = error ? error : "Unable to load SQLite extension";
        sqlite3_free(error);
        jclass cls = env->FindClass("androidx/sqlite/SQLiteException");
        env->ThrowNew(cls, message.c_str());
    }
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteConnectionKt_nativeClose(JNIEnv*, jclass, jlong connection) {
    sqlite3_close_v2(as_db(connection));
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeBindBlob(JNIEnv* env, jclass, jlong statement, jint index, jbyteArray value) {
    sqlite3_stmt* stmt = as_stmt(statement);
    jsize len = env->GetArrayLength(value);
    jbyte* bytes = env->GetByteArrayElements(value, nullptr);
    int rc = sqlite3_bind_blob(stmt, index, bytes, len, SQLITE_TRANSIENT);
    env->ReleaseByteArrayElements(value, bytes, JNI_ABORT);
    check_stmt_result(env, stmt, rc, "Unable to bind blob");
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeBindDouble(JNIEnv* env, jclass, jlong statement, jint index, jdouble value) {
    sqlite3_stmt* stmt = as_stmt(statement);
    check_stmt_result(env, stmt, sqlite3_bind_double(stmt, index, value), "Unable to bind double");
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeBindLong(JNIEnv* env, jclass, jlong statement, jint index, jlong value) {
    sqlite3_stmt* stmt = as_stmt(statement);
    check_stmt_result(env, stmt, sqlite3_bind_int64(stmt, index, value), "Unable to bind long");
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeBindText(JNIEnv* env, jclass, jlong statement, jint index, jstring value) {
    sqlite3_stmt* stmt = as_stmt(statement);
    const char* text = env->GetStringUTFChars(value, nullptr);
    int rc = sqlite3_bind_text(stmt, index, text, -1, SQLITE_TRANSIENT);
    env->ReleaseStringUTFChars(value, text);
    check_stmt_result(env, stmt, rc, "Unable to bind text");
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeBindNull(JNIEnv* env, jclass, jlong statement, jint index) {
    sqlite3_stmt* stmt = as_stmt(statement);
    check_stmt_result(env, stmt, sqlite3_bind_null(stmt, index), "Unable to bind null");
}

extern "C" JNIEXPORT jboolean JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeStep(JNIEnv* env, jclass, jlong statement) {
    sqlite3_stmt* stmt = as_stmt(statement);
    int rc = sqlite3_step(stmt);
    if (rc == SQLITE_ROW) return JNI_TRUE;
    if (rc == SQLITE_DONE) return JNI_FALSE;
    throw_sqlite(env, sqlite3_db_handle(stmt), rc, "Unable to step statement");
    return JNI_FALSE;
}

extern "C" JNIEXPORT jbyteArray JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetBlob(JNIEnv* env, jclass, jlong statement, jint index) {
    sqlite3_stmt* stmt = as_stmt(statement);
    const void* blob = sqlite3_column_blob(stmt, index);
    int len = sqlite3_column_bytes(stmt, index);
    jbyteArray result = env->NewByteArray(len);
    if (len > 0 && blob) {
        env->SetByteArrayRegion(result, 0, len, reinterpret_cast<const jbyte*>(blob));
    }
    return result;
}

extern "C" JNIEXPORT jdouble JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetDouble(JNIEnv*, jclass, jlong statement, jint index) {
    return sqlite3_column_double(as_stmt(statement), index);
}

extern "C" JNIEXPORT jlong JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetLong(JNIEnv*, jclass, jlong statement, jint index) {
    return sqlite3_column_int64(as_stmt(statement), index);
}

extern "C" JNIEXPORT jstring JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetText(JNIEnv* env, jclass, jlong statement, jint index) {
    const unsigned char* text = sqlite3_column_text(as_stmt(statement), index);
    return text ? env->NewStringUTF(reinterpret_cast<const char*>(text)) : nullptr;
}

extern "C" JNIEXPORT jint JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetColumnCount(JNIEnv*, jclass, jlong statement) {
    return sqlite3_column_count(as_stmt(statement));
}

extern "C" JNIEXPORT jstring JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetColumnName(JNIEnv* env, jclass, jlong statement, jint index) {
    const char* name = sqlite3_column_name(as_stmt(statement), index);
    return name ? env->NewStringUTF(name) : nullptr;
}

extern "C" JNIEXPORT jint JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeGetColumnType(JNIEnv*, jclass, jlong statement, jint index) {
    return sqlite3_column_type(as_stmt(statement), index);
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeReset(JNIEnv* env, jclass, jlong statement) {
    sqlite3_stmt* stmt = as_stmt(statement);
    int rc = sqlite3_reset(stmt);
    check_stmt_result(env, stmt, rc, "Unable to reset statement");
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeClearBindings(JNIEnv* env, jclass, jlong statement) {
    sqlite3_stmt* stmt = as_stmt(statement);
    check_stmt_result(env, stmt, sqlite3_clear_bindings(stmt), "Unable to clear bindings");
}

extern "C" JNIEXPORT void JNICALL
Java_androidx_sqlite_driver_bundled_BundledSQLiteStatementKt_nativeClose(JNIEnv*, jclass, jlong statement) {
    sqlite3_finalize(as_stmt(statement));
}
