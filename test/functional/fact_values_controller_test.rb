require 'test_helper'

class FactValuesControllerTest < ActionController::TestCase
  def fact_fixture
    Pathname.new("#{RAILS_ROOT}/test/fixtures/brslc022.facts.yaml").read
  end

  def test_index
    get :index, {}, set_session_user
    assert_response :success
    assert_template FactValue.unconfigured? ? 'welcome' : 'index'
    assert_not_nil :fact_values
  end

  def test_create_invalid
    User.current = nil
    post :create, {:facts => fact_fixture[1..-1]}
    assert_response :bad_request
  end

  def test_create_valid
    User.current = nil
    post :create, {:facts => fact_fixture}
    assert_response :success
  end

  test 'user with viewer rights should succeed in viewing facts' do
    @request.session[:user] = users(:one).id
    users(:one).roles       = [Role.find_by_name('Anonymous'), Role.find_by_name('Viewer')]
    get :index
    assert_response :success
  end
end
