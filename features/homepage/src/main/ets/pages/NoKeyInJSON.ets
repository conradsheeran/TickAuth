@Component
export struct NoKeyInJSON {
  @State message: string = '请点击右上角添加一个验证码吧';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
  }
}
