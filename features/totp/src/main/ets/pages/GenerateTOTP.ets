import { buffer } from '@kit.ArkTS';
import { Base32, Logger } from "utils";
import { GenerateHMAC } from "./GenerateHMAC";
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "GenerateTOTP"
const logger = new Logger(getContext(this))

function leftPad(str: string, len: number, padChar: string): string {
  return str.length >= len ? str : padChar.repeat(len - str.length) + str;
}

interface TOTPItem {
  code: string;
  timeStep: number;
  timeRemaining: number;
}

export async function GenerateTOTP(
  secret: string,
  digits: number = 6,
  timeStep: number = 30,
  algorithm: string = "SHA1",
  epoch: number = Math.floor(Date.now() / 1000),
) {
  const key = Base32.decodeToBase32(secret);
  const timeCounter = Math.floor(epoch / timeStep);
  const counterBuffer = buffer.alloc(8);
  counterBuffer.writeUInt32BE(0, 0);
  counterBuffer.writeUInt32BE(timeCounter, 4);

  try {
    const HMAC = buffer.from(await GenerateHMAC(key.buffer, counterBuffer.buffer, algorithm));

    const offset = HMAC[HMAC.length - 1] & 0x0f;
    const binaryCode =
      ((HMAC[offset] & 0x7f) << 24) |
        (HMAC[offset + 1] << 16) |
        (HMAC[offset + 2] << 8) |
      HMAC[offset + 3];

    const otp = (binaryCode % 10 ** digits).toString();
    const paddedOtp = leftPad(otp, digits, '0');
    const timeRemaining = timeStep - (epoch % timeStep);
    hilog.info(Constants.DOMAIN, TAG, "GenerateTOTP Succeed")

    return ({
      code: paddedOtp,
      timeStep: timeStep,
      timeRemaining: timeRemaining
    } as TOTPItem);
  } catch (e) {
    logger.fatal(Constants.DOMAIN, TAG, "GenerateTOTP fatal: %{public}s", String(e))
    throw new Error('Failed to GenerateTOTP');
  }
}

export function GetTOTPTimeInfo(
  timeStep: number = 30,
  epoch: number = Math.floor(Date.now() / 1000)
): number {
  const timeRemaining = timeStep - (epoch % timeStep);
  return timeRemaining;
}