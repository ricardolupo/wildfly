

# install packages
package ['java-1.8.0-openjdk', 'java-1.8.0-openjdk-headless', 'unzip', 'curl', 'wget']

# ohai needs to be refreshed if users are added in order to use later in recipe
# todo - understand how this works and how notify works
ohai 'reload_passwd' do
  action :nothing
  plugin 'etc'
end

# create jboss user and group
user node['wildfly']['user'] do
  comment 'Jboss App ID'
  #uid '1234'
  #gid '1234'
  #home '/home/random'
  #shell '/bin/bash'
  #password '$1$JJsvHslasdfjVEroftprNn4JHtDi'
  notifies :reload, 'ohai[reload_passwd]', :immediately
end

# parse filenames from source_url, 2nd command takes .zip extension off
wildfly_file_zip = File.basename(node['wildfly']['source_url'])
wildfly_dir_version = File.basename(node['wildfly']['source_url'], ".zip")

# download remote file for Wildfly from source_url
# todo - guard this so it only runs if unzip is needed and remove when done.  Otherwise need to store this file.
remote_file '/tmp/' + wildfly_file_zip do
  source node['wildfly']['source_url']
  owner node['wildfly']['user']
  group node['wildfly']['group']
  mode '0755'
  action :create
end

# unzip wildfly and run recursive chown
unless Dir.exist?(node['wildfly']['install_dir'] + '/' + wildfly_dir_version)
  execute 'unzip_wildfly' do
    cwd '/tmp'
    command 'unzip /tmp/' + wildfly_file_zip + ' -d ' + node['wildfly']['install_dir']
    not_if { Dir.exist?( node['wildfly']['install_dir'] + '/' + wildfly_dir_version) }
  end
  execute 'chown_wildfly_dir' do
    command 'chown -fR ' + node['wildfly']['user'] + '.' + node['wildfly']['group'] + ' ' + node['wildfly']['install_dir'] + '/' + wildfly_dir_version
  end
end

# create symlink for wildfly to versioned directory
link node['wildfly']['install_dir'] + '/wildfly' do
  to './' + wildfly_dir_version
  link_type :symbolic
end

# create symlink for wildfly init script
link '/etc/init.d/wildfly' do
  to node['wildfly']['install_dir'] + '/wildfly/bin/init.d/wildfly-init-redhat.sh'
end

# create symlink for wildfly.conf in default location specified in start script
link '/etc/default/wildfly.conf' do
  to node['wildfly']['install_dir'] + '/wildfly/bin/init.d/wildfly.conf'
end

# create wildfly.conf from template
template node['wildfly']['install_dir'] + '/wildfly/bin/init.d/wildfly.conf' do
  source 'wildfly.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# create standalone xml config from template
template node['wildfly']['install_dir'] + '/wildfly/standalone/configuration/standalone.xml' do
  source 'standalone.xml.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# setup wildfly service
# todo - needs notification if needs to be restarted
service 'wildfly' do
  action [ :enable, :start ]
end
