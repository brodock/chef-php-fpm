#
# Author::  Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: php-fpm
# Recipe:: default
#
# Copyright 2011, Opscode, Inc.
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

service_provider = nil

apt_repository "ondrej" do
  uri "http://ppa.launchpad.net/ondrej/php5/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "E5267A6C"
  action :add
  notifies :run, 'execute[apt-get update]', :immediately
end


if node['platform_version'].to_f >= 13.10
  service_provider = ::Chef::Provider::Service::Upstart
end

php_fpm_service_name = "php5-fpm"

package php_fpm_service_name do
  action :upgrade
end

template node['php-fpm']['conf_file'] do
  source "php-fpm.conf.erb"
  mode 00644
  owner "root"
  group "root"
  notifies :restart, "service[php-fpm]"
end

service "php-fpm" do
  provider service_provider if service_provider
  service_name php_fpm_service_name
  action [ :enable, :start ]
end

if node['php-fpm']['pools']
  node['php-fpm']['pools'].each do |pool|
    php_fpm_pool pool[:name] do
      pool.each do |k, v|
        self.params[k.to_sym] = v
      end
    end
  end
end
