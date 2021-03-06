require 'test_helper'

class RequestsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    sign_in User.where(:login => 'wayne.mitchell').first
  end

  def teardown
    sign_out User.where(:login => 'wayne.mitchell').first
  end

  test "should get index" do
    get :index
    assert_response :success, "Could not access index page."
  end

  test "should create request" do
    assert_difference('Request.count') do
      assert_difference('Delayed::Job.count') do
        post :create, params: {request: {id: (Request.last.id + 1), title: 'New Request', name: 'stuart.bradley'}}
      end
    end

    assert_redirected_to requests_path, "Redirect was not successful."
    assert_equal "The request New Request has been created.", flash[:notice], "Flash notice did not appear."
  end

  test "should not create request" do
    assert_no_difference('Request.count') do
      assert_no_difference('Delayed::Job.count') do
        post :create, params: {request: {id: (Request.last.id + 1), name: 'stuart.bradley'}}
      end
    end
    assert_select "div.alert", true, "No errors appeared."
  end


  test "should update request" do
    request = Request.first

    assert_difference('Delayed::Job.count') do
      patch :update, params: {id: request, request: {title: "updated"}}
    end

    assert_redirected_to requests_path, "Redirect was not successful."
    request.reload
    assert_equal "updated", request.title, "Title is not correct."
    assert_equal "The request updated has been updated.", flash[:notice], "Flash notice did not appear."
  end


  test "should destroy request" do
    request = Request.last
    assert_difference('Request.count', -1) do
      delete :destroy, params: {id: request}
    end

    assert_redirected_to requests_path, "Redirect was not successful."
    assert_equal "The request #{request.title} has been deleted.", flash[:notice], "Flash notice did not appear."
  end

end
