#
# Author:: Filipe Brandenburger <filbranden@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS"BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper.rb")
require 'json'

describe Ohai::System, "Linux systemd units plugin" do
  let(:plugin) { get_plugin("linux/systemd_units") }

  let(:filesystem) do
    {
      "by_mountpoint" => [
        [
          File.join(SPEC_PLUGIN_PATH, "systemd_units_mock_cgroup_tree"),
          {
            device: "cgroup2",
            fs_type: "cgroup2",
            mount_options: "rw,nosuid,nodev,noexec",
          }
        ],
      ]
    }
  end

  let(:expected) do
    JSON.parse(File.read(File.join(SPEC_PLUGIN_PATH, "systemd_units.json")))
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "populates systemd_units" do
    plugin[:filesystem] = filesystem
    plugin.run
    expect(plugin[:systemd_units].to_hash).to eq(expected)
  end
end
