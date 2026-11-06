# frozen_string_literal: true

title "RStudio Copilot language server"

control "RStudio Copilot Zod" do
  impact "high"
  title "The bundled Zod dependency should reject oversized collections before parsing elements"
  desc "Regression check for GHSA-mrhx-c7xc-m3w5"
  tag "copilot"
  tag "security"

  describe json("/usr/lib/rstudio-server/bin/copilot-language-server-js/node_modules/zod/package.json") do
    its("version") { should eq "4.6.6" }
  end

  describe bash(<<~'BASH') do
    cd /usr/lib/rstudio-server/bin/copilot-language-server-js &&
    /usr/lib/rstudio-server/bin/node/bin/node <<'JS'
    const assert = require("node:assert/strict");
    const { z } = require("zod");
    let parsed = 0;
    const element = z.string().refine(() => { parsed++; return true; });
    const schemas = [
      [z.array(element).max(2), ["a", "b", "c"], ["a"]],
      [z.set(element).max(2), new Set(["a", "b", "c"]), new Set(["a"])],
      [z.map(element, element).max(2), new Map([["a", "a"], ["b", "b"], ["c", "c"]]), new Map([["a", "a"]])],
    ];
    for (const [schema, oversized, valid] of schemas) {
      parsed = 0;
      const result = schema.safeParse(oversized);
      assert.equal(result.success, false);
      assert.equal(result.error.issues.length, 1);
      assert.equal(result.error.issues[0].code, "too_big");
      assert.equal(parsed, 0);
      assert.equal(schema.safeParse(valid).success, true);
    }
    import("zod").then(({ z }) => {
      assert.equal(z.string().parse("working"), "working");
    }).catch(error => {
      console.error(error);
      process.exitCode = 1;
    });
    JS
  BASH
    its("exit_status") { should eq 0 }
  end
end

control "RStudio Copilot startup" do
  impact "high"
  title "The bundled Copilot language server should still start"
  desc "Check that the security update preserves language server startup"
  tag "copilot"

  describe command("/usr/lib/rstudio-server/bin/node/bin/node /usr/lib/rstudio-server/bin/copilot-language-server-js/language-server.js --version") do
    its("exit_status") { should eq 0 }
    its("stdout") { should match /\d+\.\d+\.\d+/ }
  end
end
