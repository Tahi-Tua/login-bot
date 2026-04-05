.class public final Lcom/example/auth/AuthGate;
.super Ljava/lang/Object;

.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static shouldAllowAccess(Landroid/content/Context;)Z
    .registers 2

    # Environment guard
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z

    move-result v0

    if-nez v0, :env_ok

    const/4 v0, 0x0

    return v0

    :env_ok
    invoke-static {p0}, Lcom/example/auth/SessionStore;->hasValidSession(Landroid/content/Context;)Z

    move-result v0

    return v0
.end method

.method public static launchOverlayIfNeeded(Landroid/app/Activity;)Z
    .registers 5

    # Environment guard - if compromised, clear session and force overlay
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z

    move-result v0

    if-nez v0, :env_ok

    invoke-static {p0}, Lcom/example/auth/SessionStore;->clearSession(Landroid/content/Context;)V

    goto :launch

    :env_ok
    invoke-static {p0}, Lcom/example/auth/SessionStore;->hasValidSession(Landroid/content/Context;)Z

    move-result v0

    if-eqz v0, :launch

    const/4 v1, 0x0

    return v1

    :launch
    new-instance v1, Landroid/content/Intent;

    const-class v2, Lcom/example/auth/OverlayActivity;

    invoke-direct {v1, p0, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    invoke-virtual {p0, v1}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V

    const/4 v4, 0x1

    return v4
.end method
