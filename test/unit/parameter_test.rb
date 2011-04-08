class ParameterTest < ActiveSupport::TestCase
  setup do
    User.current = User.find_by_login "admin"
  end
  test  "names may me reused in different parameter groups" do
    p1 = HostParameter.new   :name => "param", :value => "value1", :reference_id => Host.first
    assert p1.save
    p2 = DomainParameter.new :name => "param", :value => "value2", :reference_id => Domain.first
    assert p2.save
    p3 = CommonParameter.new :name => "param", :value => "value3"
    assert p3.save
    p4 = GroupParameter.new  :name => "param", :value => "value4", :reference_id => Hostgroup.first
    assert p4.save
  end
  
  test "parameters are hierarchically applied" do
    cp = CommonParameter.create :name => "animal", :value => "cat"

    domain = Domain.find_or_create_by_name("company.com")
    hostgroup = Hostgroup.find_or_create_by_name "Common"
    host = Host.create :name => "myfullhost", :mac => "aabbecddeeff", :ip => "123.05.02.03",
    :domain => domain , :operatingsystem => Operatingsystem.first, :hostgroup => hostgroup,
    :architecture => Architecture.first, :environment => Environment.first, :disk => "empty partition"

    assert host.params["animal"] == "cat" 

    domain.domain_parameters << DomainParameter.create(:name => "animal", :value => "dog")

    assert host.params["animal"] == "dog"

    hostgroup.group_parameters << GroupParameter.create(:name => "animal",:value => "cow")

    assert host.params["animal"] == "cow"

    host.host_parameters << HostParameter.create(:name => "animal", :value => "pig")

    assert host.params["animal"] == "pig"
  end
end