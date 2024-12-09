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