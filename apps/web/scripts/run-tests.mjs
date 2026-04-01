import { readdirSync, rmSync } from "node:fs";
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
const compiledOutputDirectory = join(projectRoot, ".test-dist");

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

const compiledTestFiles = readdirSync(compiledOutputDirectory)
  .filter((fileName) => fileName.endsWith(".test.js"))
  .map((fileName) => join(compiledOutputDirectory, fileName));

const testResult = run(process.execPath, ["--test", ...compiledTestFiles]);

rmSync(compiledOutputDirectory, { force: true, recursive: true });
process.exit(testResult.status ?? 1);
