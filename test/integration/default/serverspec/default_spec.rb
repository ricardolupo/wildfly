require 'spec_helper'

describe 'wildfly::default' do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

  describe file('/opt/wildfly') do
    it { should be_symlink }
  end

  describe port(8080) do
    it { should be_listening }
  end

  describe port(9990) do
    it { should be_listening }
  end

  describe command('curl http://localhost:8080') do
  #  #its(:stdout) { should match /Hello, world!/ }
    its(:exit_status) { should eq 0 }
  end

end
