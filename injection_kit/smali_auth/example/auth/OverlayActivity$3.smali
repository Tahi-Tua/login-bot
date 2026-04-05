.class public Lcom/example/auth/OverlayActivity$3;
.super Ljava/lang/Object;
.implements Ljava/lang/Runnable;

.field final synthetic this$0:Lcom/example/auth/OverlayActivity;
.field final synthetic val$result:I

.method public constructor <init>(Lcom/example/auth/OverlayActivity;I)V
    .registers 3

    iput-object p1, p0, Lcom/example/auth/OverlayActivity$3;->this$0:Lcom/example/auth/OverlayActivity;

    iput p2, p0, Lcom/example/auth/OverlayActivity$3;->val$result:I

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public run()V
    .registers 3

    iget-object v0, p0, Lcom/example/auth/OverlayActivity$3;->this$0:Lcom/example/auth/OverlayActivity;

    iget v1, p0, Lcom/example/auth/OverlayActivity$3;->val$result:I

    invoke-virtual {v0, v1}, Lcom/example/auth/OverlayActivity;->onValidationResult(I)V

    return-void
.end method
