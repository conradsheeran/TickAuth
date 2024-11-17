import { Constants } from "../common/Constants";
@Entry
@Component
export struct NoKeyInJSON {
  @State message: string = '请点击右上角添加一个验证码吧';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize($r('app.float.NoKeyInJSON_fontsize'))
          .fontWeight(FontWeight.Bold)
      }
      .width(Constants.HOMEPAGE_SIZE)
    }
    .height(Constants.HOMEPAGE_SIZE)
  }
}
