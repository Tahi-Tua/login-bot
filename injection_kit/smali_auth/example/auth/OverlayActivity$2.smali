.class public Lcom/example/auth/OverlayActivity$2;
.super Ljava/lang/Object;
.implements Ljava/lang/Runnable;

.field final synthetic this$0:Lcom/example/auth/OverlayActivity;
.field final synthetic val$key:Ljava/lang/String;
.field final synthetic val$deviceId:Ljava/lang/String;

.method public constructor <init>(Lcom/example/auth/OverlayActivity;Ljava/lang/String;Ljava/lang/String;)V
    .registers 4

    iput-object p1, p0, Lcom/example/auth/OverlayActivity$2;->this$0:Lcom/example/auth/OverlayActivity;

    iput-object p2, p0, Lcom/example/auth/OverlayActivity$2;->val$key:Ljava/lang/String;

    iput-object p3, p0, Lcom/example/auth/OverlayActivity$2;->val$deviceId:Ljava/lang/String;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public run()V
    .registers 6

    iget-object v0, p0, Lcom/example/auth/OverlayActivity$2;->val$key:Ljava/lang/String;

    iget-object v1, p0, Lcom/example/auth/OverlayActivity$2;->val$deviceId:Ljava/lang/String;

    invoke-static {v0, v1}, Lcom/example/auth/KeyValidationManager;->activateDeviceBlocking(Ljava/lang/String;Ljava/lang/String;)I

    move-result v2

    new-instance v3, Lcom/example/auth/OverlayActivity$3;

    iget-object v4, p0, Lcom/example/auth/OverlayActivity$2;->this$0:Lcom/example/auth/OverlayActivity;

    invoke-direct {v3, v4, v2}, Lcom/example/auth/OverlayActivity$3;-><init>(Lcom/example/auth/OverlayActivity;I)V

    iget-object v4, p0, Lcom/example/auth/OverlayActivity$2;->this$0:Lcom/example/auth/OverlayActivity;

    invoke-virtual {v4, v3}, Lcom/example/auth/OverlayActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    return-void
.end method
