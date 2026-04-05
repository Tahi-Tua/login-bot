.class public Lcom/example/auth/OverlayActivity$1;
.super Ljava/lang/Object;
.implements Landroid/view/View$OnClickListener;

.field final synthetic this$0:Lcom/example/auth/OverlayActivity;

.method public constructor <init>(Lcom/example/auth/OverlayActivity;)V
    .registers 2

    iput-object p1, p0, Lcom/example/auth/OverlayActivity$1;->this$0:Lcom/example/auth/OverlayActivity;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public onClick(Landroid/view/View;)V
    .registers 3

    iget-object v0, p0, Lcom/example/auth/OverlayActivity$1;->this$0:Lcom/example/auth/OverlayActivity;

    invoke-virtual {v0}, Lcom/example/auth/OverlayActivity;->onValidateClicked()V

    return-void
.end method
