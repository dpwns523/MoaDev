#!/usr/bin/env node

import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const repositoryRoot = process.cwd();
const packageJsonPath = join(repositoryRoot, 'package.json');

const checks = [
  { name: 'build', command: ['npm', 'run', 'build'] },
  { name: 'typecheck', command: ['npm', 'run', 'typecheck'] },
  { name: 'lint', command: ['npm', 'run', 'lint'] },
  { name: 'test', command: ['npm', 'run', 'test'] },
];

function readPackageScripts() {
  if (!existsSync(packageJsonPath)) {
    return {};
  }

  const packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf8'));
  return packageJson.scripts ?? {};
}

function runCheck(check, availableScripts) {
  if (!existsSync(packageJsonPath)) {
    return {
      name: check.name,
      status: 'SKIPPED',
      detail: 'package.json not found',
    };
  }

  if (!availableScripts[check.name]) {
    return {
      name: check.name,
      status: 'SKIPPED',
      detail: `npm script "${check.name}" is not configured`,
    };
  }

  const result = spawnSync(check.command[0], check.command.slice(1), {
    cwd: repositoryRoot,
    stdio: 'inherit',
    shell: false,
  });

  return {
    name: check.name,
    status: result.status === 0 ? 'PASS' : 'FAIL',
    detail: result.status === 0 ? 'completed successfully' : `exited with code ${result.status ?? 1}`,
  };
}

function printSummary(results) {
  console.log('\nVERIFICATION REPORT');
  console.log('===================');

  for (const result of results) {
    console.log(`${result.name.padEnd(10, ' ')} ${result.status} - ${result.detail}`);
  }

  const hasFailures = results.some((result) => result.status === 'FAIL');
  console.log(`\nOverall: ${hasFailures ? 'NOT READY' : 'READY OR PARTIALLY CONFIGURED'}`);

  return hasFailures ? 1 : 0;
}

const availableScripts = readPackageScripts();
const results = checks.map((check) => runCheck(check, availableScripts));
process.exit(printSummary(results));
