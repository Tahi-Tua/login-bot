.class public Lcom/example/auth/OverlayActivity;
.super Landroid/app/Activity;

.field private keyInput:Landroid/widget/EditText;
.field private statusView:Landroid/widget/TextView;

.method public constructor <init>()V
    .registers 1

    invoke-direct {p0}, Landroid/app/Activity;-><init>()V

    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .registers 3

    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    # Environment guard - if not safe, always show overlay
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z

    move-result v0

    if-eqz v0, :show_overlay

    invoke-static {p0}, Lcom/example/auth/SessionStore;->hasValidSession(Landroid/content/Context;)Z

    move-result v0

    if-eqz v0, :show_overlay

    invoke-virtual {p0}, Lcom/example/auth/OverlayActivity;->finish()V

    return-void

    :show_overlay
    invoke-direct {p0}, Lcom/example/auth/OverlayActivity;->buildUi()V

    return-void
.end method

.method private buildUi()V
    .registers 16
    # p0 = v15 = this

    # === Get display density for dp conversion ===
    invoke-virtual {p0}, Landroid/app/Activity;->getResources()Landroid/content/res/Resources;
    move-result-object v4
    invoke-virtual {v4}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v4
    iget v0, v4, Landroid/util/DisplayMetrics;->density:F

    # === ScrollView (handles keyboard) ===
    new-instance v1, Landroid/widget/ScrollView;
    invoke-direct {v1, p0}, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V
    const/4 v4, 0x1
    invoke-virtual {v1, v4}, Landroid/widget/ScrollView;->setFillViewport(Z)V
    const-string v4, "#0B1220"
    invoke-static {v4}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v4
    invoke-virtual {v1, v4}, Landroid/widget/ScrollView;->setBackgroundColor(I)V

    # === Root layout (centers card vertically) ===
    new-instance v2, Landroid/widget/LinearLayout;
    invoke-direct {v2, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v4, 0x1
    invoke-virtual {v2, v4}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/16 v4, 0x11
    invoke-virtual {v2, v4}, Landroid/widget/LinearLayout;->setGravity(I)V
    const/high16 v4, 0x41C00000
    mul-float v4, v4, v0
    float-to-int v4, v4
    invoke-virtual {v2, v4, v4, v4, v4}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    # === Card container with rounded background ===
    new-instance v3, Landroid/widget/LinearLayout;
    invoke-direct {v3, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v4, 0x1
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/4 v4, 0x1
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->setGravity(I)V
    const/high16 v4, 0x41E00000
    mul-float v4, v4, v0
    float-to-int v4, v4
    const/high16 v5, 0x42100000
    mul-float v5, v5, v0
    float-to-int v5, v5
    invoke-virtual {v3, v4, v5, v4, v5}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    new-instance v4, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v4}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    const-string v5, "#111B2E"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    const/high16 v5, 0x41A00000
    mul-float v5, v5, v0
    invoke-virtual {v4, v5}, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
    const/high16 v5, 0x3F800000
    mul-float v5, v5, v0
    float-to-int v5, v5
    const-string v6, "#1E293B"
    invoke-static {v6}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v6
    invoke-virtual {v4, v5, v6}, Landroid/graphics/drawable/GradientDrawable;->setStroke(II)V
    invoke-virtual {v3, v4}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V

    # ====== Title "Secure Login" ======
    new-instance v4, Landroid/widget/TextView;
    invoke-direct {v4, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v5, "Secure Login"
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const-string v5, "#F8FAFC"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTextColor(I)V
    const/high16 v5, 0x41C00000
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v5, Landroid/graphics/Typeface;->DEFAULT_BOLD:Landroid/graphics/Typeface;
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
    const/16 v5, 0x11
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setGravity(I)V
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x2
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/high16 v6, 0x41400000
    mul-float v6, v6, v0
    float-to-int v6, v6
    const/4 v7, 0x0
    invoke-virtual {v5, v7, v7, v7, v6}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v3, v4, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    # ====== Blue accent line ======
    new-instance v4, Landroid/view/View;
    invoke-direct {v4, p0}, Landroid/view/View;-><init>(Landroid/content/Context;)V
    const-string v5, "#3B82F6"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/view/View;->setBackgroundColor(I)V
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/high16 v7, 0x40000000
    mul-float v7, v7, v0
    float-to-int v7, v7
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/high16 v6, 0x41800000
    mul-float v6, v6, v0
    float-to-int v6, v6
    const/4 v7, 0x0
    invoke-virtual {v5, v7, v6, v7, v6}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v3, v4, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    # ====== Subtitle ======
    new-instance v4, Landroid/widget/TextView;
    invoke-direct {v4, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v5, "Enter your license key to continue"
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const-string v5, "#94A3B8"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTextColor(I)V
    const/high16 v5, 0x41600000
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTextSize(F)V
    const/16 v5, 0x11
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setGravity(I)V
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x2
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/high16 v6, 0x41E00000
    mul-float v6, v6, v0
    float-to-int v6, v6
    const/4 v7, 0x0
    invoke-virtual {v5, v7, v7, v7, v6}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v3, v4, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    # ====== EditText (key input) with rounded bg ======
    new-instance v4, Landroid/widget/EditText;
    invoke-direct {v4, p0}, Landroid/widget/EditText;-><init>(Landroid/content/Context;)V
    const-string v5, "GK-XXXXX-XXXXX"
    invoke-virtual {v4, v5}, Landroid/widget/EditText;->setHint(Ljava/lang/CharSequence;)V
    const-string v5, "#64748B"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/widget/EditText;->setHintTextColor(I)V
    const-string v5, "#F1F5F9"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/widget/EditText;->setTextColor(I)V
    const/high16 v5, 0x41700000
    invoke-virtual {v4, v5}, Landroid/widget/EditText;->setTextSize(F)V
    const/4 v5, 0x1
    invoke-virtual {v4, v5}, Landroid/widget/EditText;->setSingleLine(Z)V
    const/high16 v5, 0x41800000
    mul-float v5, v5, v0
    float-to-int v5, v5
    const/high16 v6, 0x41600000
    mul-float v6, v6, v0
    float-to-int v6, v6
    invoke-virtual {v4, v5, v6, v5, v6}, Landroid/widget/EditText;->setPadding(IIII)V
    new-instance v7, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v7}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    const-string v8, "#0F172A"
    invoke-static {v8}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v8
    invoke-virtual {v7, v8}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    const/high16 v8, 0x41400000
    mul-float v8, v8, v0
    invoke-virtual {v7, v8}, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
    const/high16 v8, 0x3F800000
    mul-float v8, v8, v0
    float-to-int v8, v8
    const-string v9, "#334155"
    invoke-static {v9}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v9
    invoke-virtual {v7, v8, v9}, Landroid/graphics/drawable/GradientDrawable;->setStroke(II)V
    invoke-virtual {v4, v7}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V
    iput-object v4, p0, Lcom/example/auth/OverlayActivity;->keyInput:Landroid/widget/EditText;
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x2
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/high16 v6, 0x41800000
    mul-float v6, v6, v0
    float-to-int v6, v6
    const/4 v7, 0x0
    invoke-virtual {v5, v7, v7, v7, v6}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v3, v4, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    # ====== Button with rounded blue bg ======
    new-instance v4, Landroid/widget/Button;
    invoke-direct {v4, p0}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
    const-string v5, "VERIFY KEY"
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V
    const-string v5, "#FFFFFF"
    invoke-static {v5}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v5
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setTextColor(I)V
    const/high16 v5, 0x41700000
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setTextSize(F)V
    sget-object v5, Landroid/graphics/Typeface;->DEFAULT_BOLD:Landroid/graphics/Typeface;
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setTypeface(Landroid/graphics/Typeface;)V
    const/4 v5, 0x0
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setAllCaps(Z)V
    const/4 v5, 0x0
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setMinHeight(I)V
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setMinimumHeight(I)V
    const/high16 v5, 0x41A00000
    mul-float v5, v5, v0
    float-to-int v5, v5
    const/high16 v6, 0x41600000
    mul-float v6, v6, v0
    float-to-int v6, v6
    invoke-virtual {v4, v5, v6, v5, v6}, Landroid/widget/Button;->setPadding(IIII)V
    new-instance v7, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v7}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    const-string v8, "#3B82F6"
    invoke-static {v8}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v8
    invoke-virtual {v7, v8}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    const/high16 v8, 0x41400000
    mul-float v8, v8, v0
    invoke-virtual {v7, v8}, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
    invoke-virtual {v4, v7}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V
    new-instance v5, Lcom/example/auth/OverlayActivity$1;
    invoke-direct {v5, p0}, Lcom/example/auth/OverlayActivity$1;-><init>(Lcom/example/auth/OverlayActivity;)V
    invoke-virtual {v4, v5}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x2
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/high16 v6, 0x41800000
    mul-float v6, v6, v0
    float-to-int v6, v6
    const/4 v7, 0x0
    invoke-virtual {v5, v7, v7, v7, v6}, Landroid/widget/LinearLayout$LayoutParams;->setMargins(IIII)V
    invoke-virtual {v3, v4, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    # ====== Status text ======
    new-instance v4, Landroid/widget/TextView;
    invoke-direct {v4, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v5, ""
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/high16 v5, 0x41500000
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setTextSize(F)V
    const/16 v5, 0x11
    invoke-virtual {v4, v5}, Landroid/widget/TextView;->setGravity(I)V
    iput-object v4, p0, Lcom/example/auth/OverlayActivity;->statusView:Landroid/widget/TextView;
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x2
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v3, v4, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    # ====== Assemble: card -> root -> scroll ======
    new-instance v5, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x2
    invoke-direct {v5, v6, v7}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v2, v3, v5}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    new-instance v5, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v6, -0x1
    const/4 v7, -0x1
    invoke-direct {v5, v6, v7}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V
    invoke-virtual {v1, v2, v5}, Landroid/widget/ScrollView;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    invoke-virtual {p0, v1}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V

    return-void
.end method

.method private setStatus(Ljava/lang/String;Ljava/lang/String;)V
    .registers 5

    iget-object v0, p0, Lcom/example/auth/OverlayActivity;->statusView:Landroid/widget/TextView;

    invoke-virtual {v0, p1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    invoke-static {p2}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I

    move-result v1

    iget-object v2, p0, Lcom/example/auth/OverlayActivity;->statusView:Landroid/widget/TextView;

    invoke-virtual {v2, v1}, Landroid/widget/TextView;->setTextColor(I)V

    return-void
.end method

.method public onValidateClicked()V
    .registers 8

    iget-object v0, p0, Lcom/example/auth/OverlayActivity;->keyInput:Landroid/widget/EditText;

    invoke-virtual {v0}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Object;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->length()I

    move-result v2

    if-nez v2, :validate

    const-string v3, "Please enter your key"

    const-string v4, "#FCA5A5"

    invoke-direct {p0, v3, v4}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    return-void

    :validate
    const-string v5, "Checking key..."

    const-string v6, "#93C5FD"

    invoke-direct {p0, v5, v6}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    invoke-direct {p0, v1}, Lcom/example/auth/OverlayActivity;->performValidationAsync(Ljava/lang/String;)V

    return-void

.end method

.method private performValidationAsync(Ljava/lang/String;)V
    .registers 5

    new-instance v0, Ljava/lang/Thread;

    new-instance v1, Lcom/example/auth/OverlayActivity$2;

    invoke-direct {v1, p0, p1}, Lcom/example/auth/OverlayActivity$2;-><init>(Lcom/example/auth/OverlayActivity;Ljava/lang/String;)V

    invoke-direct {v0, v1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;)V

    invoke-virtual {v0}, Ljava/lang/Thread;->start()V

    return-void
.end method

.method public onValidationResult(I)V
    .registers 7

    move v0, p1

    const/4 v1, 0x1

    if-ne v0, v1, :check_expired

    # Redundant environment check before granting access
    invoke-static {}, Lcom/example/auth/EnvironmentGuard;->isSafe()Z

    move-result v2

    if-nez v2, :grant_access

    const-string v3, "Security check failed"

    const-string v4, "#FCA5A5"

    invoke-direct {p0, v3, v4}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    return-void

    :grant_access
    const v2, 0x15180

    invoke-static {p0, v2}, Lcom/example/auth/SessionStore;->saveSession(Landroid/content/Context;I)V

    const-string v3, "Access granted"

    const-string v4, "#86EFAC"

    invoke-direct {p0, v3, v4}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {p0}, Lcom/example/auth/OverlayActivity;->finish()V

    return-void

    :check_expired
    const/4 v1, -0x1

    if-ne v0, v1, :check_invalid

    const-string v3, "Key expired. Request a new key."

    const-string v4, "#FCA5A5"

    invoke-direct {p0, v3, v4}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    return-void

    :check_invalid
    if-nez v0, :network_fail

    const-string v3, "Invalid key"

    const-string v4, "#FCA5A5"

    invoke-direct {p0, v3, v4}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    return-void

    :network_fail
    const-string v3, "Network error. Try again."

    const-string v4, "#FDE68A"

    invoke-direct {p0, v3, v4}, Lcom/example/auth/OverlayActivity;->setStatus(Ljava/lang/String;Ljava/lang/String;)V

    return-void
.end method
