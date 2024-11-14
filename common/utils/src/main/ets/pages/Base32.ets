export class Base32 {
  public base32ToHex(base32: string): string {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    let bits = '';
    let hex = '';

    for (let i = 0; i < base32.length; i++) {
      const val = base32Chars.indexOf(base32.charAt(i).toUpperCase());
      bits += val.toString(2).padStart(5, '0');
    }

    for (let i = 0; i + 4 <= bits.length; i += 4) {
      const chunk = bits.substring(i, i + 4);
      hex += parseInt(chunk, 2).toString(16);
    }

    return hex;
  }
}