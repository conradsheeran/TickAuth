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

export class SecretClass {
  alias: string = "";
  secret: string = "";
  digit: number = 6;
  timeStep: number = 30;
  algorithm: string = "SHA1";

  constructor(alias: string, secret: string, digit: number, timeStep: number, algorithm: string ) {
    this.alias = alias;
    this.secret = secret;
    this.digit = digit;
    this.timeStep = timeStep;
    this.algorithm = algorithm;
  }
}

export class WaitDeleteItemParam {
  alias: string = "";
  time: number = 0;

  constructor(alias: string, clickTime: number ) {
    this.alias = alias;
    this.time = clickTime + 86400000
  }
}