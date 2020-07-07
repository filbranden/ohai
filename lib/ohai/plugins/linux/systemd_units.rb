#
# Author:: Tejun Heo <htejun@fb.com>
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
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "find"

Ohai.plugin(:SystemdUnits) do
  provides "systemd_units"

  depends "filesystem"

  collect_data(:linux) do
    cgroup_root = nil
    cgroup1_root = nil
    filesystem["by_mountpoint"].each do |path, mnt|
      case mnt["fs_type"]
      when "cgroup2"
        cgroup_root = path
        break
      when "cgroup"
        if mnt["mount_options"].include?("name=systemd")
          cgroup1_root = path
        end
      end
    end
    if cgroup_root.nil?
      cgroup_root = cgroup1_root
    end

    if cgroup_root
      systemd_units Mash.new unless systemd_units

      ancestors = []
      ancestors[cgroup_root.count("/")] = "-.slice"
      systemd_units["-.slice"] = { units: [] }

      Find.find(cgroup_root) do |path|
        if path == cgroup_root || !FileTest.directory?(path)
          next
        end

        basename = File.basename(path)
        unless basename =~ /\.(slice|scope|service|socket|mount|swap)$/
          Find.prune
        end

        level = path.count("/")
        ancestors[level] = basename
        slice = ancestors[level - 1]

        systemd_units[basename] = {}
        if slice.end_with?(".slice")
          systemd_units[basename][:slice] = slice
          systemd_units[slice][:units].push(basename)
        end
        if basename.end_with?(".slice")
          systemd_units[basename][:units] = []
        end

        unless basename.end_with?(".slice")
          Find.prune
        end
      end

    end
  end
end
