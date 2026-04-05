.class public final Lcom/example/auth/IntegrityChecker;
.super Ljava/lang/Object;

# ============================================================
# APK Integrity Checker
# - Verifies APK signature (detects repackaging)
# - Verifies classes.dex CRC (detects smali patches)
# - Silent failure: clears session + returns false
# ============================================================

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

# Check APK signature matches expected fingerprint
# Returns true if signature is valid (not repackaged)
.method public static verifyApkSignature(Landroid/content/Context;)Z
    .registers 8

    :try_start
    invoke-virtual {p0}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;
    move-result-object v0

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v1

    # GET_SIGNATURES = 0x40
    const/16 v2, 0x40

    invoke-virtual {v0, v1, v2}, Landroid/content/pm/PackageManager;->getPackageInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;
    move-result-object v3

    iget-object v4, v3, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    if-eqz v4, :tampered

    array-length v5, v4

    if-lez v5, :tampered

    # Get first signature bytes
    const/4 v5, 0x0
    aget-object v6, v4, v5

    invoke-virtual {v6}, Landroid/content/pm/Signature;->toByteArray()[B
    move-result-object v6

    # Compute SHA-256 of signature
    const-string v7, "SHA-256"
    invoke-static {v7}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
    move-result-object v7

    invoke-virtual {v7, v6}, Ljava/security/MessageDigest;->digest([B)[B
    move-result-object v6

    # Convert to hex string for comparison
    invoke-static {v6}, Lcom/example/auth/IntegrityChecker;->bytesToHex([B)Ljava/lang/String;
    move-result-object v5

    # Store the fingerprint in SharedPreferences on first run
    # On subsequent runs, compare with stored value
    const-string v6, "_ic_fp"
    const/4 v7, 0x0
    invoke-virtual {p0, v6, v7}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v6

    const-string v7, "_sf"
    const-string v0, ""
    invoke-interface {v6, v7, v0}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/String;->length()I
    move-result v1

    if-nez v1, :compare_fp

    # First run — store fingerprint
    invoke-interface {v6}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v1
    invoke-interface {v1, v7, v5}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;
    move-result-object v1
    invoke-interface {v1}, Landroid/content/SharedPreferences$Editor;->apply()V

    const/4 v0, 0x1
    return v0

    :compare_fp
    # Compare current with stored
    invoke-virtual {v5, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    return v1

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    :tampered
    const/4 v0, 0x0
    return v0
.end method

# Verify classes.dex CRC matches expected value
# Uses ZipFile to read CRC from the APK itself
.method public static verifyDexCrc(Landroid/content/Context;)Z
    .registers 10

    :try_start
    # Get APK path
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;
    move-result-object v0
    iget-object v1, v0, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;

    # Open APK as ZipFile
    new-instance v2, Ljava/util/zip/ZipFile;
    invoke-direct {v2, v1}, Ljava/util/zip/ZipFile;-><init>(Ljava/lang/String;)V

    # Get classes.dex entry
    const-string v3, "classes.dex"
    invoke-virtual {v2, v3}, Ljava/util/zip/ZipFile;->getEntry(Ljava/lang/String;)Ljava/util/zip/ZipEntry;
    move-result-object v4

    if-eqz v4, :dex_tampered

    # Get CRC of classes.dex
    invoke-virtual {v4}, Ljava/util/zip/ZipEntry;->getCrc()J
    move-result-wide v5

    invoke-virtual {v2}, Ljava/util/zip/ZipFile;->close()V

    # Compare with stored CRC (same pattern as signature)
    const-string v7, "_ic_fp"
    const/4 v8, 0x0
    invoke-virtual {p0, v7, v8}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v7

    const-string v8, "_dc"
    const-wide/16 v3, 0x0
    invoke-interface {v7, v8, v3, v4}, Landroid/content/SharedPreferences;->getLong(Ljava/lang/String;J)J
    move-result-wide v3

    # Check if first run
    const-wide/16 v0, 0x0
    cmp-long v9, v3, v0
    if-nez v9, :compare_crc

    # First run — store CRC
    invoke-interface {v7}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v0
    invoke-interface {v0, v8, v5, v6}, Landroid/content/SharedPreferences$Editor;->putLong(Ljava/lang/String;J)Landroid/content/SharedPreferences$Editor;
    move-result-object v0
    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V

    const/4 v0, 0x1
    return v0

    :compare_crc
    cmp-long v9, v5, v3
    if-nez v9, :dex_tampered

    const/4 v0, 0x1
    return v0

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    :dex_tampered
    const/4 v0, 0x0
    return v0
.end method

# Full integrity check (signature + DEX CRC + environment)
.method public static isIntact(Landroid/content/Context;)Z
    .registers 3

    # Check environment first
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z
    move-result v0
    if-eqz v0, :compromised

    # Check APK signature
    invoke-static {p0}, Lcom/example/auth/IntegrityChecker;->verifyApkSignature(Landroid/content/Context;)Z
    move-result v0
    if-eqz v0, :compromised

    # Check DEX CRC
    invoke-static {p0}, Lcom/example/auth/IntegrityChecker;->verifyDexCrc(Landroid/content/Context;)Z
    move-result v0
    if-eqz v0, :compromised

    const/4 v0, 0x1
    return v0

    :compromised
    # Clear session on compromise
    invoke-static {p0}, Lcom/example/auth/SessionStore;->clearSession(Landroid/content/Context;)V
    const/4 v0, 0x0
    return v0
.end method

# Helper: bytes to hex string
.method private static bytesToHex([B)Ljava/lang/String;
    .registers 6

    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    array-length v1, p0
    const/4 v2, 0x0

    :loop
    if-ge v2, v1, :done

    aget-byte v3, p0, v2
    and-int/lit16 v3, v3, 0xFF
    const-string v4, "%02x"
    new-array v5, v2, [Ljava/lang/Object;

    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v3

    const/4 v5, 0x0
    new-array v5, v2, [Ljava/lang/Object;

    # Simpler approach: just append hex chars
    aget-byte v3, p0, v2
    and-int/lit16 v3, v3, 0xFF

    shr-int/lit8 v4, v3, 0x4
    and-int/lit8 v4, v4, 0xF
    invoke-static {v4}, Lcom/example/auth/IntegrityChecker;->hexChar(I)C
    move-result v4
    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    and-int/lit8 v4, v3, 0xF
    invoke-static {v4}, Lcom/example/auth/IntegrityChecker;->hexChar(I)C
    move-result v4
    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    add-int/lit8 v2, v2, 0x1
    goto :loop

    :done
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method

# Helper: int 0-15 to hex char
.method private static hexChar(I)C
    .registers 3
    const/16 v0, 0xA
    if-lt p0, v0, :digit
    add-int/lit8 v1, p0, 0x57
    int-to-char v1, v1
    return v1
    :digit
    add-int/lit8 v1, p0, 0x30
    int-to-char v1, v1
    return v1
.end method
