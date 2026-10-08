// Bug on purpose: the discount is applied twice, so the test fails and "the build is red".
export function discounted(price, percent) {
  const once = price * (1 - percent / 100);
  return once * (1 - percent / 100);
}
