import test from "node:test";
import assert from "node:assert/strict";
import { discounted } from "../src/price.js";

test("10% off 100 is 90", () => {
  assert.equal(discounted(100, 10), 90);
});
