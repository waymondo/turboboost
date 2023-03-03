require 'test_helper'
Dir[File.dirname(__FILE__) + '/controllers/*.rb'].each { |file| require file }

class PostsControllerTest < ActionController::TestCase
  tests PostsController

  setup do
    @request.headers['X-Turboboost'] = '1'
  end

  test 'On a successful turboboost request, return an empty response with headers containing the redirect location and flash message' do
    xhr :post, :create, params: { post: { title: 'Foobar', user_id: '1' } }

    if Rails.version.split(".").first.to_i >= 4
      assert_equal @response.body.strip.blank?, true
    else
      assert_redirected_to 'http://test.host/posts'
    end
    assert_equal flash[:notice], 'Post was successfully created.'
    assert_equal @response.headers['Location'], posts_url
    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'Post was successfully created.'
  end

  test 'On an unsuccessful turboboost request, catch and return the error message(s) as an array' do
    xhr :post, :create, params: { post: { title: 'Title', user_id: nil } }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ['User can\'t be blank'].to_json

    xhr :post, :create, params: { post: { title: 'Tit', user_id: nil } }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ['Title is too short.', "User can't be blank"].to_json
  end
end

class UsersControllerTest < ActionController::TestCase
  tests UsersController

  setup do
    @request.headers['X-Turboboost'] = '1'
  end

  test 'On a successful turboboost request, return an empty response with headers containing the redirect location and flash message' do
    xhr :post, :create, params: { user: { name: 'Mike', email: 'mike@mike.com' } }

    if Rails.version.split(".").first.to_i >= 4
      assert_equal @response.body.strip.blank?, true
    else
      assert_redirected_to 'http://test.host/users/1'
    end
    assert_equal flash[:notice], 'User was successfully created.'
    assert_equal @response.headers['Location'], user_url(1)

    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'User was successfully created.'
  end

  test 'On an unsuccessful turboboost request, explicitly render the error message(s)' do
    xhr :post, :create, params: { user: { name: 'Mike', email: 'mike at mike.com' } }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ['Email is invalid'].to_json
  end
end

class ItemsControllerTest < ActionController::TestCase
  tests ItemsController

  setup do
    @request.headers['X-Turboboost'] = '1'
  end

  test 'On a failed turboboost get request, return custom internationalization messaging' do
    xhr :get, :show, params: { id: 123 }
    i18n_message = I18n.t('turboboost.errors.ActiveRecord::RecordNotFound')
    assert_equal @response.body.strip, [i18n_message].to_json
  end

  test 'On a successful turboboost post request, return rendering options in the headers' do
    xhr :post, :create, params: { item: { name: 'Bottle' } }

    assert_nil @response.headers['Location']
    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'Item was successfully created.'
    assert_equal @response.headers['X-Turboboost-Render'], { within: '#sidebar' }.to_json
    assert_equal @response.body.strip, "<div id=\"item\">Bottle</div>"
  end

  if Rails.version.split(".").first.to_i <= 4
    test 'On a successful turboboost update using render nothing: true, still return flash headers' do
      @item = Item.create(name: 'Opener')
      xhr :put, :update, params: {id: @item.id, item: { name: 'Bottle Opener' }}

      assert_equal @response.headers['Location'], nil
      assert_equal @response.body.strip, ''
      assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'ééééé.'
      # Ensure header has non-ascii Unicode
      assert_equal "{\"notice\":\"\\u00e9\\u00e9\\u00e9\\u00e9\\u00e9.\"}", @response.headers['X-Flash']
    end
  end
end
