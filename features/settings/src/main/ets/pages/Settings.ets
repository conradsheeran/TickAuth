@Component
export struct Settings {
  @State message: string = '暂未开发设置界面';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(38)
          .fontWeight(FontWeight.Bold)
        Text("正在加快开发进度")
          .fontSize(38)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
  }
}
