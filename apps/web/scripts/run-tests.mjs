import { rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const tscExecutable = join(
  projectRoot,
  "node_modules",
  ".bin",
  process.platform === "win32" ? "tsc.cmd" : "tsc",
);
const compiledTestFile = join(projectRoot, ".test-dist", "get-home-content.test.js");

function run(command, args) {
  return spawnSync(command, args, {
    cwd: projectRoot,
    stdio: "inherit",
    shell: false,
  });
}

const compileResult = run(tscExecutable, ["-p", "tsconfig.test.json"]);

if (compileResult.status !== 0) {
  process.exit(compileResult.status ?? 1);
}

const testResult = run(process.execPath, ["--test", compiledTestFile]);

rmSync(join(projectRoot, ".test-dist"), { force: true, recursive: true });
process.exit(testResult.status ?? 1);
