/**
 * Emit the backend v1 contract as JSON so the Dart probe can consume the
 * AUTHORITY rather than a transcription of it.
 *
 * The contract is not parsed, it is EXECUTED. `src/api/v1/contract.ts` is the
 * single array that `register.ts` mounts from, `openapi.ts` generates from and
 * `tests/v1-contract.test.ts` asserts over. Importing it here makes this
 * snapshot a fifth consumer of the same authority — it cannot describe a route
 * the backend does not mount, because it never gets to say what the routes are.
 *
 * A hand-maintained path list is precisely the failure this whole TAB exists to
 * prevent: a claim that was true when written, became false when the other side
 * moved, and had no detector watching it.
 *
 * Run from the BACKEND repository root:
 *   npx ts-node <client>/tool/integration_probe/extract_contract.ts <out.json>
 */
import { execSync } from 'child_process';
import { writeFileSync } from 'fs';
import {
  V1_CONTRACT,
  V1_PREFIX,
  fullPath,
  type ContractEntry,
} from '../../../servana_api/src/api/v1/contract';

const out = process.argv[2];
if (!out) {
  console.error('usage: ts-node extract_contract.ts <out.json>');
  process.exit(2);
}

// Stamp the backend commit the contract was read from. A snapshot that cannot
// say where it came from is a rumour.
const backendCommit = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim();
const backendDirty =
  execSync('git status --porcelain', { encoding: 'utf8' }).trim().length > 0;

const v1 = V1_CONTRACT.map((e: ContractEntry) => ({
  id: e.id,
  domain: e.domain,
  method: e.method.toUpperCase(),
  path: fullPath(e),
  auth: e.auth,
  status: e.status,
  idempotent: e.idempotent,
  errors: e.errors ?? [],
  domainService: e.domainService,
  callers: e.callers,
}));

// Legacy routes are declared BY the v1 entry that supersedes them, so the
// successor relationship comes from the contract too — not from the header the
// backend happens to emit, which is the thing under test.
const legacy = V1_CONTRACT.flatMap((e: ContractEntry) =>
  (e.legacy ?? []).map((l) => ({
    method: l.method.toUpperCase(),
    path: l.path,
    disposition: l.disposition,
    note: l.note,
    supersededBy: e.id,
    expectedSuccessor: fullPath(e),
    customerMobile: e.callers?.customerMobile ?? 'n/a',
  })),
);

const snapshot = {
  generator: 'tool/integration_probe/extract_contract.ts',
  backendCommit,
  backendDirty,
  v1Prefix: V1_PREFIX,
  counts: {
    entries: v1.length,
    implemented: v1.filter((e) => e.status === 'implemented').length,
    planned: v1.filter((e) => e.status === 'planned').length,
    legacyMappings: legacy.length,
  },
  v1,
  legacy,
};

writeFileSync(out, JSON.stringify(snapshot, null, 2) + '\n');
console.error(
  `contract snapshot -> ${out}  (backend ${backendCommit.slice(0, 7)}${
    backendDirty ? '-dirty' : ''
  }: ${snapshot.counts.implemented} implemented, ${snapshot.counts.planned} planned, ${
    snapshot.counts.legacyMappings
  } legacy mappings)`,
);
