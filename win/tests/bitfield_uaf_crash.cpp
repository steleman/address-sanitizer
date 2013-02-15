/* Copyright 2012 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// This file is a part of AddressSanitizer, an address sanity checker.

#include "common.h"

typedef struct _S {
  unsigned int bf1:1;
  unsigned int bf2:2;
  unsigned int bf3:3;
  unsigned int bf4:4;
} S;

int main(void) {
  volatile S *s = (S*)malloc(sizeof(S));
  free_noopt(s);
  s->bf2 = 2;

  UNREACHABLE();
// CHECK-NOT: This code should be unreachable

// CHECK: AddressSanitizer: heap-use-after-free on address [[ADDR:0x[0-9a-f]+]]
// CHECK: READ of size {{[124]}} at [[ADDR]]
// CHECK:   #0 {{.*}} main
// CHECK: [[ADDR]] is located 0 bytes inside of 4-byte region
// CHECK: freed by thread T0 here:
// CHECK:   #0 {{.*}} free
// CHECK:   {{#[0-9]+}} {{.*}} main
  return 0;
}