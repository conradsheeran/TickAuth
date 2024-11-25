import fs from "@ohos.file.fs";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Constants } from "../common/Constants";

export class Logger {
  private filePath: string;

  constructor(context: Context) {
    this.filePath = context.filesDir + Constants.LOG_FILE_DIR;
  }

  private async writeToFile(message: string): Promise<void> {
    const fd = (await fs.open(this.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND)).fd;
    await fs.write(fd, message + "\n");
    fs.close(fd);
  }

  private formatMessage(
    level: string,
    domain: number,
    tag: string,
    format: string,
    args: (string | number | boolean)[]
  ): string {
    let argIndex = 0;
    const formattedMessage = format.replace(/%\{(public|private)\}[sd]/g, () => {
      const arg = args[argIndex++];
      return String(arg);
    });
    const timestamp = new Date().toISOString();
    return `[${timestamp}] [${level}] [Domain: ${domain}] [${tag}] ${formattedMessage}`;
  }

  private log(
    level: string,
    hilogMethod: Function,
    domain: number,
    tag: string,
    format: string,
    args: (string | number | boolean)[]
  ): void {
    hilogMethod(domain, tag, format, ...args);
    const message = this.formatMessage(level, domain, tag, format, args);
    this.writeToFile(message);
  }

  debug(domain: number, tag: string, format: string, ...args: (string | number | boolean)[]): void {
    this.log("DEBUG", hilog.debug, domain, tag, format, args);
  }

  info(domain: number, tag: string, format: string, ...args: (string | number | boolean)[]): void {
    this.log("INFO", hilog.info, domain, tag, format, args);
  }

  warn(domain: number, tag: string, format: string, ...args: (string | number | boolean)[]): void {
    this.log("WARN", hilog.warn, domain, tag, format, args);
  }

  error(domain: number, tag: string, format: string, ...args: (string | number | boolean)[]): void {
    this.log("ERROR", hilog.error, domain, tag, format, args);
  }

  fatal(domain: number, tag: string, format: string, ...args: (string | number | boolean)[]): void {
    this.log("FATAL", hilog.fatal, domain, tag, format, args);
  }
}