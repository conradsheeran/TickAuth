/*
 * Copyright (c) 2024 Yang He
 *
 * TickAuth is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import  { picker } from '@kit.CoreFileKit';
import { bufferToString, Logger, WriteToJson } from "utils";
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { Constants } from 'homepage/src/main/ets/common/Constants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';
import { promptAction } from '@kit.ArkUI';

const TAG: string = "ImportAndExport"
const logger = new Logger(getContext(this))

@Component
struct ImportAndExport {
  @LocalStorageLink("refresh") refresh: boolean = false;
  @Consume("pathStack") pathStack: NavPathStack;

  private context = getContext(this) as common.UIAbilityContext;
  private writeToJson = new WriteToJson(this.context.filesDir + Constants.SECRET_FILE_DIR)

  build() {
    NavDestination() {
      Column() {
        SymbolGlyph($r('sys.symbol.doc_text'))
          .fontSize($r('app.float.ImportAndExport_Symbol_size'))
          .margin({ top: Constants.IMPORTANDEXPORT_ITEM_MARGIN, bottom: $r('app.float.ImportAndExport_Symbol_margin') })

        Text() {
          Span($r('app.string.ImportAndExport_explanation_1'))
            .fontColor(Color.Gray)
          Span($r('app.string.ImportAndExport_explanation_2'))
            .fontColor($r('app.color.ImportAndExport_explanation_fontcolor'))
            .decoration({
              type: TextDecorationType.Underline,
              color: $r('app.color.ImportAndExport_explanation_fontcolor')
            })
            .onClick(() => {
              const documentSaveOptions = new picker.DocumentSaveOptions();
              documentSaveOptions.newFileNames = ["请选择一个文件夹保存示例文件.json"];
              documentSaveOptions.fileSuffixChoices = ['.json'];

              const documentViewPicker = new picker.DocumentViewPicker(this.context);
              documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
                fs.open(documentSaveResult[0], fs.OpenMode.READ_WRITE).then(async (file) => {
                  getContext(this).resourceManager.getRawFileContent("demo.json").then((content) => {
                    new WriteToJson(file.path).append(bufferToString(content))
                    fs.close(file.fd)
                  })
                })
              }).catch((e: BusinessError) => {
                promptAction.showToast({
                  message: `错误：${e.message} (${TAG})`,
                  duration: 2000
                });
                logger.error(Constants.DOMAIN, TAG, "documentViewPicker.save Fatal: %{public}s code: {public}d", e.message, e.code)
              })
            })
        }
        .margin({ top: $r('app.float.ImportAndExport_Explanation_margin') })
        .width(Constants.IMPORTANDEXPORT_ITEM_WIDTH)
        .fontSize($r('app.float.ImportAndExport_Explanation_fontsize'))

        Text("● 请确保一次性导入的密钥数少于 25 组，若大于 25 组，请分批导入")
          .fontColor(Color.Gray)
          .margin({ top: 8 })
          .width(Constants.IMPORTANDEXPORT_ITEM_WIDTH)
          .fontSize($r('app.float.ImportAndExport_Explanation_fontsize'))

        Row() {
          Button($r('app.string.ImportAndExport_Button_import'))
            .backgroundColor($r('app.color.ImportAndExport_Button_color'))
            .onClick(() => {
              let documentSelectOptions = new picker.DocumentSelectOptions();
              documentSelectOptions.maxSelectNumber = 1;
              documentSelectOptions.fileSuffixFilters = ["json"];

              let documentPicker = new picker.DocumentViewPicker(this.context);
              documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
                fs.open(documentSelectResult[0], fs.OpenMode.READ_ONLY).then((file) => {
                  let arrayBuffer = new ArrayBuffer(4096);
                  fs.read(file.fd, arrayBuffer).then((readLen) => {
                    let buf = buffer.from(arrayBuffer, 0, readLen);
                    this.writeToJson.append(bufferToString(new Uint8Array(buf.buffer)).replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim()).then(() => {
                      this.refresh = true;
                      fs.close(file.fd)
                      hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed")
                    })
                  }).catch((e: BusinessError) => {
                    promptAction.showToast({
                      message: `错误：${e.message} (${TAG})`,
                      duration: 2000
                    });
                    fs.close(file.fd)
                    logger.error(Constants.DOMAIN, TAG, "Read JSON file fatal: %{public}s", String(e))
                  })
                })
                hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed")
              }).catch((e: BusinessError) => {
                promptAction.showToast({
                  message: `错误：${e.message}(${TAG})`,
                  duration: 2000
                });
                logger.error(Constants.DOMAIN, TAG, "documentViewPicker.select Fatal: %{public}s code: {public}d", e.message, e.code)
              });
            })

          Blank()

          Button($r('app.string.ImportAndExport_Button_export'))
            .backgroundColor($r('app.color.ImportAndExport_Button_color'))
            .onClick(() => {
              const documentSaveOptions = new picker.DocumentSaveOptions();
              documentSaveOptions.newFileNames = ["secret.json"];
              documentSaveOptions.fileSuffixChoices = ['.json'];

              const documentViewPicker = new picker.DocumentViewPicker(this.context);
              documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
                fs.open(documentSaveResult[0], fs.OpenMode.READ_WRITE).then((file) => {
                  fs.copyFile(this.context.filesDir + Constants.SECRET_FILE_DIR, file.fd).then(() => {
                    fs.close(file.fd)
                    hilog.debug(Constants.DOMAIN, TAG, "copyFile: Export Succeed")
                  }).catch((e: BusinessError) => {
                    promptAction.showToast({
                      message: `错误：${e.message} (${TAG})`,
                      duration: 2000
                    });
                    fs.close(file.fd)
                    logger.error(Constants.DOMAIN, TAG, "copyFile Fatal: %{public}s code: {public}d", e.message, e.code)
                  });
                })
              }).catch((e: BusinessError) => {
                promptAction.showToast({
                  message: `错误：${e.message} (${TAG})`,
                  duration: 2000
                });
                logger.error(Constants.DOMAIN, TAG, "documentViewPicker.save Fatal: %{public}s code: {public}d", e.message, e.code)
              })
            })
        }
        .margin({ top: Constants.IMPORTANDEXPORT_ITEM_MARGIN })
        .width(Constants.IMPORTANDEXPORT_ITEM_WIDTH)

        Button("导出日志文件")
          .width(Constants.IMPORTANDEXPORT_ITEM_WIDTH)
          .margin({ top: 12 })
          .backgroundColor($r('app.color.ImportAndExport_Button_color'))
          .onClick(() => {
            const documentSaveOptions = new picker.DocumentSaveOptions();
            documentSaveOptions.newFileNames = ["log.txt"];

            const documentViewPicker = new picker.DocumentViewPicker(this.context);
            documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
              fs.open(documentSaveResult[0], fs.OpenMode.READ_WRITE).then((file) => {
                fs.copyFile(this.context.filesDir + "/log.txt", file.fd).then(() => {
                  fs.close(file.fd)
                  hilog.debug(Constants.DOMAIN, TAG, "copyFile: Export Succeed")
                }).catch((e: BusinessError) => {
                  promptAction.showToast({
                    message: `错误：${e.message} (${TAG})`,
                    duration: 2000
                  });
                  fs.close(file.fd)
                  logger.error(Constants.DOMAIN, TAG, "copyFile Fatal: %{public}s code: {public}d", e.message, e.code)
                });
              })
            }).catch((e: BusinessError) => {
              promptAction.showToast({
                message: `错误：${e.message} (${TAG})`,
                duration: 2000
              });
              logger.error(Constants.DOMAIN, TAG, "documentViewPicker.save Fatal: %{public}s code: {public}d", e.message, e.code)
            })
          })
      }
      .width(Constants.IMPORTANDEXPORT_SIZE)
      .height(Constants.IMPORTANDEXPORT_SIZE)
      .justifyContent(FlexAlign.Center)
    }
    .backgroundColor($r('app.color.background'))
    .title('导入和导出')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}

@Builder
export function ImportAndExportBuilder(name: string, param: Object) {
  ImportAndExport()
}