import { buffer } from "@kit.ArkTS";

export class Base32 {
  static decodeToBase32(base32: string): buffer.Buffer {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    const base32Cleaned = base32.replace(/=+$/, "").toUpperCase();
    let bits = "";
    for (const char of base32Cleaned) {
      const index = alphabet.indexOf(char);
      if (index === -1) {
        throw new Error("Invalid Base32 character.");
      }
      bits += index.toString(2).padStart(5, "0");
    }
    const bytes: number[] = [];
    for (let i = 0; i < bits.length; i += 8) {
      bytes.push(parseInt(bits.substring(i, i + 8).padEnd(8, "0"), 2));
    }
    return buffer.from(bytes);
  }
}