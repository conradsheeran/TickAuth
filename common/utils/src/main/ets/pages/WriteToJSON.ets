import { fileIo as fs } from '@kit.CoreFileKit';
import { JSON } from "@kit.ArkTS"
import { Logger } from './Logger';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "WriteToJson";
const logger = new Logger(getContext(this))

interface SecretItem {
  alias: string;
  secret: string;
}

export async function WriteToJson(
  filePath: string,
  data: SecretItem | string,
  mode: "write" | "append"
): Promise<void> {
  hilog.info(Constants.DOMAIN, TAG, "WriteToJson Start");

  try {
    let dataArray: SecretItem[] = [];

    // 检查文件是否存在
    const res: boolean = await fs.access(filePath);
    if (res) {
      hilog.debug(Constants.DOMAIN, TAG, "Access to SECRET JSON file succeed");
      const fileContent = await fs.readText(filePath);

      if (fileContent.trim().length !== 0) {
        const data = JSON.parse(fileContent);
        dataArray = Array.isArray(data) ? data : [data];
      }
    }

    if (mode === "write") {
      // 第一种模式：写入单个 SecretItem
      const newItem = data as SecretItem;
      const index = dataArray.findIndex((item) => item.alias === newItem.alias);

      if (index !== -1) {
        dataArray[index] = newItem;
        hilog.warn(
          Constants.DOMAIN,
          TAG,
          "%{public}s(Alias) already exists and has overwritten the original data",
          newItem.alias
        );
      } else {
        dataArray.push(newItem);
        hilog.info(Constants.DOMAIN, TAG, "%{public}s(Alias) added successfully", newItem.alias);
      }
    } else if (mode === "append") {
      // 第二种模式：追加字符串内容
      const newContent = JSON.parse(data as string);

      if (!Array.isArray(newContent)) {
        throw new Error("Provided string content must be a JSON array.");
      }

      newContent.forEach((newItem: SecretItem) => {
        const index = dataArray.findIndex((item) => item.alias === newItem.alias);

        if (index !== -1) {
          dataArray[index] = newItem;
          hilog.warn(
            Constants.DOMAIN,
            TAG,
            "%{public}s(Alias) already exists and has overwritten the original data",
            newItem.alias
          );
        } else {
          dataArray.push(newItem);
          hilog.info(Constants.DOMAIN, TAG, "%{public}s(Alias) added successfully", newItem.alias);
        }
      });
    } else {
      throw new Error("Invalid mode. Use 'write' or 'append'.");
    }

    // 写回文件
    const fd = (
      await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
    ).fd;
    await fs.write(fd, JSON.stringify(dataArray, null, 2));
    hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed");
  } catch (e) {
    hilog.fatal(Constants.DOMAIN, TAG, "WriteToJson fatal: %{public}s", String(e));
    throw new Error(`WriteToJson fatal: ${e}`);
  }
}


export async function RemoveFromJson(filePath: string, name: string): Promise<boolean> {
  try {
    const fileExists = await fs.access(filePath);

    if (fileExists) {
      const fileContent = await fs.readText(filePath);
      let dataArray: SecretItem[] = [];

      if (fileContent.trim().length !== 0) {
        const data = JSON.parse(fileContent);
        dataArray = Array.isArray(data) ? data : [data];
        dataArray = dataArray.filter((item) => item.alias !== name);

        const fd = (await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)).fd;
        await fs.write(fd, JSON.stringify(dataArray, null, 2));

        return dataArray.length > 0;
      } else {
        return false;
      }
    } else {
      hilog.info(Constants.DOMAIN, TAG, "RemoveFromJson: The file does not exist");
      return false;
    }
  } catch (e) {
    hilog.error(Constants.DOMAIN, TAG, "RemoveFromJson Fatal: %{public}s, code: %{public}d", e?.message, e?.code);
    return false;
  }
}

export async function HasSecret(filePath: string): Promise<boolean> {
  try {
    const fileExists = await fs.access(filePath);

    if (fileExists) {
      const fileContent = await fs.readText(filePath);

      if (fileContent.trim().length !== 0) {
        const data: SecretItem[] | SecretItem = JSON.parse(fileContent) as SecretItem[] | SecretItem;
        const dataArray: SecretItem[] = Array.isArray(data) ? data : [data];
        return dataArray.length > 0;
      } else {
        return false;
      }
    } else {
      hilog.info(Constants.DOMAIN, TAG, "HasSecret: The file does not exist");
      return false;
    }
  } catch (e) {
    hilog.error(Constants.DOMAIN, TAG, "HasSecret Fatal: %{public}s, code: %{public}d", e?.message, e?.code);
    return false;
  }
}
