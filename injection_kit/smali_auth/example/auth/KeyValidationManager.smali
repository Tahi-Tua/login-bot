.class public final Lcom/example/auth/KeyValidationManager;
.super Ljava/lang/Object;

# ============================================================
# Hardened key validation with:
# - Obfuscated strings (no plain URLs)
# - Nonce-based challenge-response
# - HMAC signature verification
# - Environment guard checks
# ============================================================

.field public static final STATUS_INVALID:I = 0x0
.field public static final STATUS_VALID:I = 0x1
.field public static final STATUS_EXPIRED:I = -0x1
.field public static final STATUS_ERROR:I = -0x2

.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

# Build API base URL from fragments (anti-grep)
.method private static getBaseUrl()Ljava/lang/String;
    .registers 3

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "ht"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "tps://"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "gk-auth"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "-api.onrender"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, ".com"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "/api/"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    return-object v2
.end method

# Build HMAC response key from fragments (anti-grep)
.method private static getResponseKey()Ljava/lang/String;
    .registers 3

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Xk9#"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "mW2$"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "pL7@"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "nQ4!"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    return-object v2
.end method

# Validate key format (GK-XXXX-YYYY, 16-128 chars, alphanumeric)
.method public static isKeyFormatValid(Ljava/lang/String;)Z
    .registers 3

    if-eqz p0, :invalid

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    const/16 v1, 0x10

    if-lt v0, v1, :invalid

    const/16 v1, 0x80

    if-gt v0, v1, :invalid

    const-string v1, "^[A-Za-z0-9_-]+$"

    invoke-virtual {p0, v1}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v0

    return v0

    :invalid
    const/4 v0, 0x0

    return v0
.end method

# Main validation entry point with nonce + HMAC
.method public static validateKeyBlocking(Ljava/lang/String;)I
    .registers 9

    # p0 = key

    # ---- Environment guard ----
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z

    move-result v0

    if-nez v0, :env_ok

    const/4 v0, -0x2

    return v0

    :env_ok
    # ---- Format check ----
    invoke-static {p0}, Lcom/example/auth/KeyValidationManager;->isKeyFormatValid(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :format_ok

    const/4 v0, 0x0

    return v0

    :format_ok
    :try_start

    # ---- Step 1: Fetch nonce ----
    invoke-static {}, Lcom/example/auth/KeyValidationManager;->getBaseUrl()Ljava/lang/String;

    move-result-object v1

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v3, "nonce"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v2}, Lcom/example/auth/KeyValidationManager;->httpGet(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    if-eqz v3, :error

    const-string v7, "nonce"

    invoke-static {v3, v7}, Lcom/example/auth/KeyValidationManager;->extractJsonValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    if-eqz v4, :error

    # ---- Step 2: Verify with nonce ----
    invoke-static {p0}, Landroid/net/Uri;->encode(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    invoke-static {}, Lcom/example/auth/KeyValidationManager;->getBaseUrl()Ljava/lang/String;

    move-result-object v1

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v3, "verify?key="

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v3, "&nonce="

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v2}, Lcom/example/auth/KeyValidationManager;->httpGet(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    if-eqz v3, :error

    # ---- Step 3: Parse response ----
    const-string v7, "status"

    invoke-static {v3, v7}, Lcom/example/auth/KeyValidationManager;->extractJsonValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    if-eqz v5, :error

    const-string v7, "sig"

    invoke-static {v3, v7}, Lcom/example/auth/KeyValidationManager;->extractJsonValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    if-eqz v6, :error

    # ---- Step 4: Verify HMAC signature ----
    invoke-static {v4, v5, v6}, Lcom/example/auth/KeyValidationManager;->verifySignature(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :sig_ok

    const/4 v0, -0x2

    return v0

    :sig_ok
    # ---- Step 5: Redundant environment check ----
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z

    move-result v0

    if-nez v0, :env_ok2

    const/4 v0, -0x2

    return v0

    :env_ok2
    # ---- Step 6: Parse status ----
    const-string v7, "valid"

    invoke-virtual {v5, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :check_expired

    const/4 v0, 0x1

    return v0

    :check_expired
    const-string v7, "expired"

    invoke-virtual {v5, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :is_invalid

    const/4 v0, -0x1

    return v0

    :is_invalid
    const/4 v0, 0x0

    return v0

    :error
    const/4 v0, -0x2

    return v0

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    const/4 v0, -0x2

    return v0
.end method

# HTTP GET helper - returns response body or null
.method private static httpGet(Ljava/lang/String;)Ljava/lang/String;
    .registers 8

    # p0 = url

    const/4 v0, 0x0

    :try_start

    new-instance v1, Ljava/net/URL;

    invoke-direct {v1, p0}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object v0

    check-cast v0, Ljava/net/HttpURLConnection;

    const-string v1, "GET"

    invoke-virtual {v0, v1}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V

    const/16 v1, 0x1388

    invoke-virtual {v0, v1}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    invoke-virtual {v0, v1}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v1

    const/16 v5, 0xc8

    if-eq v1, v5, :ok

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->disconnect()V

    const/4 v6, 0x0

    return-object v6

    :ok
    new-instance v3, Ljava/io/InputStreamReader;

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;

    move-result-object v5

    invoke-direct {v3, v5}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;)V

    new-instance v2, Ljava/io/BufferedReader;

    invoke-direct {v2, v3}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    :read_loop
    invoke-virtual {v2}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v5

    if-eqz v5, :read_done

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    goto :read_loop

    :read_done
    invoke-virtual {v2}, Ljava/io/BufferedReader;->close()V

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->disconnect()V

    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v6

    return-object v6

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    instance-of v6, v0, Ljava/net/HttpURLConnection;

    if-eqz v6, :null_conn

    check-cast v0, Ljava/net/HttpURLConnection;

    invoke-virtual {v0}, Ljava/net/HttpURLConnection;->disconnect()V

    :null_conn
    const/4 v6, 0x0

    return-object v6
.end method

# Extract a string value from JSON: {"field":"value"} -> value
.method private static extractJsonValue(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .registers 6

    # p0 = json, p1 = field name

    # Build search pattern: "\"field\":\""
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\""

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, "\":\""

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    # Find start of search pattern
    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v1

    const/4 v3, -0x1

    if-ne v1, v3, :found_start

    const/4 v0, 0x0

    return-object v0

    :found_start
    # Advance past pattern to get start of value
    invoke-virtual {v0}, Ljava/lang/String;->length()I

    move-result v2

    add-int/2addr v1, v2

    # Find closing quote
    const-string v2, "\""

    invoke-virtual {p0, v2, v1}, Ljava/lang/String;->indexOf(Ljava/lang/String;I)I

    move-result v2

    if-ne v2, v3, :found_end

    const/4 v0, 0x0

    return-object v0

    :found_end
    invoke-virtual {p0, v1, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v0

    return-object v0
.end method

# Verify HMAC-SHA256 signature from server
# sig = Base64(HMAC-SHA256(RESPONSE_KEY, nonce + ":" + status))
.method private static verifySignature(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Z
    .registers 12

    # p0 = nonce, p1 = status, p2 = expected sig (base64)

    :try_start

    # Get response key as bytes
    invoke-static {}, Lcom/example/auth/KeyValidationManager;->getResponseKey()Ljava/lang/String;

    move-result-object v0

    const-string v1, "UTF-8"

    invoke-virtual {v0, v1}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B

    move-result-object v0

    # Build message: nonce + ":" + status
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v2, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v3, ":"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    const-string v3, "UTF-8"

    invoke-virtual {v2, v3}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B

    move-result-object v2

    # Create HMAC-SHA256
    const-string v3, "HmacSHA256"

    new-instance v4, Ljavax/crypto/spec/SecretKeySpec;

    invoke-direct {v4, v0, v3}, Ljavax/crypto/spec/SecretKeySpec;-><init>([BLjava/lang/String;)V

    invoke-static {v3}, Ljavax/crypto/Mac;->getInstance(Ljava/lang/String;)Ljavax/crypto/Mac;

    move-result-object v5

    invoke-virtual {v5, v4}, Ljavax/crypto/Mac;->init(Ljava/security/Key;)V

    invoke-virtual {v5, v2}, Ljavax/crypto/Mac;->doFinal([B)[B

    move-result-object v6

    # Base64 encode computed HMAC (NO_WRAP = 2)
    const/4 v7, 0x2

    invoke-static {v6, v7}, Landroid/util/Base64;->encodeToString([BI)Ljava/lang/String;

    move-result-object v8

    # Compare with expected signature
    invoke-virtual {v8, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    return v7

    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch

    :catch
    const/4 v0, 0x0

    return v0
.end method
