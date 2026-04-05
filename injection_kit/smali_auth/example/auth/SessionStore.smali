.class public final Lcom/example/auth/SessionStore;
.super Ljava/lang/Object;

# ============================================================
# Encrypted session storage
# - XOR encryption with device-derived key
# - Integrity checksum to detect tampering
# - Obfuscated pref names
# ============================================================

.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

# Derive obfuscation key from package name
.method private static getObfKey(Landroid/content/Context;)J
    .registers 7

    # p0 = context (at register 6)

    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/String;->hashCode()I

    move-result v1

    int-to-long v2, v1

    const-wide v4, 0x5DEECE66DL

    mul-long/2addr v2, v4

    return-wide v2
.end method

# Check if a non-tampered, non-expired session exists
.method public static hasValidSession(Landroid/content/Context;)Z
    .registers 13

    # p0 = context (at register 12)

    # Get SharedPreferences (obfuscated name)
    const-string v0, "_sys_cfg"

    const/4 v1, 0x0

    invoke-virtual {p0, v0, v1}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v2

    # Read encrypted expiry
    const-string v3, "_c0"

    const-wide/16 v4, 0x0

    invoke-interface {v2, v3, v4, v5}, Landroid/content/SharedPreferences;->getLong(Ljava/lang/String;J)J

    move-result-wide v4

    # Read checksum
    const-string v3, "_c1"

    const-wide/16 v6, 0x0

    invoke-interface {v2, v3, v6, v7}, Landroid/content/SharedPreferences;->getLong(Ljava/lang/String;J)J

    move-result-wide v6

    # Check if empty
    const-wide/16 v8, 0x0

    cmp-long v0, v4, v8

    if-nez v0, :not_zero

    const/4 v0, 0x0

    return v0

    :not_zero
    # Verify integrity: expected = enc ^ 0x55AA55AA
    const-wide/32 v8, 0x55AA55AA

    xor-long v10, v4, v8

    cmp-long v0, v6, v10

    if-eqz v0, :integrity_ok

    # Tampered - clear everything
    invoke-static {p0}, Lcom/example/auth/SessionStore;->clearSession(Landroid/content/Context;)V

    const/4 v0, 0x0

    return v0

    :integrity_ok
    # Decrypt: expiry = enc ^ getObfKey(ctx)
    invoke-static {p0}, Lcom/example/auth/SessionStore;->getObfKey(Landroid/content/Context;)J

    move-result-wide v8

    xor-long v10, v4, v8

    # Compare with current time
    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    move-result-wide v8

    cmp-long v0, v10, v8

    if-lez v0, :expired

    const/4 v0, 0x1

    return v0

    :expired
    const/4 v0, 0x0

    return v0
.end method

# Save encrypted session with integrity checksum
.method public static saveSession(Landroid/content/Context;I)V
    .registers 12

    # p0 = context (at register 10), p1 = seconds (at register 11)

    # Calculate expiry timestamp
    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    move-result-wide v0

    int-to-long v2, p1

    const-wide/16 v4, 0x3E8

    mul-long/2addr v2, v4

    add-long/2addr v0, v2

    # v0/v1 = expiry in millis

    # Encrypt: enc = expiry ^ getObfKey(ctx)
    invoke-static {p0}, Lcom/example/auth/SessionStore;->getObfKey(Landroid/content/Context;)J

    move-result-wide v2

    xor-long v4, v0, v2

    # v4/v5 = encrypted expiry

    # Checksum: chk = enc ^ 0x55AA55AA
    const-wide/32 v6, 0x55AA55AA

    xor-long v6, v4, v6

    # v6/v7 = checksum

    # Save to SharedPreferences
    const-string v8, "_sys_cfg"

    const/4 v9, 0x0

    invoke-virtual {p0, v8, v9}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v8

    invoke-interface {v8}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v8

    const-string v9, "_c0"

    invoke-interface {v8, v9, v4, v5}, Landroid/content/SharedPreferences$Editor;->putLong(Ljava/lang/String;J)Landroid/content/SharedPreferences$Editor;

    move-result-object v8

    const-string v9, "_c1"

    invoke-interface {v8, v9, v6, v7}, Landroid/content/SharedPreferences$Editor;->putLong(Ljava/lang/String;J)Landroid/content/SharedPreferences$Editor;

    move-result-object v8

    invoke-interface {v8}, Landroid/content/SharedPreferences$Editor;->apply()V

    return-void
.end method

# Clear session data (including device_token)
.method public static clearSession(Landroid/content/Context;)V
    .registers 5

    # p0 = context (at register 4)

    const-string v0, "_sys_cfg"

    const/4 v1, 0x0

    invoke-virtual {p0, v0, v1}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v2

    invoke-interface {v2}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v3

    const-string v0, "_c0"

    invoke-interface {v3, v0}, Landroid/content/SharedPreferences$Editor;->remove(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object v3

    const-string v0, "_c1"

    invoke-interface {v3, v0}, Landroid/content/SharedPreferences$Editor;->remove(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object v3

    const-string v0, "_c2"

    invoke-interface {v3, v0}, Landroid/content/SharedPreferences$Editor;->remove(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object v3

    invoke-interface {v3}, Landroid/content/SharedPreferences$Editor;->apply()V

    return-void
.end method

# Save device_token (XOR encrypted with obfuscation key, Base64 encoded)
.method public static saveDeviceToken(Landroid/content/Context;Ljava/lang/String;)V
    .registers 10

    # p0 = context, p1 = deviceToken
    if-eqz p1, :done

    # Get obfuscation key
    invoke-static {p0}, Lcom/example/auth/SessionStore;->getObfKey(Landroid/content/Context;)J
    move-result-wide v0
    # v0/v1 = obfKey (long)

    # Convert token to bytes
    const-string v2, "UTF-8"
    invoke-virtual {p1, v2}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B
    move-result-object v3
    # v3 = token bytes

    # XOR encrypt each byte with key bytes (cycling through 8 bytes of long)
    array-length v4, v3
    const/4 v5, 0x0

    :xor_loop
    if-ge v5, v4, :xor_done

    # Get key byte: shift obfKey right by (i % 8) * 8, mask with 0xFF
    rem-int/lit8 v6, v5, 0x8
    mul-int/lit8 v6, v6, 0x8
    shr-long v7, v0, v6
    long-to-int v7, v7
    and-int/lit16 v7, v7, 0xFF

    # XOR with data byte
    aget-byte v8, v3, v5
    xor-int/2addr v8, v7
    int-to-byte v8, v8
    aput-byte v8, v3, v5

    add-int/lit8 v5, v5, 0x1
    goto :xor_loop

    :xor_done
    # Base64 encode (NO_WRAP = 2)
    const/4 v5, 0x2
    invoke-static {v3, v5}, Landroid/util/Base64;->encodeToString([BI)Ljava/lang/String;
    move-result-object v6

    # Store in SharedPreferences
    const-string v7, "_sys_cfg"
    const/4 v8, 0x0
    invoke-virtual {p0, v7, v8}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v7

    invoke-interface {v7}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v7

    const-string v8, "_c2"
    invoke-interface {v7, v8, v6}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;
    move-result-object v7

    invoke-interface {v7}, Landroid/content/SharedPreferences$Editor;->apply()V

    :done
    return-void
.end method

# Get device_token (decrypt from storage)
.method public static getDeviceToken(Landroid/content/Context;)Ljava/lang/String;
    .registers 10

    # p0 = context

    # Read from SharedPreferences
    const-string v0, "_sys_cfg"
    const/4 v1, 0x0
    invoke-virtual {p0, v0, v1}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v2

    const-string v3, "_c2"
    const/4 v4, 0x0
    invoke-interface {v2, v3, v4}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v5

    if-nez v5, :has_token
    const/4 v0, 0x0
    return-object v0

    :has_token
    :try_start
    # Base64 decode
    const/4 v6, 0x0
    invoke-static {v5, v6}, Landroid/util/Base64;->decode(Ljava/lang/String;I)[B
    move-result-object v3
    # v3 = encrypted bytes

    # Get obfuscation key
    invoke-static {p0}, Lcom/example/auth/SessionStore;->getObfKey(Landroid/content/Context;)J
    move-result-wide v0
    # v0/v1 = obfKey

    # XOR decrypt (same as encrypt)
    array-length v4, v3
    const/4 v5, 0x0

    :dec_loop
    if-ge v5, v4, :dec_done

    rem-int/lit8 v6, v5, 0x8
    mul-int/lit8 v6, v6, 0x8
    shr-long v7, v0, v6
    long-to-int v7, v7
    and-int/lit16 v7, v7, 0xFF

    aget-byte v8, v3, v5
    xor-int/2addr v8, v7
    int-to-byte v8, v8
    aput-byte v8, v3, v5

    add-int/lit8 v5, v5, 0x1
    goto :dec_loop

    :dec_done
    # Convert back to String
    new-instance v6, Ljava/lang/String;
    const-string v7, "UTF-8"
    invoke-direct {v6, v3, v7}, Ljava/lang/String;-><init>([BLjava/lang/String;)V
    return-object v6

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    const/4 v0, 0x0
    return-object v0
.end method
