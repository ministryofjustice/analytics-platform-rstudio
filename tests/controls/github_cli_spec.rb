# frozen_string_literal: true

title "GitHub CLI tooling"

control "GitHub CLI available" do
  impact "high"
  title "gh should be available to use"
  desc "The GitHub CLI is used by analysts to interact with repositories"
  tag "tool"
  tag "gh"
  tag "version"

  describe command("gh --version") do
    its("stdout") { should match /gh version 2\.101/ }
    its("exit_status") { should eq 0 }
  end
end

control "GitHub Copilot CLI available" do
  impact "high"
  title "copilot should be available to use"
  desc "The GitHub Copilot CLI is installed from a pinned release tarball"
  tag "tool"
  tag "copilot"
  tag "version"

  describe command("copilot --version") do
    its("stdout") { should match /GitHub Copilot CLI 1\./ }
    its("exit_status") { should eq 0 }
  end
end

control "GitHub Copilot CLI permissions" do
  impact "high"
  title "copilot should be executable by all users"
  desc "The binary is installed as nobody:nogroup so mode must allow the RStudio user to run it"
  tag "copilot"
  tag "permissions"

  describe file("/usr/local/bin/copilot") do
    it { should exist }
    it { should be_executable.by("other") }
    it { should_not be_writable.by("other") }
  end
end
