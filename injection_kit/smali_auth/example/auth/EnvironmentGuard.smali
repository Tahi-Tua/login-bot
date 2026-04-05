.class public final Lcom/example/auth/EnvironmentGuard;
.super Ljava/lang/Object;

# ============================================================
# Anti-tamper environment checks
# Detects: root, Frida, Xposed, debugger
# ============================================================

.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

# Returns true if environment is safe (no hooks detected)
.method public static isSafe()Z
    .registers 1

    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isRooted()Z

    move-result v0

    if-nez v0, :unsafe

    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isFridaDetected()Z

    move-result v0

    if-nez v0, :unsafe

    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isXposedPresent()Z

    move-result v0

    if-nez v0, :unsafe

    invoke-static {}, Landroid/os/Debug;->isDebuggerConnected()Z

    move-result v0

    if-nez v0, :unsafe

    const/4 v0, 0x1

    return v0

    :unsafe
    const/4 v0, 0x0

    return v0
.end method

# Check for root binaries (su, Magisk)
.method private static isRooted()Z
    .registers 3

    const-string v0, "/system/bin/su"

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :rooted

    const-string v0, "/system/xbin/su"

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :rooted

    const-string v0, "/sbin/su"

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :rooted

    const-string v0, "/data/local/bin/su"

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :rooted

    const-string v0, "/sbin/.magisk"

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :rooted

    const/4 v2, 0x0

    return v2

    :rooted
    const/4 v2, 0x1

    return v2
.end method

# Check /proc/self/maps for Frida injection
.method private static isFridaDetected()Z
    .registers 7

    :try_start

    # Build "frida" from fragments (anti-grep)
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "fri"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "da"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    # Build "gadget" from fragments
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "gad"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "get"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v4

    # Open /proc/self/maps
    const-string v0, "/proc/self/maps"

    new-instance v1, Ljava/io/FileReader;

    invoke-direct {v1, v0}, Ljava/io/FileReader;-><init>(Ljava/lang/String;)V

    new-instance v2, Ljava/io/BufferedReader;

    invoke-direct {v2, v1}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V

    :read_loop
    invoke-virtual {v2}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v5

    if-eqz v5, :not_found

    invoke-virtual {v5, v3}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v6

    if-nez v6, :found

    invoke-virtual {v5, v4}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v6

    if-nez v6, :found

    goto :read_loop

    :not_found
    invoke-virtual {v2}, Ljava/io/BufferedReader;->close()V

    const/4 v6, 0x0

    return v6

    :found
    invoke-virtual {v2}, Ljava/io/BufferedReader;->close()V

    const/4 v6, 0x1

    return v6

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    const/4 v6, 0x0

    return v6
.end method

# Check for Xposed framework via class loading
.method private static isXposedPresent()Z
    .registers 3

    :try_start

    # Build class name from fragments (anti-grep)
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "de.robv.android."

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "xposed.XposedBridge"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    # If we reach here, Xposed is loaded
    const/4 v2, 0x1

    return v2

    :try_end
    .catch Ljava/lang/ClassNotFoundException; {:try_start .. :try_end} :catch

    :catch
    const/4 v2, 0x0

    return v2
.end method
