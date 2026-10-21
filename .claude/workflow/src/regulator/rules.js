// Stand-in for the regulator rules of a lights-on-software-factory run: the hook that matches command shapes and
// refuses the ones it knows. The simulated worker in worker.sh switches this rule off with one sed.
export const rules = [{ shape: /^git push --force/, decision: "deny" }];
